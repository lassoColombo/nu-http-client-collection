# Auto-generated client for IoE² IoT API - to create end-user applications v3.0.0
# Source: https://api.apis.guru/v2/specs/ijenko.net/3.0.0/swagger.json
# Auth: --token flag or $env.IOE_IOT_API___TO_CREATE_END_USER_APPLICATIONS_TOKEN

const BASE_URL = "https://ioe2api.ijenko.net"
const DEFAULT_AUTH = "query-token"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o IOE_IOT_API___TO_CREATE_END_USER_APPLICATIONS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "access-token" => { {headers: {Access-Token: $token_val}, query: ""} }
    "query-token" => { {headers: {}, query: $"token=($token_val)"} }
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

def base-url-completer [] { ["https://ioe2api.ijenko.net"] }
def auth-scheme-completer [] { ["access-token" "query-token"] }

# Completers for enum parameters
def span-completer [] { ["D" "H" "M" "Wmo" "Wsu" "Y"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account-change-password AccountchangePassword" } } | get name | first)
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

# Change the password
#
# POST /account/change-password
# operationId: Account.changePassword
export def "account-change-password AccountchangePassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  newPassword: string # format: password
  oldPassword: string # format: password
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/change-password")
  let body = {newPassword: $newPassword, oldPassword: $oldPassword} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Places of the Account
#
# GET /account/places
# operationId: Account.places
export def "account-places Accountplaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/places")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Place
#
# POST /account/places
# operationId: Account.newPlace
export def "account-places AccountnewPlace" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  country: string # Country code (ISO 3166-1 alpha-2) (e.g. FR)
  --metadata: record # Keys are limited to the same format as tags (up to 21 characters, [a-z0-9], starting with [a-z]). Values can be any JSON value.
  name: string # e.g. ⌂ Home
  timeZone: string # A time zone name from the Time Zone Database at https://www.iana.org/time-zones (e.g. Europe/Paris)
  zipCode: string # Postal code
]: any -> record<code: int, message: string, resource: record<entity: string, href: string, id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/places")
  let body = {country: $country, metadata: $metadata, name: $name, timeZone: $timeZone, zipCode: $zipCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List active Tokens of the Account
#
# GET /account/tokens
# operationId: Account.tokens
export def "account-tokens Accounttokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<appName: string, id: string, lastUse: string, places: list<record>, refreshTokenExpires: string, self: bool, user: record<canLogin: bool, email: string, id: string, locale: string, metadata: record, name: string, phoneNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/tokens")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revoke a Token
#
# DELETE /account/tokens/{tokenId}
# operationId: Account.revokeToken
export def "account-tokens AccountrevokeToken" [
  tokenId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/tokens/($tokenId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Users of the Account
#
# GET /account/users
# operationId: Account.users
export def "account-users Accountusers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed-metadata: list # Request to include the given keys of metadata in the response. If a key doesn't exist on the resource it is ignored. **Note:** This only applies to the top level resources.
]: nothing -> table<canLogin: bool, email: string, id: string, locale: string, metadata: record, name: string, phoneNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "embed-metadata" $embed_metadata "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/account/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# New User
#
# POST /account/users
# operationId: Account.newUser
export def "account-users AccountnewUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  email: string # format: email
  locale: string # Locale identifier (language, region). See https://tools.ietf.org/html/rfc5646 and https://www.iana.org/assignments/lang-subtags-templates/lang-subtags-templates.xhtml .  (e.g. fr-FR)
  --metadata: record # Keys are limited to the same format as tags (up to 21 characters, [a-z0-9], starting with [a-z]). Values can be any JSON value.
  name: string
  --phoneNumber: string # Phone number of the *User* in international format, for SMS notifications. (e.g. +33177494646)
]: any -> record<code: int, message: string, resource: record<entity: string, href: string, id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/account/users")
  let body = {email: $email, locale: $locale, metadata: $metadata, name: $name, phoneNumber: $phoneNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a User
#
# DELETE /account/users/{userId}
# operationId: Account.deleteUser
export def "account-users AccountdeleteUser" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/users/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Information about a User
#
# GET /account/users/{userId}
# operationId: Account.getUser
export def "account-users AccountgetUser" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account: string, canLogin: bool, email: string, locale: string, metadata: record, name: string, phoneNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/users/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a User
#
# PATCH /account/users/{userId}
# operationId: Account.patchUser
export def "account-users AccountpatchUser" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string # format: email
  --locale: string # Locale identifier (language, region). See https://tools.ietf.org/html/rfc5646 and https://www.iana.org/assignments/lang-subtags-templates/lang-subtags-templates.xhtml .  (e.g. fr-FR)
  --name: string
  --phoneNumber: string # Phone number of the *User* in international format, for SMS notifications. (e.g. +33177494646)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/users/($userId)")
  let body = {email: $email, locale: $locale, name: $name, phoneNumber: $phoneNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List metadata
#
# GET /account/users/{userId}/metadata
# operationId: User.getMetadata
export def "account-users-metadata UsergetMetadata" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/users/($userId)/metadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify metadata
#
# PATCH /account/users/{userId}/metadata
# operationId: User.patchMetadata
export def "account-users-metadata UserpatchMetadata" [
  userId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/account/users/($userId)/metadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a token using login+password
#
# POST /auth/login
# operationId: AuthAccountLogin
export def "auth-login AuthAccountLogin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  appId: string
  login: string
  password: string # format: password
  --ttl: int # Desired maximum life-time in seconds for the refresh token (e.g. 1800)
]: any -> record<accessToken: string, accessTokenExpires: string, refreshToken: string, refreshTokenExpires: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/login")
  let body = {appId: $appId, login: $login, password: $password, ttl: $ttl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Refresh a token
#
# POST /auth/refresh
# operationId: AuthRefreshToken
export def "auth-refresh AuthRefreshToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  appId: string
  refreshToken: string
]: any -> record<accessToken: string, accessTokenExpires: string, refreshToken: string, refreshTokenExpires: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/refresh")
  let body = {appId: $appId, refreshToken: $refreshToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Ask for a new password
#
# POST /auth/reset-password
# operationId: AuthResetPassword
export def "auth-reset-password AuthResetPassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  appId: string
  --email: string # format: email
  --login: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/reset-password")
  let body = {appId: $appId, email: $email, login: $login} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revoke a token
#
# POST /auth/revoke
# operationId: AuthRevokeToken
export def "auth-revoke AuthRevokeToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/revoke")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Information about a Device
#
# GET /devices/{deviceId}
# operationId: Devices.get
export def "devices Devicesget" [
  deviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<address: string, attributes: record, class: string, functionalities: table<class: string, device: string, endpoint: int, id: string, metadata: record, name: string, tags: list>, isOnline: bool, manufacturer: string, metadata: record, model: string, name: string, place: string, protocol: string, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/devices/($deviceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Device
#
# PATCH /devices/{deviceId}
# operationId: Devices.patch
export def "devices Devicespatch" [
  deviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Name of the *Device* as defined by the user. Can be used for user interfaces.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/devices/($deviceId)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add dynamically a functionality
#
# POST /devices/{deviceId}/functionalities
# operationId: Device.addFunctionality
export def "devices-functionalities DeviceaddFunctionality" [
  deviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --metadata: record # Keys are limited to the same format as tags (up to 21 characters, [a-z0-9], starting with [a-z]). Values can be any JSON value.
  --name: string # Free functionality name
  --tags: list
]: any -> record<code: int, message: string, resource: record<entity: string, href: string, id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/devices/($deviceId)/functionalities")
  let body = {metadata: $metadata, name: $name, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List metadata
#
# GET /devices/{deviceId}/metadata
# operationId: Device.getMetadata
export def "devices-metadata DevicegetMetadata" [
  deviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/devices/($deviceId)/metadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify metadata
#
# PATCH /devices/{deviceId}/metadata
# operationId: Device.patchMetadata
export def "devices-metadata DevicepatchMetadata" [
  deviceId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/devices/($deviceId)/metadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Run actions
#
# POST /devices/{deviceId}/run/{action}
# operationId: Device.run
export def "devices-run Devicerun" [
  deviceId: string
  action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --functionalities: string # Functionality selector: Functionality tags or functionality class (optionally, '@' followed by a endpoint in decimal) or '*' for all. Multiple values are separated by '|' and are interpreted as « OR ».
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "functionalities" $functionalities "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/devices/($deviceId)/run/($action)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List tags
#
# GET /devices/{deviceId}/tags
# operationId: Device.getTags
export def "devices-tags DevicegetTags" [
  deviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/devices/($deviceId)/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify tags
#
# PATCH /devices/{deviceId}/tags
# operationId: Device.patchTags
export def "devices-tags DevicepatchTags" [
  deviceId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/devices/($deviceId)/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Information about a Functionality
#
# GET /functionalities/{functionalityId}
# operationId: Functionalities.get
export def "functionalities Functionalitiesget" [
  functionalityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<actions: list<string>, attributes: list<string>, class: string, device: string, endpoint: int, metadata: record, name: string, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/functionalities/($functionalityId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Functionality
#
# PATCH /functionalities/{functionalityId}
# operationId: Functionality.patch
export def "functionalities Functionalitypatch" [
  functionalityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --name: string # Free functionality name
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/functionalities/($functionalityId)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get history of multiple attributes
#
# GET /functionalities/{functionalityId}/attributes
# operationId: Functionality.values
export def "functionalities-attributes Functionalityvalues" [
  functionalityId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --names: list # One or multiple *Attribute* names separated by commas
  --qp-from: string # Beginning of the time interval. (format: date-time)
  --qp-to: string # End of the interval. Default: now.  (format: date-time)
  --surround: oneof<nothing, bool> # If true, return also one value before from and one value after to
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "names" $names "csv") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "surround" $surround "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/functionalities/($functionalityId)/attributes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an Attribute value
#
# GET /functionalities/{functionalityId}/attributes/{attributeName}
# operationId: Functionality.value
export def "functionalities-attributes Functionalityvalue" [
  functionalityId: string
  attributeName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<value: any, when: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/functionalities/($functionalityId)/attributes/($attributeName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify an Attribute value
#
# PUT /functionalities/{functionalityId}/attributes/{attributeName}
# operationId: Functionality.set
export def "functionalities-attributes Functionalityset" [
  functionalityId: string
  attributeName: string
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
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/functionalities/($functionalityId)/attributes/($attributeName)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List metadata
#
# GET /functionalities/{functionalityId}/metadata
# operationId: Functionality.getMetadata
export def "functionalities-metadata FunctionalitygetMetadata" [
  functionalityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/functionalities/($functionalityId)/metadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify metadata
#
# PATCH /functionalities/{functionalityId}/metadata
# operationId: Functionality.patchMetadata
export def "functionalities-metadata FunctionalitypatchMetadata" [
  functionalityId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/functionalities/($functionalityId)/metadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Run an action
#
# POST /functionalities/{functionalityId}/run/{action}
# operationId: Functionality.run
export def "functionalities-run Functionalityrun" [
  functionalityId: string
  action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<functionality: string, result: list<any>, status: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/functionalities/($functionalityId)/run/($action)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List tags
#
# GET /functionalities/{functionalityId}/tags
# operationId: Functionality.getTags
export def "functionalities-tags FunctionalitygetTags" [
  functionalityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/functionalities/($functionalityId)/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify tags
#
# PATCH /functionalities/{functionalityId}/tags
# operationId: Functionality.patchTags
export def "functionalities-tags FunctionalitypatchTags" [
  functionalityId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/functionalities/($functionalityId)/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Information about the User
#
# GET /me
# operationId: Me.get
export def "me Meget" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<email: string, id: string, locale: string, login: string, metadata: record, name: string, phoneNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update User information
#
# PATCH /me
# operationId: Me.patch
export def "me Mepatch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # Locale identifier (language, region). See https://tools.ietf.org/html/rfc5646 and https://www.iana.org/assignments/lang-subtags-templates/lang-subtags-templates.xhtml .  (e.g. fr-FR)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me")
  let body = {locale: $locale} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a Notification
#
# DELETE /notifications/{notificationId}
# operationId: Notification.delete
export def "notifications Notificationdelete" [
  notificationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notifications/($notificationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Information about a Notification
#
# GET /notifications/{notificationId}
# operationId: Notifications.get
export def "notifications Notificationsget" [
  notificationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record, metadata: record, name: string, place: string, routing: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notifications/($notificationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Notification
#
# PATCH /notifications/{notificationId}
# operationId: Notification.patch
export def "notifications Notificationpatch" [
  notificationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: record
  --name: string
  --routing: string # format: uri
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notifications/($notificationId)")
  let body = {data: $data, name: $name, routing: $routing} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List metadata
#
# GET /notifications/{notificationId}/metadata
# operationId: Notification.getMetadata
export def "notifications-metadata NotificationgetMetadata" [
  notificationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notifications/($notificationId)/metadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify metadata of a Notification
#
# PATCH /notifications/{notificationId}/metadata
# operationId: Notification.patchMetadata
export def "notifications-metadata NotificationpatchMetadata" [
  notificationId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/notifications/($notificationId)/metadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List accessible Places
#
# GET /places
# operationId: Me.places
export def "places Meplaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed-metadata: list # Request to include the given keys of metadata in the response. If a key doesn't exist on the resource it is ignored. **Note:** This only applies to the top level resources.
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "embed-metadata" $embed_metadata "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/places" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Information about a Place
#
# GET /places/{placeId}
# operationId: Places.get
export def "places Placesget" [
  placeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account: string, country: string, metadata: record, name: string, timeZone: string, zipCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($placeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Place
#
# PATCH /places/{placeId}
# operationId: Place.patch
export def "places Placepatch" [
  placeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --country: string # Country code (ISO 3166-1 alpha-2) (e.g. FR)
  --name: string # e.g. ⌂ Home
  --timeZone: string # A time zone name from the Time Zone Database at https://www.iana.org/time-zones (e.g. Europe/Paris)
  --zipCode: string # Postal code
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($placeId)")
  let body = {country: $country, name: $name, timeZone: $timeZone, zipCode: $zipCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Buses
#
# GET /places/{placeId}/buses
# operationId: Place.buses
export def "places-buses Placebuses" [
  placeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --withPairing: oneof<nothing, bool> # Filter out buses that have no pairing window (default: false)
]: nothing -> table<functionality: string, id: string, protocol: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "withPairing" $withPairing "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($placeId)/buses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# State of the pairing window
#
# GET /places/{placeId}/buses/{busId}/pairing
# operationId: Place.pairing
export def "places-buses-pairing Placepairing" [
  placeId: string
  busId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<duration: int, enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($placeId)/buses/($busId)/pairing")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Open/Close the pairing window
#
# PUT /places/{placeId}/buses/{busId}/pairing
# operationId: Place.openPairing
export def "places-buses-pairing PlaceopenPairing" [
  placeId: string
  busId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --duration: int # Duration of the pairing window.
  --enabled: oneof<nothing, bool>
]: any -> record<duration: int, enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($placeId)/buses/($busId)/pairing")
  let body = {duration: $duration, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List of Devices
#
# GET /places/{placeId}/devices
# operationId: Place.devices
export def "places-devices Placedevices" [
  placeId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --devices: string # Devices selector. Device tags or device classes or device ids or '*' for any. Multiple values are separated by '|' and interpreted as « OR ».
  --embed-metadata: list # Request to include the given keys of metadata in the response. If a key doesn't exist on the resource it is ignored. **Note:** This only applies to the top level resources.
]: nothing -> table<address: string, class: string, id: string, isOnline: bool, metadata: record, name: string, place: string, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "devices" $devices "scalar") (serialize-qp "embed-metadata" $embed_metadata "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($placeId)/devices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get autonomy rate of the place
#
# GET /places/{placeId}/electricity/autonomy
# operationId: Place.Electricity.autonomy
export def "places-electricity-autonomy PlaceElectricityautonomy" [
  placeId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --when: string # A time part of the time span. (format: date-time)
  --span: string@span-completer # Timespan: H (hour), D (day), Wmo (week starting on Monday), Wsu (week starting on Sunday), M (month), Y (year)
]: nothing -> record<autonomy: float, code: int, from: string, message: string, to: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "when" $when "scalar") (serialize-qp "span" $span "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($placeId)/electricity/autonomy" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get electricity virtual flows
#
# GET /places/{placeId}/electricity/flows
# operationId: Place.Electricity.getFlows
export def "places-electricity-flows PlaceElectricitygetFlows" [
  placeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --flows: list # Names of the flows requested
]: nothing -> record<code: int, flows: record<battery_charge: list<record>, battery_discharge: list<record>, battery_grid: list<record>, elec_drawn: list<record>, elec_feed_in: list<record>, elec_from_household: list<record>, elec_local: list<record>, elec_to_pv: list<record>, elec_total_gen: list<record>, elec_total_usage: list<record>, elec_usage: list<record>>, message: string, missing: record<battery_charge: bool, battery_discharge: bool, battery_grid: bool, elec_drawn: bool, elec_feed_in: bool, elec_from_household: bool, elec_local: bool, elec_to_pv: bool, elec_total_gen: bool, elec_total_usage: bool, elec_usage: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "flows" $flows "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($placeId)/electricity/flows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get electricity flows setup
#
# GET /places/{placeId}/electricity/flows/setup
# operationId: Place.Electricity.getFlowsSetup
export def "places-electricity-flows-setup PlaceElectricitygetFlowsSetup" [
  placeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<battery_charge: table<class: string, id: string>, battery_discharge: table<class: string, id: string>, battery_grid: table<class: string, id: string>, elec_drawn: table<class: string, id: string>, elec_feed_in: table<class: string, id: string>, elec_from_household: table<class: string, id: string>, elec_local: table<class: string, id: string>, elec_to_pv: table<class: string, id: string>, elec_total_gen: table<class: string, id: string>, elec_total_usage: table<class: string, id: string>, elec_usage: table<class: string, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($placeId)/electricity/flows/setup")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get self-consumption rate of the place
#
# GET /places/{placeId}/electricity/self-consumption
# operationId: Place.Electricity.selfConsumption
export def "places-electricity-self-consumption PlaceElectricityselfConsumption" [
  placeId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --when: string # A time part of the time span. (format: date-time)
  --span: string@span-completer # Timespan: H (hour), D (day), Wmo (week starting on Monday), Wsu (week starting on Sunday), M (month), Y (year)
]: nothing -> record<code: int, from: string, message: string, selfConsumption: float, to: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "when" $when "scalar") (serialize-qp "span" $span "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($placeId)/electricity/self-consumption" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Functionalities
#
# GET /places/{placeId}/functionalities
# operationId: Place.functionalities
export def "places-functionalities Placefunctionalities" [
  placeId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed-metadata: list # Request to include the given keys of metadata in the response. If a key doesn't exist on the resource it is ignored. **Note:** This only applies to the top level resources.
]: nothing -> table<class: string, device: string, endpoint: int, id: string, metadata: record, name: string, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "embed-metadata" $embed_metadata "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($placeId)/functionalities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List metadata
#
# GET /places/{placeId}/metadata
# operationId: Place.getMetadata
export def "places-metadata PlacegetMetadata" [
  placeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($placeId)/metadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify metadata
#
# PATCH /places/{placeId}/metadata
# operationId: Place.patchMetadata
export def "places-metadata PlacepatchMetadata" [
  placeId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($placeId)/metadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Notifications
#
# GET /places/{placeId}/notifications
# operationId: Place.notifications
export def "places-notifications Placenotifications" [
  placeId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed-metadata: list # Request to include the given keys of metadata in the response. If a key doesn't exist on the resource it is ignored. **Note:** This only applies to the top level resources.
]: nothing -> table<id: string, metadata: record, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "embed-metadata" $embed_metadata "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($placeId)/notifications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Notification
#
# POST /places/{placeId}/notifications
# operationId: Place.newNotification
export def "places-notifications PlacenewNotification" [
  placeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --data: record
  --metadata: record # Keys are limited to the same format as tags (up to 21 characters, [a-z0-9], starting with [a-z]). Values can be any JSON value.
  name: string
  --routing: string # format: uri
]: any -> record<code: int, message: string, resource: record<entity: string, href: string, id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($placeId)/notifications")
  let body = {data: $data, metadata: $metadata, name: $name, routing: $routing} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Programs
#
# GET /places/{placeId}/programs
# operationId: Place.programs
export def "places-programs Placeprograms" [
  placeId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --embed-metadata: list # Request to include the given keys of metadata in the response. If a key doesn't exist on the resource it is ignored. **Note:** This only applies to the top level resources.
]: nothing -> table<enabled: bool, id: string, metadata: record, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "embed-metadata" $embed_metadata "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($placeId)/programs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a Program
#
# POST /places/{placeId}/programs
# operationId: Place.newProgram
export def "places-programs PlacenewProgram" [
  placeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  code: any # null/boolean/integer/number/string/object/array
  --enabled: oneof<nothing, bool> # default: true
  --metadata: record # Keys are limited to the same format as tags (up to 21 characters, [a-z0-9], starting with [a-z]). Values can be any JSON value.
  name: string
]: any -> record<code: int, message: string, resource: record<entity: string, href: string, id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/places/($placeId)/programs")
  let body = {code: $code, enabled: $enabled, metadata: $metadata, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Run actions
#
# POST /places/{placeId}/run/{action}
# operationId: Place.run
export def "places-run Placerun" [
  placeId: string
  action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --devices: string # Devices selector. Device tags or device classes or device ids or '*' for any. Multiple values are separated by '|' and interpreted as « OR ».
  --functionalities: string # Functionality selector: Functionality tags or functionality class (optionally, '@' followed by a endpoint in decimal) or '*' for all. Multiple values are separated by '|' and are interpreted as « OR ».
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "devices" $devices "scalar") (serialize-qp "functionalities" $functionalities "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/places/($placeId)/run/($action)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a Program
#
# DELETE /programs/{programId}
# operationId: Program.delete
export def "programs Programdelete" [
  programId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/programs/($programId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Information about a Program
#
# GET /programs/{programId}
# operationId: Programs.get
export def "programs Programsget" [
  programId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<code: any, enabled: bool, metadata: record, name: string, place: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/programs/($programId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify a Program
#
# PATCH /programs/{programId}
# operationId: Program.patch
export def "programs Programpatch" [
  programId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --code: any # null/boolean/integer/number/string/object/array
  --enabled: oneof<nothing, bool>
  --name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/programs/($programId)")
  let body = {code: $code, enabled: $enabled, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# History of executions of a Program
#
# GET /programs/{programId}/log
# operationId: Program.log
export def "programs-log Programlog" [
  programId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-from: string # Beginning of the time interval. (format: date-time)
  --qp-to: string # End of the interval. Default: now.  (format: date-time)
]: nothing -> table<actions: list<record>, errors: list<string>, notifications: list<string>, when: string> {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/programs/($programId)/log" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List metadata
#
# GET /programs/{programId}/metadata
# operationId: Program.getMetadata
export def "programs-metadata ProgramgetMetadata" [
  programId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/programs/($programId)/metadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Modify metadata of a Program
#
# PATCH /programs/{programId}/metadata
# operationId: Program.patchMetadata
export def "programs-metadata ProgrampatchMetadata" [
  programId: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/programs/($programId)/metadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Run the Program
#
# POST /programs/{programId}/run
# operationId: Program.run
export def "programs-run Programrun" [
  programId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "query-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/programs/($programId)/run")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
