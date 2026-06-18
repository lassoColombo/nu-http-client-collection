# Auto-generated client for Appwrite v0.9.3
# Source: https://api.apis.guru/v2/specs/appwrite.io/server/0.9.3/openapi.json
# Auth: --token flag or $env.APPWRITE_TOKEN

const BASE_URL = "https://appwrite.io/v1"
const DEFAULT_AUTH = "x-appwrite-jwt"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o APPWRITE_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-appwrite-jwt" => { {headers: {X-Appwrite-JWT: $token_val}, query: ""} }
    "x-appwrite-key" => { {headers: {X-Appwrite-Key: $token_val}, query: ""} }
    "x-appwrite-locale" => { {headers: {X-Appwrite-Locale: $token_val}, query: ""} }
    "x-appwrite-project" => { {headers: {X-Appwrite-Project: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://appwrite.io/v1"] }
def auth-scheme-completer [] { ["x-appwrite-jwt" "x-appwrite-key" "x-appwrite-locale" "x-appwrite-project"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account delete" } } | get name | first)
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

# Delete Account
#
# DELETE /account
# operationId: accountDelete
export def "account delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Account
#
# GET /account
# operationId: accountGet
export def "account get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_id: string, email: string, emailVerification: bool, name: string, passwordUpdate: int, prefs: record, registration: int, status: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Account Email
#
# PATCH /account/email
# operationId: accountUpdateEmail
export def "account-email update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # User email.
  password: string # User password. Must be between 6 to 32 chars.
]: any -> record<_id: string, email: string, emailVerification: bool, name: string, passwordUpdate: int, prefs: record, registration: int, status: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/email")
  let req_body = {"email": $email, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get Account Logs
#
# GET /account/logs
# operationId: accountGetLogs
export def "account-logs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<logs: table<clientCode: string, clientEngine: string, clientEngineVersion: string, clientName: string, clientType: string, clientVersion: string, countryCode: string, countryName: string, deviceBrand: string, deviceModel: string, deviceName: string, event: string, ip: string, osCode: string, osName: string, osVersion: string, time: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/logs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Account Name
#
# PATCH /account/name
# operationId: accountUpdateName
export def "account-name update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # User name. Max length: 128 chars.
]: any -> record<_id: string, email: string, emailVerification: bool, name: string, passwordUpdate: int, prefs: record, registration: int, status: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/name")
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update Account Password
#
# PATCH /account/password
# operationId: accountUpdatePassword
export def "account-password update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --old-password: string # Old user password. Must be between 6 to 32 chars.
  password: string # New user password. Must be between 6 to 32 chars.
]: any -> record<_id: string, email: string, emailVerification: bool, name: string, passwordUpdate: int, prefs: record, registration: int, status: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/password")
  let req_body = {"oldPassword": $old_password, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get Account Preferences
#
# GET /account/prefs
# operationId: accountGetPrefs
export def "account-prefs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/prefs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Account Preferences
#
# PATCH /account/prefs
# operationId: accountUpdatePrefs
export def "account-prefs update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  prefs: record # Prefs key-value JSON object.
]: any -> record<_id: string, email: string, emailVerification: bool, name: string, passwordUpdate: int, prefs: record, registration: int, status: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/prefs")
  let req_body = {"prefs": $prefs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Create Password Recovery
#
# POST /account/recovery
# operationId: accountCreateRecovery
export def "account-recovery create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # User email.
  url: string # URL to redirect the user back to your app from the recovery email. Only URLs from hostnames in your project platform list are allowed. This requirement helps to prevent an [open redirect](https://cheatsheetseries.owasp.org/cheatsheets/Unvalidated_Redirects_and_Forwards_Cheat_Sheet.html) attack against your project API.
]: any -> record<_id: string, expire: int, secret: string, userId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/recovery")
  let req_body = {"email": $email, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Complete Password Recovery
#
# PUT /account/recovery
# operationId: accountUpdateRecovery
export def "account-recovery update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string # New password. Must be between 6 to 32 chars.
  password_again: string # New password again. Must be between 6 to 32 chars.
  secret: string # Valid reset token.
  user_id: string # User account UID address.
]: any -> record<_id: string, expire: int, secret: string, userId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/recovery")
  let req_body = {"password": $password, "passwordAgain": $password_again, "secret": $secret, "userId": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete All Account Sessions
#
# DELETE /account/sessions
# operationId: accountDeleteSessions
export def "account-sessions delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/sessions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Account Sessions
#
# GET /account/sessions
# operationId: accountGetSessions
export def "account-sessions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<sessions: table<_id: string, clientCode: string, clientEngine: string, clientEngineVersion: string, clientName: string, clientType: string, clientVersion: string, countryCode: string, countryName: string, current: bool, deviceBrand: string, deviceModel: string, deviceName: string, expire: int, ip: string, osCode: string, osName: string, osVersion: string, provider: string, providerToken: string, providerUid: string, userId: string>, sum: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/sessions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Account Session
#
# DELETE /account/sessions/{sessionId}
# operationId: accountDeleteSession
export def "account-sessions delete-by-sessionId" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({session_id: (encode-path-segment $session_id)} | format pattern "/account/sessions/{session_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Session By ID
#
# GET /account/sessions/{sessionId}
# operationId: accountGetSession
export def "account-sessions get" [
  session_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_id: string, clientCode: string, clientEngine: string, clientEngineVersion: string, clientName: string, clientType: string, clientVersion: string, countryCode: string, countryName: string, current: bool, deviceBrand: string, deviceModel: string, deviceName: string, expire: int, ip: string, osCode: string, osName: string, osVersion: string, provider: string, providerToken: string, providerUid: string, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({session_id: (encode-path-segment $session_id)} | format pattern "/account/sessions/{session_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Email Verification
#
# POST /account/verification
# operationId: accountCreateVerification
export def "account-verification create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  url: string # URL to redirect the user back to your app from the verification email. Only URLs from hostnames in your project platform list are allowed. This requirement helps to prevent an [open redirect](https://cheatsheetseries.owasp.org/cheatsheets/Unvalidated_Redirects_and_Forwards_Cheat_Sheet.html) attack against your project API.
]: any -> record<_id: string, expire: int, secret: string, userId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/verification")
  let req_body = {"url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Complete Email Verification
#
# PUT /account/verification
# operationId: accountUpdateVerification
export def "account-verification update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  secret: string # Valid verification token.
  user_id: string # User unique ID.
]: any -> record<_id: string, expire: int, secret: string, userId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/verification")
  let req_body = {"secret": $secret, "userId": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get Browser Icon
#
# GET /avatars/browsers/{code}
# operationId: avatarsGetBrowser
export def "avatars-browsers get" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --width: int # Image width. Pass an integer between 0 to 2000. Defaults to 100. (format: int32, default: 100)
  --height: int # Image height. Pass an integer between 0 to 2000. Defaults to 100. (format: int32, default: 100)
  --quality: int # Image quality. Pass an integer between 0 to 100. Defaults to 100. (format: int32, default: 100)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "width" $width "scalar") (serialize-qp "height" $height "scalar") (serialize-qp "quality" $quality "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({code: (encode-path-segment $code)} | format pattern "/avatars/browsers/{code}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Credit Card Icon
#
# GET /avatars/credit-cards/{code}
# operationId: avatarsGetCreditCard
export def "avatars-credit-cards get" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --width: int # Image width. Pass an integer between 0 to 2000. Defaults to 100. (format: int32, default: 100)
  --height: int # Image height. Pass an integer between 0 to 2000. Defaults to 100. (format: int32, default: 100)
  --quality: int # Image quality. Pass an integer between 0 to 100. Defaults to 100. (format: int32, default: 100)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "width" $width "scalar") (serialize-qp "height" $height "scalar") (serialize-qp "quality" $quality "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({code: (encode-path-segment $code)} | format pattern "/avatars/credit-cards/{code}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Favicon
#
# GET /avatars/favicon
# operationId: avatarsGetFavicon
export def "avatars-favicon get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --url: string # Website URL which you want to fetch the favicon from. (format: url)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/avatars/favicon" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Country Flag
#
# GET /avatars/flags/{code}
# operationId: avatarsGetFlag
export def "avatars-flags get" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --width: int # Image width. Pass an integer between 0 to 2000. Defaults to 100. (format: int32, default: 100)
  --height: int # Image height. Pass an integer between 0 to 2000. Defaults to 100. (format: int32, default: 100)
  --quality: int # Image quality. Pass an integer between 0 to 100. Defaults to 100. (format: int32, default: 100)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "width" $width "scalar") (serialize-qp "height" $height "scalar") (serialize-qp "quality" $quality "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({code: (encode-path-segment $code)} | format pattern "/avatars/flags/{code}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Image from URL
#
# GET /avatars/image
# operationId: avatarsGetImage
export def "avatars-image get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --url: string # Image URL which you want to crop. (format: url)
  --width: int # Resize preview image width, Pass an integer between 0 to 2000. (format: int32, default: 400)
  --height: int # Resize preview image height, Pass an integer between 0 to 2000. (format: int32, default: 400)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $url "scalar") (serialize-qp "width" $width "scalar") (serialize-qp "height" $height "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/avatars/image" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get User Initials
#
# GET /avatars/initials
# operationId: avatarsGetInitials
export def "avatars-initials get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Full Name. When empty, current user name or email will be used. Max length: 128 chars. (default: )
  --width: int # Image width. Pass an integer between 0 to 2000. Defaults to 100. (format: int32, default: 500)
  --height: int # Image height. Pass an integer between 0 to 2000. Defaults to 100. (format: int32, default: 500)
  --color: string # Changes text color. By default a random color will be picked and stay will persistent to the given name. (default: )
  --background: string # Changes background color. By default a random color will be picked and stay will persistent to the given name. (default: )
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "width" $width "scalar") (serialize-qp "height" $height "scalar") (serialize-qp "color" $color "scalar") (serialize-qp "background" $background "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/avatars/initials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get QR Code
#
# GET /avatars/qr
# operationId: avatarsGetQR
export def "avatars-qr get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --text: string # Plain text to be converted to QR code image.
  --size: int # QR code size. Pass an integer between 0 to 1000. Defaults to 400. (format: int32, default: 400)
  --margin: int # Margin from edge. Pass an integer between 0 to 10. Defaults to 1. (format: int32, default: 1)
  --download: oneof<nothing, bool> # Return resulting image with 'Content-Disposition: attachment ' headers for the browser to start downloading it. Pass 0 for no header, or 1 for otherwise. Default value is set to 0. (default: false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "text" $text "scalar") (serialize-qp "size" $size "scalar") (serialize-qp "margin" $margin "scalar") (serialize-qp "download" $download "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/avatars/qr" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Collections
#
# GET /database/collections
# operationId: databaseListCollections
export def "database-collections list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search term to filter your list results. Max length: 256 chars. (default: )
  --limit: int # Results limit value. By default will return maximum 25 results. Maximum of 100 results allowed per request. (format: int32, default: 25)
  --offset: int # Results offset. The default value is 0. Use this param to manage pagination. (format: int32, default: 0)
  --order-type: string # Order result by ASC or DESC order. (default: ASC)
]: nothing -> record<collections: table<_id: string, _permissions: record, dateCreated: int, dateUpdated: int, name: string, rules: list>, sum: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "orderType" $order_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/database/collections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Collection
#
# POST /database/collections
# operationId: databaseCreateCollection
export def "database-collections create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Collection name. Max length: 128 chars.
  read: list<string> # An array of strings with read permissions. By default no user is granted with any read permissions. [learn more about permissions](/docs/permissions) and get a full list of available permissions.
  rules: list<string> # Array of [rule objects](/docs/rules). Each rule define a collection field name, data type and validation.
  write: list<string> # An array of strings with write permissions. By default no user is granted with any write permissions. [learn more about permissions](/docs/permissions) and get a full list of available permissions.
]: any -> record<_id: string, _permissions: record, dateCreated: int, dateUpdated: int, name: string, rules: table<_collection: string, _id: string, array: bool, default: string, key: string, label: string, list: list, required: bool, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/database/collections")
  let req_body = {"name": $name, "read": $read, "rules": $rules, "write": $write} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete Collection
#
# DELETE /database/collections/{collectionId}
# operationId: databaseDeleteCollection
export def "database-collections delete" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/database/collections/{collection_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Collection
#
# GET /database/collections/{collectionId}
# operationId: databaseGetCollection
export def "database-collections get" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_id: string, _permissions: record, dateCreated: int, dateUpdated: int, name: string, rules: table<_collection: string, _id: string, array: bool, default: string, key: string, label: string, list: list, required: bool, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/database/collections/{collection_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Collection
#
# PUT /database/collections/{collectionId}
# operationId: databaseUpdateCollection
export def "database-collections update" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Collection name. Max length: 128 chars.
  --read: list<string> # An array of strings with read permissions. By default inherits the existing read permissions. [learn more about permissions](/docs/permissions) and get a full list of available permissions.
  --rules: list<string> # Array of [rule objects](/docs/rules). Each rule define a collection field name, data type and validation.
  --write: list<string> # An array of strings with write permissions. By default inherits the existing write permissions. [learn more about permissions](/docs/permissions) and get a full list of available permissions.
]: any -> record<_id: string, _permissions: record, dateCreated: int, dateUpdated: int, name: string, rules: table<_collection: string, _id: string, array: bool, default: string, key: string, label: string, list: list, required: bool, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/database/collections/{collection_id}"))
  let req_body = {"name": $name, "read": $read, "rules": $rules, "write": $write} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List Documents
#
# GET /database/collections/{collectionId}/documents
# operationId: databaseListDocuments
export def "database-collections-documents list" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list<string> # Array of filter strings. Each filter is constructed from a key name, comparison operator (=, !=, >, <, <=, >=) and a value. You can also use a dot (.) separator in attribute names to filter by child document attributes. Examples: 'name=John Doe' or 'category.$id>=5bed2d152c362'. (default: [])
  --limit: int # Maximum number of documents to return in response. Use this value to manage pagination. By default will return maximum 25 results. Maximum of 100 results allowed per request. (format: int32, default: 25)
  --offset: int # Offset value. The default value is 0. Use this param to manage pagination. (format: int32, default: 0)
  --order-field: string # Document field that results will be sorted by. (default: )
  --order-type: string # Order direction. Possible values are DESC for descending order, or ASC for ascending order. (default: ASC)
  --order-cast: string # Order field type casting. Possible values are int, string, date, time or datetime. The database will attempt to cast the order field to the value you pass here. The default value is a string. (default: string)
  --search: string # Search query. Enter any free text search. The database will try to find a match against all document attributes and children. Max length: 256 chars. (default: )
]: nothing -> record<documents: table<_collection: string, _id: string, _permissions: record>, sum: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "orderField" $order_field "scalar") (serialize-qp "orderType" $order_type "scalar") (serialize-qp "orderCast" $order_cast "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/database/collections/{collection_id}/documents") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Document
#
# POST /database/collections/{collectionId}/documents
# operationId: databaseCreateDocument
export def "database-collections-documents create" [
  collection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # Document data as JSON object.
  --parent-document: string # Parent document unique ID. Use when you want your new document to be a child of a parent document.
  --parent-property: string # Parent document property name. Use when you want your new document to be a child of a parent document.
  --parent-property-type: string # Parent document property connection type. You can set this value to **assign**, **append** or **prepend**, default value is assign. Use when you want your new document to be a child of a parent document.
  --read: list<string> # An array of strings with read permissions. By default only the current user is granted with read permissions. [learn more about permissions](/docs/permissions) and get a full list of available permissions.
  --write: list<string> # An array of strings with write permissions. By default only the current user is granted with write permissions. [learn more about permissions](/docs/permissions) and get a full list of available permissions.
]: any -> record<_collection: string, _id: string, _permissions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id)} | format pattern "/database/collections/{collection_id}/documents"))
  let req_body = {"data": $data, "parentDocument": $parent_document, "parentProperty": $parent_property, "parentPropertyType": $parent_property_type, "read": $read, "write": $write} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete Document
#
# DELETE /database/collections/{collectionId}/documents/{documentId}
# operationId: databaseDeleteDocument
export def "database-collections-documents delete" [
  collection_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id), document_id: (encode-path-segment $document_id)} | format pattern "/database/collections/{collection_id}/documents/{document_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Document
#
# GET /database/collections/{collectionId}/documents/{documentId}
# operationId: databaseGetDocument
export def "database-collections-documents get" [
  collection_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_collection: string, _id: string, _permissions: record> {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id), document_id: (encode-path-segment $document_id)} | format pattern "/database/collections/{collection_id}/documents/{document_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Document
#
# PATCH /database/collections/{collectionId}/documents/{documentId}
# operationId: databaseUpdateDocument
export def "database-collections-documents update" [
  collection_id: string
  document_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  data: record # Document data as JSON object.
  --read: list<string> # An array of strings with read permissions. By default inherits the existing read permissions. [learn more about permissions](/docs/permissions) and get a full list of available permissions.
  --write: list<string> # An array of strings with write permissions. By default inherits the existing write permissions. [learn more about permissions](/docs/permissions) and get a full list of available permissions.
]: any -> record<_collection: string, _id: string, _permissions: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({collection_id: (encode-path-segment $collection_id), document_id: (encode-path-segment $document_id)} | format pattern "/database/collections/{collection_id}/documents/{document_id}"))
  let req_body = {"data": $data, "read": $read, "write": $write} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List Functions
#
# GET /functions
# operationId: functionsList
export def "functions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search term to filter your list results. Max length: 256 chars. (default: )
  --limit: int # Results limit value. By default will return maximum 25 results. Maximum of 100 results allowed per request. (format: int32, default: 25)
  --offset: int # Results offset. The default value is 0. Use this param to manage pagination. (format: int32, default: 0)
  --order-type: string # Order result by ASC or DESC order. (default: ASC)
]: nothing -> record<functions: table<_id: string, _permissions: record, dateCreated: int, dateUpdated: int, events: list, name: string, runtime: string, schedule: string, scheduleNext: int, schedulePrevious: int, status: string, tag: string, timeout: int, vars: string>, sum: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "orderType" $order_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/functions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Function
#
# POST /functions
# operationId: functionsCreate
export def "functions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --events: list<string> # Events list.
  execute: list<string> # An array of strings with execution permissions. By default no user is granted with any execute permissions. [learn more about permissions](/docs/permissions) and get a full list of available permissions.
  name: string # Function name. Max length: 128 chars.
  runtime: string # Execution runtime.
  --schedule: string # Schedule CRON syntax.
  --timeout: int # Function maximum execution time in seconds.
  --vars: record # Key-value JSON object.
]: any -> record<_id: string, _permissions: record, dateCreated: int, dateUpdated: int, events: list<string>, name: string, runtime: string, schedule: string, scheduleNext: int, schedulePrevious: int, status: string, tag: string, timeout: int, vars: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/functions")
  let req_body = {"events": $events, "execute": $execute, "name": $name, "runtime": $runtime, "schedule": $schedule, "timeout": $timeout, "vars": $vars} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete Function
#
# DELETE /functions/{functionId}
# operationId: functionsDelete
export def "functions delete" [
  function_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({function_id: (encode-path-segment $function_id)} | format pattern "/functions/{function_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Function
#
# GET /functions/{functionId}
# operationId: functionsGet
export def "functions get" [
  function_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_id: string, _permissions: record, dateCreated: int, dateUpdated: int, events: list<string>, name: string, runtime: string, schedule: string, scheduleNext: int, schedulePrevious: int, status: string, tag: string, timeout: int, vars: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({function_id: (encode-path-segment $function_id)} | format pattern "/functions/{function_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Function
#
# PUT /functions/{functionId}
# operationId: functionsUpdate
export def "functions update" [
  function_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --events: list<string> # Events list.
  execute: list<string> # An array of strings with execution permissions. By default no user is granted with any execute permissions. [learn more about permissions](/docs/permissions) and get a full list of available permissions.
  name: string # Function name. Max length: 128 chars.
  --schedule: string # Schedule CRON syntax.
  --timeout: int # Function maximum execution time in seconds.
  --vars: record # Key-value JSON object.
]: any -> record<_id: string, _permissions: record, dateCreated: int, dateUpdated: int, events: list<string>, name: string, runtime: string, schedule: string, scheduleNext: int, schedulePrevious: int, status: string, tag: string, timeout: int, vars: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({function_id: (encode-path-segment $function_id)} | format pattern "/functions/{function_id}"))
  let req_body = {"events": $events, "execute": $execute, "name": $name, "schedule": $schedule, "timeout": $timeout, "vars": $vars} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List Executions
#
# GET /functions/{functionId}/executions
# operationId: functionsListExecutions
export def "functions-executions list" [
  function_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search term to filter your list results. Max length: 256 chars. (default: )
  --limit: int # Results limit value. By default will return maximum 25 results. Maximum of 100 results allowed per request. (format: int32, default: 25)
  --offset: int # Results offset. The default value is 0. Use this param to manage pagination. (format: int32, default: 0)
  --order-type: string # Order result by ASC or DESC order. (default: ASC)
]: nothing -> record<executions: table<_id: string, dateCreated: int, exitCode: int, functionId: string, status: string, stderr: string, stdout: string, time: float, trigger: string>, sum: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "orderType" $order_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({function_id: (encode-path-segment $function_id)} | format pattern "/functions/{function_id}/executions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Execution
#
# POST /functions/{functionId}/executions
# operationId: functionsCreateExecution
export def "functions-executions create" [
  function_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: string # String of custom data to send to function.
]: any -> record<_id: string, dateCreated: int, exitCode: int, functionId: string, status: string, stderr: string, stdout: string, time: float, trigger: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({function_id: (encode-path-segment $function_id)} | format pattern "/functions/{function_id}/executions"))
  let req_body = {"data": $data} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get Execution
#
# GET /functions/{functionId}/executions/{executionId}
# operationId: functionsGetExecution
export def "functions-executions get" [
  function_id: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_id: string, dateCreated: int, exitCode: int, functionId: string, status: string, stderr: string, stdout: string, time: float, trigger: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({function_id: (encode-path-segment $function_id), execution_id: (encode-path-segment $execution_id)} | format pattern "/functions/{function_id}/executions/{execution_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Function Tag
#
# PATCH /functions/{functionId}/tag
# operationId: functionsUpdateTag
export def "functions-tag update" [
  function_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  tag: string # Tag unique ID.
]: any -> record<_id: string, _permissions: record, dateCreated: int, dateUpdated: int, events: list<string>, name: string, runtime: string, schedule: string, scheduleNext: int, schedulePrevious: int, status: string, tag: string, timeout: int, vars: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({function_id: (encode-path-segment $function_id)} | format pattern "/functions/{function_id}/tag"))
  let req_body = {"tag": $tag} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List Tags
#
# GET /functions/{functionId}/tags
# operationId: functionsListTags
export def "functions-tags list" [
  function_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search term to filter your list results. Max length: 256 chars. (default: )
  --limit: int # Results limit value. By default will return maximum 25 results. Maximum of 100 results allowed per request. (format: int32, default: 25)
  --offset: int # Results offset. The default value is 0. Use this param to manage pagination. (format: int32, default: 0)
  --order-type: string # Order result by ASC or DESC order. (default: ASC)
]: nothing -> record<sum: int, tags: table<_id: string, command: string, dateCreated: int, functionId: string, size: string>> {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "orderType" $order_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({function_id: (encode-path-segment $function_id)} | format pattern "/functions/{function_id}/tags") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Tag
#
# POST /functions/{functionId}/tags
# operationId: functionsCreateTag
export def "functions-tags create" [
  function_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string # Gzip file with your code package. When used with the Appwrite CLI, pass the path to your code directory, and the CLI will automatically package your code. Use a path that is within the current directory.
  command: string # Code execution command.
]: any -> record<_id: string, command: string, dateCreated: int, functionId: string, size: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({function_id: (encode-path-segment $function_id)} | format pattern "/functions/{function_id}/tags"))
  let req_body = {"code": $code, "command": $command} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Delete Tag
#
# DELETE /functions/{functionId}/tags/{tagId}
# operationId: functionsDeleteTag
export def "functions-tags delete" [
  function_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({function_id: (encode-path-segment $function_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/functions/{function_id}/tags/{tag_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Tag
#
# GET /functions/{functionId}/tags/{tagId}
# operationId: functionsGetTag
export def "functions-tags get" [
  function_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_id: string, command: string, dateCreated: int, functionId: string, size: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({function_id: (encode-path-segment $function_id), tag_id: (encode-path-segment $tag_id)} | format pattern "/functions/{function_id}/tags/{tag_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get HTTP
#
# GET /health
# operationId: healthGet
export def "health get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Anti virus
#
# GET /health/anti-virus
# operationId: healthGetAntiVirus
export def "health-anti-virus get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health/anti-virus")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Cache
#
# GET /health/cache
# operationId: healthGetCache
export def "health-cache get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health/cache")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get DB
#
# GET /health/db
# operationId: healthGetDB
export def "health-db get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health/db")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Certificate Queue
#
# GET /health/queue/certificates
# operationId: healthGetQueueCertificates
export def "health-queue-certificates get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health/queue/certificates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Functions Queue
#
# GET /health/queue/functions
# operationId: healthGetQueueFunctions
export def "health-queue-functions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health/queue/functions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Logs Queue
#
# GET /health/queue/logs
# operationId: healthGetQueueLogs
export def "health-queue-logs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health/queue/logs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Tasks Queue
#
# GET /health/queue/tasks
# operationId: healthGetQueueTasks
export def "health-queue-tasks get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health/queue/tasks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Usage Queue
#
# GET /health/queue/usage
# operationId: healthGetQueueUsage
export def "health-queue-usage get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health/queue/usage")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Webhooks Queue
#
# GET /health/queue/webhooks
# operationId: healthGetQueueWebhooks
export def "health-queue-webhooks get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health/queue/webhooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Local Storage
#
# GET /health/storage/local
# operationId: healthGetStorageLocal
export def "health-storage-local get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health/storage/local")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Time
#
# GET /health/time
# operationId: healthGetTime
export def "health-time get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health/time")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get User Locale
#
# GET /locale
# operationId: localeGet
export def "locale get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<continent: string, continentCode: string, country: string, countryCode: string, currency: string, eu: bool, ip: string> {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/locale")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Continents
#
# GET /locale/continents
# operationId: localeGetContinents
export def "locale-continents get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<continents: table<code: string, name: string>, sum: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/locale/continents")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Countries
#
# GET /locale/countries
# operationId: localeGetCountries
export def "locale-countries get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<countries: table<code: string, name: string>, sum: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/locale/countries")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List EU Countries
#
# GET /locale/countries/eu
# operationId: localeGetCountriesEU
export def "locale-countries-eu get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<countries: table<code: string, name: string>, sum: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/locale/countries/eu")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Countries Phone Codes
#
# GET /locale/countries/phones
# operationId: localeGetCountriesPhones
export def "locale-countries-phones get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<phones: table<code: string, countryCode: string, countryName: string>, sum: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/locale/countries/phones")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Currencies
#
# GET /locale/currencies
# operationId: localeGetCurrencies
export def "locale-currencies get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<currencies: table<code: string, decimalDigits: int, name: string, namePlural: string, rounding: float, symbol: string, symbolNative: string>, sum: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/locale/currencies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Languages
#
# GET /locale/languages
# operationId: localeGetLanguages
export def "locale-languages get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<languages: table<code: string, name: string, nativeName: string>, sum: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/locale/languages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Files
#
# GET /storage/files
# operationId: storageListFiles
export def "storage-files list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search term to filter your list results. Max length: 256 chars. (default: )
  --limit: int # Results limit value. By default will return maximum 25 results. Maximum of 100 results allowed per request. (format: int32, default: 25)
  --offset: int # Results offset. The default value is 0. Use this param to manage pagination. (format: int32, default: 0)
  --order-type: string # Order result by ASC or DESC order. (default: ASC)
]: nothing -> record<files: table<_id: string, _permissions: record, dateCreated: int, mimeType: string, name: string, signature: string, sizeOriginal: int>, sum: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "orderType" $order_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/storage/files" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create File
#
# POST /storage/files
# operationId: storageCreateFile
export def "storage-files create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # Binary file.
  --read: list<string> # An array of strings with read permissions. By default only the current user is granted with read permissions. [learn more about permissions](/docs/permissions) and get a full list of available permissions.
  --write: list<string> # An array of strings with write permissions. By default only the current user is granted with write permissions. [learn more about permissions](/docs/permissions) and get a full list of available permissions.
]: any -> record<_id: string, _permissions: record, dateCreated: int, mimeType: string, name: string, signature: string, sizeOriginal: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/storage/files")
  let req_body = {"file": $file, "read": $read, "write": $write} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let mp = (build-multipart-body $req_body [])
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $mp.content_type $mp.body
}

# Delete File
#
# DELETE /storage/files/{fileId}
# operationId: storageDeleteFile
export def "storage-files delete" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id)} | format pattern "/storage/files/{file_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get File
#
# GET /storage/files/{fileId}
# operationId: storageGetFile
export def "storage-files get" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_id: string, _permissions: record, dateCreated: int, mimeType: string, name: string, signature: string, sizeOriginal: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id)} | format pattern "/storage/files/{file_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update File
#
# PUT /storage/files/{fileId}
# operationId: storageUpdateFile
export def "storage-files update" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  read: list<string> # An array of strings with read permissions. By default no user is granted with any read permissions. [learn more about permissions](/docs/permissions) and get a full list of available permissions.
  write: list<string> # An array of strings with write permissions. By default no user is granted with any write permissions. [learn more about permissions](/docs/permissions) and get a full list of available permissions.
]: any -> record<_id: string, _permissions: record, dateCreated: int, mimeType: string, name: string, signature: string, sizeOriginal: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id)} | format pattern "/storage/files/{file_id}"))
  let req_body = {"read": $read, "write": $write} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get File for Download
#
# GET /storage/files/{fileId}/download
# operationId: storageGetFileDownload
export def "storage-files-download get" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id)} | format pattern "/storage/files/{file_id}/download"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get File Preview
#
# GET /storage/files/{fileId}/preview
# operationId: storageGetFilePreview
export def "storage-files-preview get" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --width: int # Resize preview image width, Pass an integer between 0 to 4000. (format: int32, default: 0)
  --height: int # Resize preview image height, Pass an integer between 0 to 4000. (format: int32, default: 0)
  --gravity: string # Image crop gravity. Can be one of center,top-left,top,top-right,left,right,bottom-left,bottom,bottom-right (default: center)
  --quality: int # Preview image quality. Pass an integer between 0 to 100. Defaults to 100. (format: int32, default: 100)
  --border-width: int # Preview image border in pixels. Pass an integer between 0 to 100. Defaults to 0. (format: int32, default: 0)
  --border-color: string # Preview image border color. Use a valid HEX color, no # is needed for prefix. (default: )
  --border-radius: int # Preview image border radius in pixels. Pass an integer between 0 to 4000. (format: int32, default: 0)
  --opacity: float # Preview image opacity. Only works with images having an alpha channel (like png). Pass a number between 0 to 1. (format: float, default: 1)
  --rotation: int # Preview image rotation in degrees. Pass an integer between 0 and 360. (format: int32, default: 0)
  --background: string # Preview image background color. Only works with transparent images (png). Use a valid HEX color, no # is needed for prefix. (default: )
  --output: string # Output format type (jpeg, jpg, png, gif and webp). (default: )
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "width" $width "scalar") (serialize-qp "height" $height "scalar") (serialize-qp "gravity" $gravity "scalar") (serialize-qp "quality" $quality "scalar") (serialize-qp "borderWidth" $border_width "scalar") (serialize-qp "borderColor" $border_color "scalar") (serialize-qp "borderRadius" $border_radius "scalar") (serialize-qp "opacity" $opacity "scalar") (serialize-qp "rotation" $rotation "scalar") (serialize-qp "background" $background "scalar") (serialize-qp "output" $output "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id)} | format pattern "/storage/files/{file_id}/preview") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get File for View
#
# GET /storage/files/{fileId}/view
# operationId: storageGetFileView
export def "storage-files-view get" [
  file_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: (encode-path-segment $file_id)} | format pattern "/storage/files/{file_id}/view"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Teams
#
# GET /teams
# operationId: teamsList
export def "teams list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search term to filter your list results. Max length: 256 chars. (default: )
  --limit: int # Results limit value. By default will return maximum 25 results. Maximum of 100 results allowed per request. (format: int32, default: 25)
  --offset: int # Results offset. The default value is 0. Use this param to manage pagination. (format: int32, default: 0)
  --order-type: string # Order result by ASC or DESC order. (default: ASC)
]: nothing -> record<sum: int, teams: table<_id: string, dateCreated: int, name: string, sum: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "orderType" $order_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/teams" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Team
#
# POST /teams
# operationId: teamsCreate
export def "teams create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Team name. Max length: 128 chars.
  --roles: list<string> # Array of strings. Use this param to set the roles in the team for the user who created it. The default role is **owner**. A role can be any string. Learn more about [roles and permissions](/docs/permissions). Max length for each role is 32 chars.
]: any -> record<_id: string, dateCreated: int, name: string, sum: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/teams")
  let req_body = {"name": $name, "roles": $roles} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete Team
#
# DELETE /teams/{teamId}
# operationId: teamsDelete
export def "teams delete" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({team_id: (encode-path-segment $team_id)} | format pattern "/teams/{team_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Team
#
# GET /teams/{teamId}
# operationId: teamsGet
export def "teams get" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_id: string, dateCreated: int, name: string, sum: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({team_id: (encode-path-segment $team_id)} | format pattern "/teams/{team_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Team
#
# PUT /teams/{teamId}
# operationId: teamsUpdate
export def "teams update" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Team name. Max length: 128 chars.
]: any -> record<_id: string, dateCreated: int, name: string, sum: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({team_id: (encode-path-segment $team_id)} | format pattern "/teams/{team_id}"))
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get Team Memberships
#
# GET /teams/{teamId}/memberships
# operationId: teamsGetMemberships
export def "teams-memberships get" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search term to filter your list results. Max length: 256 chars. (default: )
  --limit: int # Results limit value. By default will return maximum 25 results. Maximum of 100 results allowed per request. (format: int32, default: 25)
  --offset: int # Results offset. The default value is 0. Use this param to manage pagination. (format: int32, default: 0)
  --order-type: string # Order result by ASC or DESC order. (default: ASC)
]: nothing -> record<memberships: table<_id: string, confirm: bool, email: string, invited: int, joined: int, name: string, roles: list, teamId: string, userId: string>, sum: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "orderType" $order_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({team_id: (encode-path-segment $team_id)} | format pattern "/teams/{team_id}/memberships") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Team Membership
#
# POST /teams/{teamId}/memberships
# operationId: teamsCreateMembership
export def "teams-memberships create" [
  team_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # New team member email.
  --name: string # New team member name. Max length: 128 chars.
  roles: list<string> # Array of strings. Use this param to set the user roles in the team. A role can be any string. Learn more about [roles and permissions](/docs/permissions). Max length for each role is 32 chars.
  url: string # URL to redirect the user back to your app from the invitation email. Only URLs from hostnames in your project platform list are allowed. This requirement helps to prevent an [open redirect](https://cheatsheetseries.owasp.org/cheatsheets/Unvalidated_Redirects_and_Forwards_Cheat_Sheet.html) attack against your project API.
]: any -> record<_id: string, confirm: bool, email: string, invited: int, joined: int, name: string, roles: list<string>, teamId: string, userId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({team_id: (encode-path-segment $team_id)} | format pattern "/teams/{team_id}/memberships"))
  let req_body = {"email": $email, "name": $name, "roles": $roles, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete Team Membership
#
# DELETE /teams/{teamId}/memberships/{membershipId}
# operationId: teamsDeleteMembership
export def "teams-memberships delete" [
  team_id: string
  membership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({team_id: (encode-path-segment $team_id), membership_id: (encode-path-segment $membership_id)} | format pattern "/teams/{team_id}/memberships/{membership_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Membership Roles
#
# PATCH /teams/{teamId}/memberships/{membershipId}
# operationId: teamsUpdateMembershipRoles
export def "teams-memberships update-roles" [
  team_id: string
  membership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  roles: list<string> # Array of strings. Use this param to set the user roles in the team. A role can be any string. Learn more about [roles and permissions](/docs/permissions). Max length for each role is 32 chars.
]: any -> record<_id: string, confirm: bool, email: string, invited: int, joined: int, name: string, roles: list<string>, teamId: string, userId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({team_id: (encode-path-segment $team_id), membership_id: (encode-path-segment $membership_id)} | format pattern "/teams/{team_id}/memberships/{membership_id}"))
  let req_body = {"roles": $roles} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update Team Membership Status
#
# PATCH /teams/{teamId}/memberships/{membershipId}/status
# operationId: teamsUpdateMembershipStatus
export def "teams-memberships-status update" [
  team_id: string
  membership_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  secret: string # Secret key.
  user_id: string # User unique ID.
]: any -> record<_id: string, confirm: bool, email: string, invited: int, joined: int, name: string, roles: list<string>, teamId: string, userId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({team_id: (encode-path-segment $team_id), membership_id: (encode-path-segment $membership_id)} | format pattern "/teams/{team_id}/memberships/{membership_id}/status"))
  let req_body = {"secret": $secret, "userId": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List Users
#
# GET /users
# operationId: usersList
export def "users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search: string # Search term to filter your list results. Max length: 256 chars. (default: )
  --limit: int # Results limit value. By default will return maximum 25 results. Maximum of 100 results allowed per request. (format: int32, default: 25)
  --offset: int # Results offset. The default value is 0. Use this param to manage pagination. (format: int32, default: 0)
  --order-type: string # Order result by ASC or DESC order. (default: ASC)
]: nothing -> record<sum: int, users: table<_id: string, email: string, emailVerification: bool, name: string, passwordUpdate: int, prefs: record, registration: int, status: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "orderType" $order_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create User
#
# POST /users
# operationId: usersCreate
export def "users create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # User email.
  --name: string # User name. Max length: 128 chars.
  password: string # User password. Must be between 6 to 32 chars.
]: any -> record<_id: string, email: string, emailVerification: bool, name: string, passwordUpdate: int, prefs: record, registration: int, status: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users")
  let req_body = {"email": $email, "name": $name, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete User
#
# DELETE /users/{userId}
# operationId: usersDelete
export def "users delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get User
#
# GET /users/{userId}
# operationId: usersGet
export def "users get" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<_id: string, email: string, emailVerification: bool, name: string, passwordUpdate: int, prefs: record, registration: int, status: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get User Logs
#
# GET /users/{userId}/logs
# operationId: usersGetLogs
export def "users-logs get" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<logs: table<clientCode: string, clientEngine: string, clientEngineVersion: string, clientName: string, clientType: string, clientVersion: string, countryCode: string, countryName: string, deviceBrand: string, deviceModel: string, deviceName: string, event: string, ip: string, osCode: string, osName: string, osVersion: string, time: int>> {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/logs"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get User Preferences
#
# GET /users/{userId}/prefs
# operationId: usersGetPrefs
export def "users-prefs get" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/prefs"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update User Preferences
#
# PATCH /users/{userId}/prefs
# operationId: usersUpdatePrefs
export def "users-prefs update" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  prefs: record # Prefs key-value JSON object.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/prefs"))
  let req_body = {"prefs": $prefs} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete User Sessions
#
# DELETE /users/{userId}/sessions
# operationId: usersDeleteSessions
export def "users-sessions delete-by-userId" [
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
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/sessions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get User Sessions
#
# GET /users/{userId}/sessions
# operationId: usersGetSessions
export def "users-sessions get" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<sessions: table<_id: string, clientCode: string, clientEngine: string, clientEngineVersion: string, clientName: string, clientType: string, clientVersion: string, countryCode: string, countryName: string, current: bool, deviceBrand: string, deviceModel: string, deviceName: string, expire: int, ip: string, osCode: string, osName: string, osVersion: string, provider: string, providerToken: string, providerUid: string, userId: string>, sum: int> {
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/sessions"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete User Session
#
# DELETE /users/{userId}/sessions/{sessionId}
# operationId: usersDeleteSession
export def "users-sessions delete-by-userId-sessionId" [
  user_id: string
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
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id), session_id: (encode-path-segment $session_id)} | format pattern "/users/{user_id}/sessions/{session_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update User Status
#
# PATCH /users/{userId}/status
# operationId: usersUpdateStatus
export def "users-status update" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  status: int # User Status code. To activate the user pass 1, to block the user pass 2 and for disabling the user pass 0
]: any -> record<_id: string, email: string, emailVerification: bool, name: string, passwordUpdate: int, prefs: record, registration: int, status: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/status"))
  let req_body = {"status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Update Email Verification
#
# PATCH /users/{userId}/verification
# operationId: usersUpdateVerification
export def "users-verification update" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email-verification: oneof<nothing, bool> # User Email Verification Status.
]: any -> record<_id: string, email: string, emailVerification: bool, name: string, passwordUpdate: int, prefs: record, registration: int, status: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "x-appwrite-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/verification"))
  let req_body = {"emailVerification": $email_verification} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
