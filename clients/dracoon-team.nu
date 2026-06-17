# Auto-generated client for DRACOON API v4.42.2
# Source: https://api.apis.guru/v2/specs/dracoon.team/4.42.2/openapi.json
# Auth: --token flag or $env.DRACOON_API_TOKEN

const BASE_URL = "http://localhost/api"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DRACOON_API_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost/api"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def auth-type-completer [] { ["active_directory" "basic" "radius"] }
def x-sds-date-format-completer [] { ["EPOCH" "LEET" "LOCAL" "OFFSET" "UTC"] }
def status-completer [] { ["0" "2"] }
def resolution-strategy-completer [] { ["autorename" "fail" "overwrite"] }
def classification-completer [] { ["1" "2" "3" "4"] }
def use-key-completer [] { ["previous_room_rescue_key" "previous_system_rescue_key" "previous_user_key" "room_rescue_key" "system_rescue_key"] }
def new-group-member-acceptance-completer [] { ["autoallow" "pending"] }
def customer-contract-type-completer [] { ["demo" "free" "pay"] }
def flow-completer [] { ["authorization_code" "hybrid"] }
def user-info-source-completer [] { ["id_token" "user_info_endpoint"] }
def client-type-completer [] { ["confidential" "public"] }
def grant-types-completer [] { ["authorization_code" "client_credentials" "implicit" "password" "refresh_token"] }
def protocol-completer [] { ["TCP" "UDP"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "auth-login login" } } | get name | first)
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

# Authenticate user (Login)
#
# POST /v4/auth/login
# DEPRECATED
# Docs: https://tools.ietf.org/html/rfc2865 — Remote Authentication Dial In User Service (RADIUS)
# operationId: login
@deprecated
@deprecated --flag language
@deprecated --flag login
export def "auth-login login" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --auth-type: string@auth-type-completer # Authentication methods
  --language: string # &#128679; Deprecated since v4.7.0  Language ID or ISO 639-1 code (DEPRECATED)
  --login: string # &#128679; Deprecated since v4.7.0  User login name (DEPRECATED)
  password: string # Password
  --state: string # For RADIUS Access-Challenge  If a `replyState` is returned, it must be included as `state` in the following request.
  --body-token: string # RADIUS Token
  --user-name: string # &#128640; Since v4.13.0  Username
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/auth/login")
  let body = {"authType": $auth_type, "language": $language, "login": $login, "password": $password, "state": $state, "token": $body_token, "userName": $user_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Initiate OpenID Connect authentication
#
# GET /v4/auth/openid/login
# DEPRECATED
# Docs: http://openid.net/developers/specs — OpenID Specifications
# operationId: initiateOpenIdLogin
@deprecated
@deprecated --flag language
export def "auth-openid-login initiateOpenIdLogin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --issuer: string # Issuer identifier of the OpenID Connect identity provider
  --redirect-uri: string # Redirect URI to complete the OpenID Connect authentication
  --language: string # Language ID or ISO 639-1 code (DEPRECATED)
  --test: oneof<nothing, bool> # Flag to test the authentication parameters.  If the request is valid, the API will respond with `204 No Content`.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "issuer" $issuer "scalar") (serialize-qp "redirect_uri" $redirect_uri "scalar") (serialize-qp "language" $language "scalar") (serialize-qp "test" $test "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/auth/openid/login" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Complete OpenID Connect authentication
#
# POST /v4/auth/openid/login
# DEPRECATED
# Docs: http://openid.net/developers/specs — OpenID Specifications
# operationId: completeOpenIdLogin
@deprecated
export def "auth-openid-login completeOpenIdLogin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --code: string # Authorization code
  --id-token: string # Identity token
  --state: string # Authentication state
]: nothing -> record<token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "code" $code "scalar") (serialize-qp "id_token" $id_token "scalar") (serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/auth/openid/login" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Ping
#
# GET /v4/auth/ping
# operationId: ping
export def "auth-ping ping" [
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
  let full_url = (build-url $base "/v4/auth/ping")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Recover username
#
# POST /v4/auth/recover_username
# operationId: recoverUserName
export def "auth-recover-username recoverUserName" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --creator-language: string # IETF language tag
  email: string # Email 
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/auth/recover_username")
  let body = {"creatorLanguage": $creator_language, "email": $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request password reset
#
# POST /v4/auth/reset_password
# operationId: requestPasswordReset
@deprecated --flag language
@deprecated --flag login
export def "auth-reset-password request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --creator-language: string # IETF language tag
  --language: string # &#128679; Deprecated since v4.7.0  Language ID or ISO 639-1 code (DEPRECATED)
  --login: string # &#128679; Deprecated since v4.13.0  User login name (DEPRECATED)
  --user-name: string # &#128640; Since v4.13.0  Username
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/auth/reset_password")
  let body = {"creatorLanguage": $creator_language, "language": $language, "login": $login, "userName": $user_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Validate information for password reset
#
# GET /v4/auth/reset_password/{token}
# operationId: validateResetPasswordToken
export def "auth-reset-password validate" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<allowSystemGlobalWeakPassword: bool, firstName: string, gender: string, lastName: string, loginPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, numberOfArchivedPasswords: int, passwordExpiration: record<enabled: bool, maxPasswordAge: int>, rejectDictionaryWords: bool, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, userLockout: record<enabled: bool, lockoutPeriod: int, maxNumberOfLoginFailures: int>>, title: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({token_arg: $token_arg} | format pattern "/v4/auth/reset_password/{token_arg}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reset password
#
# PUT /v4/auth/reset_password/{token}
# operationId: resetPassword
export def "auth-reset-password reset" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  password: string # New password
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({token_arg: $token_arg} | format pattern "/v4/auth/reset_password/{token_arg}"))
  let body = {"password": $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request default values
#
# GET /v4/config/info/defaults
# Docs: https://tools.ietf.org/html/rfc5646 — Tags for Identifying Languages
# operationId: requestSystemDefaultsInfo
export def "config-info-defaults request-system" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<downloadShareDefaultExpirationPeriod: int, fileDefaultExpirationPeriod: int, hideLoginInputFields: bool, languageDefault: string, nonmemberViewerDefault: bool, uploadShareDefaultExpirationPeriod: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/config/info/defaults")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request general settings
#
# GET /v4/config/info/general
# operationId: requestGeneralSettingsInfo
export def "config-info-general request-general-settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<authTokenRestrictions: record<accessTokenValidity: int, refreshTokenValidity: int, restrictionEnabled: bool>, cryptoEnabled: bool, emailNotificationButtonEnabled: bool, eulaEnabled: bool, hideLoginInputFields: bool, homeRoomParentId: int, homeRoomsActive: bool, mediaServerEnabled: bool, s3TagsEnabled: bool, sharePasswordSmsEnabled: bool, subscriptionPlan: int, useS3Storage: bool, weakPasswordEnabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/config/info/general")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request infrastructure properties
#
# GET /v4/config/info/infrastructure
# operationId: requestInfrastructurePropertiesInfo
export def "config-info-infrastructure request-infrastructure-properties" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<isDracoonCloud: bool, mediaServerConfigEnabled: bool, s3DefaultRegion: string, s3EnforceDirectUpload: bool, smsConfigEnabled: bool, tenantUuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/config/info/infrastructure")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request list of notification channels
#
# GET /v4/config/info/notifications/channels
# operationId: requestNotificationChannelsInfo
export def "config-info-notifications-channels request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<frequency: int, id: int, isEnabled: bool, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/config/info/notifications/channels")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request algorithms
#
# GET /v4/config/info/policies/algorithms
# operationId: requestAlgorithms
export def "config-info-policies-algorithms request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<fileKeyAlgorithms: table<description: string, status: string, version: string>, keyPairAlgorithms: table<description: string, status: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/config/info/policies/algorithms")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request classification policies
#
# GET /v4/config/info/policies/classifications
# operationId: requestClassificationPoliciesConfigInfo
export def "config-info-policies-classifications request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<shareClassificationPolicies: record<classificationRequiresSharePassword: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/config/info/policies/classifications")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request guest users policies
#
# GET /v4/config/info/policies/guest_users
# operationId: requestGuestUsersPoliciesConfigInfo
export def "config-info-policies-guest-users request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<isInviteUsersEnabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/config/info/policies/guest_users")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request password policies
#
# GET /v4/config/info/policies/passwords
# operationId: requestPasswordPoliciesConfigInfo
export def "config-info-policies-passwords request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<encryptionPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>, loginPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, numberOfArchivedPasswords: int, passwordExpiration: record<enabled: bool, maxPasswordAge: int>, rejectDictionaryWords: bool, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, userLockout: record<enabled: bool, lockoutPeriod: int, maxNumberOfLoginFailures: int>>, sharesPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, rejectDictionaryWords: bool, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/config/info/policies/passwords")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request list of product packages
#
# GET /v4/config/info/product_packages
# operationId: requestProductPackages
export def "config-info-product-packages request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<packages: table<clients: list, features: list, productPackageId: int, productPackageName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/config/info/product_packages")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request list of currently enabled product packages
#
# GET /v4/config/info/product_packages/current
# operationId: requestCurrentProductPackages
export def "config-info-product-packages-current request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<packages: table<clients: list, features: list, productPackageId: int, productPackageName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/config/info/product_packages/current")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request list of configured S3 tags
#
# GET /v4/config/info/s3_tags
# operationId: requestS3TagsInfo
export def "config-info-s3-tags request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<id: int, isMandatory: bool, key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/config/info/s3_tags")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request system settings
#
# GET /v4/config/settings
# DEPRECATED
# operationId: requestSystemSettings
@deprecated
export def "config-settings request-system" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/config/settings")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update system settings
#
# PUT /v4/config/settings
# DEPRECATED
# operationId: updateSystemSettings
# --items item shape: {key: string, value: string}
@deprecated
export def "config-settings update-system" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  items: list # List of key-value pairs — item shape: {key: string, value: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/config/settings")
  let body = {"items": $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Download avatar
#
# GET /v4/downloads/avatar/{user_id}/{uuid}
# operationId: downloadAvatar
export def "downloads-avatar download" [
  user_id: int
  uuid: string
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
  let full_url = (build-url $base ({user_id: $user_id, uuid: $uuid} | format pattern "/v4/downloads/avatar/{user_id}/{uuid}"))
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download ZIP archive
#
# GET /v4/downloads/zip/{token}
# operationId: downloadZipArchiveViaToken
export def "downloads-zip download-zip-archive-via" [
  token_arg: string
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
  let full_url = (build-url $base ({token_arg: $token_arg} | format pattern "/v4/downloads/zip/{token_arg}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download file
#
# GET /v4/downloads/{token}
# Docs: https://tools.ietf.org/html/rfc7233 — Range Requests
# operationId: downloadFileViaToken
export def "downloads download-file-via" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --generic-mimetype: oneof<nothing, bool> # Always return `application/octet-stream` instead of specific mimetype
  --inline: oneof<nothing, bool> # Use Content-Disposition: `inline` instead of `attachment`
  --range: string # Range   e.g. `bytes=0-999`
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "generic_mimetype" $generic_mimetype "scalar") (serialize-qp "inline" $inline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({token_arg: $token_arg} | format pattern "/v4/downloads/{token_arg}") $qp)
  let extra_headers = {"Range": $range} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download file
#
# HEAD /v4/downloads/{token}
# Docs: https://tools.ietf.org/html/rfc7233 — Range Requests
# operationId: downloadFileViaToken_1
export def "downloads download-file-via-by-token" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --generic-mimetype: oneof<nothing, bool> # Always return `application/octet-stream` instead of specific mimetype
  --inline: oneof<nothing, bool> # Use Content-Disposition: `inline` instead of `attachment`
  --range: string # Range   e.g. `bytes=0-999`
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "generic_mimetype" $generic_mimetype "scalar") (serialize-qp "inline" $inline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({token_arg: $token_arg} | format pattern "/v4/downloads/{token_arg}") $qp)
  let extra_headers = {"Range": $range} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request nodes
#
# GET /v4/eventlog/audits/node_info
# operationId: requestAuditNodeInfo
export def "eventlog-audits-node-info request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --parent-id: int # Parent node ID.  Only rooms can be parents.  Parent ID `0` or empty is the root node. (format: int64)
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --qp-sort: string # Sort string
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<countChildren: int, nodeId: int, nodeIsEncrypted: bool, nodeName: string, nodeParentId: int, nodeParentPath: string>, range: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parent_id" $parent_id "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/eventlog/audits/node_info" $qp)
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request node assigned users with permissions
#
# GET /v4/eventlog/audits/nodes
# DEPRECATED
# operationId: requestAuditNodeUserData
@deprecated
export def "eventlog-audits-nodes request-audit-node-user-data" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --qp-sort: string # Sort string
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> table<auditUserPermissionList: list<record>, nodeCntChildren: int, nodeCreatedAt: string, nodeCreatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, nodeHasActivitiesLog: bool, nodeHasRecycleBin: bool, nodeId: int, nodeIsEncrypted: bool, nodeName: string, nodeParentId: int, nodeParentPath: string, nodeQuota: int, nodeRecycleBinRetentionPeriod: int, nodeSize: int, nodeUpdatedAt: string, nodeUpdatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/eventlog/audits/nodes" $qp)
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request system events
#
# GET /v4/eventlog/events
# operationId: requestLogEventsAsJson
export def "eventlog-events request-log-events-as-json" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string # Sort string
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --date-start: string # Filter events from given date   e.g. `2015-12-31T23:59:00`
  --date-end: string # Filter events until given date   e.g. `2015-12-31T23:59:00`
  --type: int # Operation ID   cf. `GET /eventlog/operations` (format: int32)
  --user-id: int # User ID (format: int64)
  --status: string@status-completer # Operation status:  * `0` - Success  * `2` - Error
  --user-client: string # User client
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<attribute1: string, attribute2: string, attribute3: string, authParentSource: string, authParentTarget: string, customerId: int, id: int, message: string, objectId1: int, objectId2: int, objectName1: string, objectName2: string, objectType1: int, objectType2: int, operationId: int, operationName: string, status: int, time: string, userClient: string, userId: int, userIp: string, userName: string>, range: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "date_start" $date_start "scalar") (serialize-qp "date_end" $date_end "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "user_client" $user_client "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/eventlog/events" $qp)
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request allowed Log Operations
#
# GET /v4/eventlog/operations
# operationId: requestLogOperations
export def "eventlog-operations request-log" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-deprecated: oneof<nothing, bool> # Show only deprecated operations
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<operationList: table<id: int, isDeprecated: bool, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "is_deprecated" $is_deprecated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/eventlog/operations" $qp)
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request list of user groups
#
# GET /v4/groups
# operationId: requestGroups
export def "groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --qp-sort: string # Sort string
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<cntUsers: int, createdAt: string, createdBy: record, expireAt: string, groupRoles: record, id: int, name: string, updatedAt: string, updatedBy: record>, range: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/groups" $qp)
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new user group
#
# POST /v4/groups
# operationId: createGroup
# --expiration shape: {enableExpiration: bool, expireAt?: string}
export def "groups create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --expiration: record # Expiration information — shape: {enableExpiration: bool, expireAt?: string}
  name: string # Group name
]: any -> record<cntUsers: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, expireAt: string, groupRoles: record<items: list<record>>, id: int, name: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/groups")
  let body = {"expiration": $expiration, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove user group
#
# DELETE /v4/groups/{group_id}
# operationId: removeGroup
export def "groups delete" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({group_id: $group_id} | format pattern "/v4/groups/{group_id}"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request user group
#
# GET /v4/groups/{group_id}
# operationId: requestGroup
export def "groups request" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<cntUsers: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, expireAt: string, groupRoles: record<items: list<record>>, id: int, name: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({group_id: $group_id} | format pattern "/v4/groups/{group_id}"))
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update user group's metadata
#
# PUT /v4/groups/{group_id}
# operationId: updateGroup
# --expiration shape: {enableExpiration: bool, expireAt?: string}
export def "groups update" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --expiration: record # Expiration information — shape: {enableExpiration: bool, expireAt?: string}
  --name: string # Group name
]: any -> record<cntUsers: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, expireAt: string, groupRoles: record<items: list<record>>, id: int, name: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({group_id: $group_id} | format pattern "/v4/groups/{group_id}"))
  let body = {"expiration": $expiration, "name": $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request rooms where the group is defined as last admin group
#
# GET /v4/groups/{group_id}/last_admin_rooms
# operationId: requestLastAdminRoomsGroups
export def "groups-last-admin-rooms request" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<id: int, name: string, parentId: int, parentPath: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({group_id: $group_id} | format pattern "/v4/groups/{group_id}/last_admin_rooms"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request list of roles assigned to the group
#
# GET /v4/groups/{group_id}/roles
# operationId: requestGroupRoles
export def "groups-roles request" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<description: string, id: int, items: list, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({group_id: $group_id} | format pattern "/v4/groups/{group_id}/roles"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request rooms granted to the group or / and rooms that can be granted
#
# GET /v4/groups/{group_id}/rooms
# DEPRECATED
# operationId: requestGroupRooms
@deprecated
export def "groups-rooms request" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<children: list, cntDownloadShares: int, cntUploadShares: int, createdAt: string, createdBy: record, hasRecycleBin: bool, id: int, isEncrypted: bool, isFavorite: bool, isGranted: bool, name: string, parentId: int, permissions: record, quota: int, recycleBinRetentionPeriod: int, size: int, type: string, updatedAt: string, updatedBy: record>, range: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: $group_id} | format pattern "/v4/groups/{group_id}/rooms") $qp)
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove group members
#
# DELETE /v4/groups/{group_id}/users
# operationId: removeGroupMembers
export def "groups-users delete-group-members" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  ids: list # List of user IDs
]: any -> record<cntUsers: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, expireAt: string, groupRoles: record<items: list<record>>, id: int, name: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({group_id: $group_id} | format pattern "/v4/groups/{group_id}/users"))
  let body = {"ids": $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request group member users or / and users who can become a member
#
# GET /v4/groups/{group_id}/users
# operationId: requestGroupMembers
export def "groups-users request-group-members" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<displayName: string, email: string, id: int, isMember: bool, login: string, userInfo: record>, range: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({group_id: $group_id} | format pattern "/v4/groups/{group_id}/users") $qp)
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add group members
#
# POST /v4/groups/{group_id}/users
# operationId: addGroupMembers
export def "groups-users create-group-members" [
  group_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  ids: list # List of user IDs
]: any -> record<cntUsers: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, expireAt: string, groupRoles: record<items: list<record>>, id: int, name: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({group_id: $group_id} | format pattern "/v4/groups/{group_id}/users"))
  let body = {"ids": $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request subscription plan
#
# GET /v4/internal/tenant/subscription_plan
# operationId: internalRequestSubscriptionPlan
export def "internal-tenant-subscription-plan internalRequestSubscriptionPlan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-service-token: string # Service Authentication token
]: nothing -> record<subscriptionPlanId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/internal/tenant/subscription_plan")
  let extra_headers = {"X-Sds-Service-Token": $x_sds_service_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set subscription plan
#
# PUT /v4/internal/tenant/subscription_plan
# operationId: internalSetSubscriptionPlan
export def "internal-tenant-subscription-plan internalSetSubscriptionPlan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-service-token: string # Service Authentication token
  subscription_plan_id: int # subscription plan id (format: int32)
]: any -> record<subscriptionPlanId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/internal/tenant/subscription_plan")
  let body = {"subscriptionPlanId": $subscription_plan_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Service-Token": $x_sds_service_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove nodes
#
# DELETE /v4/nodes
# operationId: removeNodes
export def "nodes delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  node_ids: list # List of node IDs
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/nodes")
  let body = {"nodeIds": $node_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request list of nodes
#
# GET /v4/nodes
# operationId: requestNodes
@deprecated --flag depth-level
export def "nodes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --depth-level: int # * `0` - top level nodes only  * `n` (any positive number) - include `n` levels starting from the current node (DEPRECATED, format: int32)
  --parent-id: int # Parent node ID.  Only rooms and folders can be parents.  Parent ID `0` or empty is the root node. (format: int64)
  --room-manager: oneof<nothing, bool> # Show all rooms for management perspective.  Only possible for _Rooms Managers_ / _Room Admins_.  For all other users, it will be ignored.
  --filter: string # Filter string
  --qp-sort: string # Sort string
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<authParentId: int, branchVersion: int, children: list, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record, encryptionInfo: record, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record>, range: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "depth_level" $depth_level "scalar") (serialize-qp "parent_id" $parent_id "scalar") (serialize-qp "room_manager" $room_manager "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/nodes" $qp)
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove node comment
#
# DELETE /v4/nodes/comments/{comment_id}
# operationId: removeNodeComment
export def "nodes-comments delete" [
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({comment_id: $comment_id} | format pattern "/v4/nodes/comments/{comment_id}"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Edit node comment
#
# PUT /v4/nodes/comments/{comment_id}
# operationId: updateNodeComment
export def "nodes-comments update" [
  comment_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  text: string # Comment text
]: any -> record<createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, id: int, isChanged: bool, isDeleted: bool, text: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({comment_id: $comment_id} | format pattern "/v4/nodes/comments/{comment_id}"))
  let body = {"text": $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove nodes from recycle bin
#
# DELETE /v4/nodes/deleted_nodes
# operationId: removeDeletedNodes
export def "nodes-deleted-nodes delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  deleted_node_ids: list # List of deleted node IDs
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/nodes/deleted_nodes")
  let body = {"deletedNodeIds": $deleted_node_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Restore deleted nodes
#
# POST /v4/nodes/deleted_nodes/actions/restore
# operationId: restoreNodes
export def "nodes-deleted-nodes-actions-restore restoreNodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  deleted_node_ids: list # List of deleted node IDs
  --keep-share-links: oneof<nothing, bool> # Preserve Download Share Links and point them to the new node. (default: false)
  --parent-id: int # Node parent ID  (default: previous parent ID) (format: int64)
  --resolution-strategy: string@resolution-strategy-completer # Node conflict resolution strategy:  * `autorename`  * `overwrite`  * `fail` (default: autorename)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/nodes/deleted_nodes/actions/restore")
  let body = {"deletedNodeIds": $deleted_node_ids, "keepShareLinks": $keep_share_links, "parentId": $parent_id, "resolutionStrategy": $resolution_strategy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request deleted node
#
# GET /v4/nodes/deleted_nodes/{deleted_node_id}
# operationId: requestDeletedNode
export def "nodes-deleted-nodes request" [
  deleted_node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<accessedAt: string, classification: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, deletedAt: string, deletedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, expireAt: string, id: int, isEncrypted: bool, name: string, notes: string, parentId: int, parentPath: string, referenceId: int, size: int, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({deleted_node_id: $deleted_node_id} | format pattern "/v4/nodes/deleted_nodes/{deleted_node_id}"))
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Mark or unmark a list of nodes (room, folder or file) as favorite
#
# PUT /v4/nodes/favorites
# operationId: updateFavorites
export def "nodes-favorites update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --is-favorite: oneof<nothing, bool> # Sets the favorite attribute to true or false on each file in an array of nodes.
  object_ids: list # List of ids
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/nodes/favorites")
  let body = {"isFavorite": $is_favorite, "objectIds": $object_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates a list of  file’s metadata
#
# PUT /v4/nodes/files
# operationId: updateFiles
# --expiration shape: {enableExpiration: bool, expireAt?: string}
export def "nodes-files update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --classification: int # Classification ID:  * `1` - public  * `2` - internal  * `3` - confidential  * `4` - strictly confidential (format: int32)
  --expiration: record # Expiration information — shape: {enableExpiration: bool, expireAt?: string}
  object_ids: list # List of ids
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/nodes/files")
  let body = {"classification": $classification, "expiration": $expiration, "objectIds": $object_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Set file keys for a list of users and files
#
# POST /v4/nodes/files/keys
# operationId: setUserFileKeys
# --items item shape: {fileId: int, fileKey: record, userId: int}
export def "nodes-files-keys setUserFileKeys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  items: list # List of user file keys — item shape: {fileId: int, fileKey: record, userId: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/nodes/files/keys")
  let body = {"items": $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create new file upload channel
#
# POST /v4/nodes/files/uploads
# operationId: createFileUploadChannel
# --expiration shape: {enableExpiration: bool, expireAt?: string}
export def "nodes-files-uploads create-file-upload-channel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --classification: int@classification-completer # Classification ID:  * `1` - public  * `2` - internal  * `3` - confidential  * `4` - strictly confidential    (default: classification from parent room) (format: int32)
  --direct-s3-upload: oneof<nothing, bool> # &#128640; Since v4.15.0  Upload direct to S3 (default: false)
  --expiration: record # Expiration information — shape: {enableExpiration: bool, expireAt?: string}
  name: string # File name
  --notes: string # User notes  Use empty string to remove.
  parent_id: int # Parent node ID (room or folder) (format: int64)
  --size: int # File size in byte (format: int64)
  --timestamp-creation: string # &#128640; Since v4.22.0  Time the node was created on external file system  (default: current server datetime in UTC format) (format: date-time)
  --timestamp-modification: string # &#128640; Since v4.22.0  Time the content of a node was last modified on external file system  (default: current server datetime in UTC format) (format: date-time)
]: any -> record<token: string, uploadId: string, uploadUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/nodes/files/uploads")
  let body = {"classification": $classification, "directS3Upload": $direct_s3_upload, "expiration": $expiration, "name": $name, "notes": $notes, "parentId": $parent_id, "size": $size, "timestampCreation": $timestamp_creation, "timestampModification": $timestamp_modification} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancel file upload
#
# DELETE /v4/nodes/files/uploads/{upload_id}
# operationId: cancelFileUpload
export def "nodes-files-uploads cancel" [
  upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({upload_id: $upload_id} | format pattern "/v4/nodes/files/uploads/{upload_id}"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request status of S3 file upload
#
# GET /v4/nodes/files/uploads/{upload_id}
# operationId: requestUploadStatusFiles
export def "nodes-files-uploads request-upload-status" [
  upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<errorDetails: record<code: int, debugInfo: string, errorCode: int, message: string>, node: record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({upload_id: $upload_id} | format pattern "/v4/nodes/files/uploads/{upload_id}"))
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload file
#
# POST /v4/nodes/files/uploads/{upload_id}
# DEPRECATED
# Docs: https://tools.ietf.org/html/rfc7233 — Range Requests
# operationId: uploadFileAsMultipart
@deprecated
export def "nodes-files-uploads upload-file-as-multipart" [
  upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-range: string # Content-Range   e.g. `bytes 0-999/3980`
  --x-sds-auth-token: string # Authentication token
  file: string # File (format: binary)
]: any -> record<hash: string, size: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({upload_id: $upload_id} | format pattern "/v4/nodes/files/uploads/{upload_id}"))
  let body = {"file": $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Range": $content_range, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Complete file upload
#
# PUT /v4/nodes/files/uploads/{upload_id}
# DEPRECATED
# operationId: completeFileUpload
# --fileKey shape: {iv: string, key: string, tag: string, version: string}
# --userFileKeyList shape: {items?: list}
@deprecated
@deprecated --flag user-file-key-list
export def "nodes-files-uploads completeFileUpload" [
  upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --file-key: record # File key information — shape: {iv: string, key: string, tag: string, version: string}
  --file-name: string # New file name to store with
  --keep-share-links: oneof<nothing, bool> # Preserve Download Share Links and point them to the new node. (default: false)
  --resolution-strategy: string@resolution-strategy-completer # Node conflict resolution strategy:  * `autorename`  * `overwrite`  * `fail` (default: autorename)
  --user-file-key-list: record # Mandatory for encrypted shares (DEPRECATED) — shape: {items?: list}
]: any -> record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({upload_id: $upload_id} | format pattern "/v4/nodes/files/uploads/{upload_id}"))
  let body = {"fileKey": $file_key, "fileName": $file_name, "keepShareLinks": $keep_share_links, "resolutionStrategy": $resolution_strategy, "userFileKeyList": $user_file_key_list} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Complete S3 file upload
#
# PUT /v4/nodes/files/uploads/{upload_id}/s3
# operationId: completeS3FileUpload
# --fileKey shape: {iv: string, key: string, tag: string, version: string}
# --parts item shape: {partEtag: string, partNumber: int}
export def "nodes-files-uploads-s3 completeS3FileUpload" [
  upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --file-key: record # File key information — shape: {iv: string, key: string, tag: string, version: string}
  --file-name: string # New file name to store with
  --keep-share-links: oneof<nothing, bool> # Preserve Download Share Links and point them to the new node. (default: false)
  parts: list # List of S3 file upload parts — item shape: {partEtag: string, partNumber: int}
  --resolution-strategy: string@resolution-strategy-completer # Node conflict resolution strategy:  * `autorename`  * `overwrite`  * `fail` (default: autorename)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({upload_id: $upload_id} | format pattern "/v4/nodes/files/uploads/{upload_id}/s3"))
  let body = {"fileKey": $file_key, "fileName": $file_name, "keepShareLinks": $keep_share_links, "parts": $parts, "resolutionStrategy": $resolution_strategy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generate presigned URLs for S3 file upload
#
# POST /v4/nodes/files/uploads/{upload_id}/s3_urls
# operationId: generatePresignedUrlsFiles
export def "nodes-files-uploads-s3-urls generatePresignedUrlsFiles" [
  upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  first_part_number: int # First part number of a range of requested presigned URLs (for S3 it is: `1`) (format: int32)
  last_part_number: int # Last part number of a range of requested presigned URLs (format: int32)
  size: int # `Content-Length` header size for each presigned URL (in bytes)  *MUST* be >= 5 MB except the last part. (format: int64)
]: any -> record<urls: table<partNumber: int, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({upload_id: $upload_id} | format pattern "/v4/nodes/files/uploads/{upload_id}/s3_urls"))
  let body = {"firstPartNumber": $first_part_number, "lastPartNumber": $last_part_number, "size": $size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request list of file versions
#
# GET /v4/nodes/files/versions/{reference_id}
# operationId: requestFileVersionList
export def "nodes-files-versions request-file-version-list" [
  reference_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<deleted: bool, id: int, name: string, parentId: int, referenceId: int>, range: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({reference_id: $reference_id} | format pattern "/v4/nodes/files/versions/{reference_id}") $qp)
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a file’s metadata
#
# PUT /v4/nodes/files/{file_id}
# operationId: updateFile
# --expiration shape: {enableExpiration: bool, expireAt?: string}
export def "nodes-files update-by-file_id" [
  file_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --classification: int # Classification ID:  * `1` - public  * `2` - internal  * `3` - confidential  * `4` - strictly confidential (format: int32)
  --expiration: record # Expiration information — shape: {enableExpiration: bool, expireAt?: string}
  --name: string # File name
  --notes: string # User notes  Use empty string to remove.
  --timestamp-creation: string # &#128640; Since v4.22.0  Time the node was created on external file system  (default: current server datetime in UTC format) (format: date-time)
  --timestamp-modification: string # &#128640; Since v4.22.0  Time the content of a node was last modified on external file system  (default: current server datetime in UTC format) (format: date-time)
]: any -> record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/v4/nodes/files/{file_id}"))
  let body = {"classification": $classification, "expiration": $expiration, "name": $name, "notes": $notes, "timestampCreation": $timestamp_creation, "timestampModification": $timestamp_modification} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request room rescue key
#
# GET /v4/nodes/files/{file_id}/data_room_file_key
# DEPRECATED
# operationId: requestRoomRescueKey
@deprecated
export def "nodes-files-data-room-file-key request-room-rescue" [
  file_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # Version (NEW)
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<iv: string, key: string, tag: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/v4/nodes/files/{file_id}/data_room_file_key") $qp)
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request system rescue key
#
# GET /v4/nodes/files/{file_id}/data_space_file_key
# DEPRECATED
# operationId: requestSystemRescueKey
@deprecated
export def "nodes-files-data-space-file-key request-system-rescue" [
  file_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # Version (NEW)
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<iv: string, key: string, tag: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/v4/nodes/files/{file_id}/data_space_file_key") $qp)
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate download URL
#
# POST /v4/nodes/files/{file_id}/downloads
# operationId: generateDownloadUrl
export def "nodes-files-downloads generateDownloadUrl" [
  file_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<downloadUrl: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/v4/nodes/files/{file_id}/downloads"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request user's file key
#
# GET /v4/nodes/files/{file_id}/user_file_key
# operationId: requestUserFileKey
export def "nodes-files-user-file-key request" [
  file_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # Version (NEW)
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<iv: string, key: string, tag: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({file_id: $file_id} | format pattern "/v4/nodes/files/{file_id}/user_file_key") $qp)
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new folder
#
# POST /v4/nodes/folders
# operationId: createFolder
export def "nodes-folders create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --classification: int@classification-completer # &#128640; Since v4.30.0  Classification ID:  * `1` - public  * `2` - internal  * `3` - confidential  * `4` - strictly confidential    Provided (or default) classification is taken from room  when file gets uploaded without any classification. (format: int32)
  name: string # Name
  --notes: string # User notes  Use empty string to remove.
  parent_id: int # Parent node ID (room or folder) (format: int64)
  --timestamp-creation: string # &#128640; Since v4.22.0  Time the node was created on external file system  (default: current server datetime in UTC format) (format: date-time)
  --timestamp-modification: string # &#128640; Since v4.22.0  Time the content of a node was last modified on external file system  (default: current server datetime in UTC format) (format: date-time)
]: any -> record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/nodes/folders")
  let body = {"classification": $classification, "name": $name, "notes": $notes, "parentId": $parent_id, "timestampCreation": $timestamp_creation, "timestampModification": $timestamp_modification} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates folder’s metadata
#
# PUT /v4/nodes/folders/{folder_id}
# operationId: updateFolder
export def "nodes-folders update" [
  folder_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --classification: int@classification-completer # &#128640; Since v4.30.0  Classification ID:  * `1` - public  * `2` - internal  * `3` - confidential  * `4` - strictly confidential    Provided (or default) classification is taken from room  when file gets uploaded without any classification. (format: int32)
  --name: string # Folder name
  --notes: string # User notes  Use empty string to remove.
  --timestamp-creation: string # &#128640; Since v4.22.0  Time the node was created on external file system  (default: current server datetime in UTC format) (format: date-time)
  --timestamp-modification: string # &#128640; Since v4.22.0  Time the content of a node was last modified on external file system  (default: current server datetime in UTC format) (format: date-time)
]: any -> record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({folder_id: $folder_id} | format pattern "/v4/nodes/folders/{folder_id}"))
  let body = {"classification": $classification, "name": $name, "notes": $notes, "timestampCreation": $timestamp_creation, "timestampModification": $timestamp_modification} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request files without user's file key
#
# GET /v4/nodes/missingFileKeys
# operationId: requestMissingFileKeys
export def "nodes-missing-file-keys request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --room-id: int # Room ID (format: int64)
  --file-id: int # File ID (format: int64)
  --user-id: int # User ID (format: int64)
  --use-key: string@use-key-completer # Determines which key should be used (NEW)
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<files: table<fileKeyContainer: record, id: int>, items: table<fileId: int, userId: int>, range: record<limit: int, offset: int, total: int>, users: table<id: int, publicKeyContainer: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "room_id" $room_id "scalar") (serialize-qp "file_id" $file_id "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "use_key" $use_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/nodes/missingFileKeys" $qp)
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new room
#
# POST /v4/nodes/rooms
# operationId: createRoom
@deprecated --flag has-recycle-bin
export def "nodes-rooms create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --admin-group-ids: list # List of group ids  A room requires at least one admin (user or group)
  --admin-ids: list # List of user ids  A room requires at least one admin (user or group)
  --classification: int@classification-completer # Classification ID:  * `1` - public  * `2` - internal  * `3` - confidential  * `4` - strictly confidential    Provided (or default) classification is taken from room  when file gets uploaded without any classification. (format: int32, default: 2)
  --has-activities-log: oneof<nothing, bool> # Is activities log active (for rooms only) (default: true)
  --has-recycle-bin: oneof<nothing, bool> # &#128679; Deprecated since v4.10.0  Is recycle bin active (for rooms only)  Recycle bin is always on (disabling is not possible). (DEPRECATED)
  --inherit-permissions: oneof<nothing, bool> # Inherit permissions from parent room  (default: `false` if `parentId` is `0`; otherwise: `true`)
  name: string # Name
  --new-group-member-acceptance: string@new-group-member-acceptance-completer # Behaviour when new users are added to the group:  * `autoallow`  * `pending`    Only relevant if `adminGroupIds` has items. (default: autoallow)
  --notes: string # User notes  Use empty string to remove.
  --parent-id: int # Parent room ID or `null` (not 0) to create a top level room (format: int64)
  --quota: int # Quota in byte (format: int64)
  --recycle-bin-retention-period: int # Retention period for deleted nodes in days (format: int32)
  --timestamp-creation: string # &#128640; Since v4.22.0  Time the node was created on external file system  (default: current server datetime in UTC format) (format: date-time)
  --timestamp-modification: string # &#128640; Since v4.22.0  Time the content of a node was last modified on external file system  (default: current server datetime in UTC format) (format: date-time)
]: any -> record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/nodes/rooms")
  let body = {"adminGroupIds": $admin_group_ids, "adminIds": $admin_ids, "classification": $classification, "hasActivitiesLog": $has_activities_log, "hasRecycleBin": $has_recycle_bin, "inheritPermissions": $inherit_permissions, "name": $name, "newGroupMemberAcceptance": $new_group_member_acceptance, "notes": $notes, "parentId": $parent_id, "quota": $quota, "recycleBinRetentionPeriod": $recycle_bin_retention_period, "timestampCreation": $timestamp_creation, "timestampModification": $timestamp_modification} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request user-room assignments per group
#
# GET /v4/nodes/rooms/pending
# operationId: requestPendingAssignments
export def "nodes-rooms-pending request-pending-assignments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --qp-sort: string # Sort string
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<groupInfo: record, pendingGroupData: record, pendingUserData: record, roomId: int, roomName: string, state: string, userInfo: record>, range: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/nodes/rooms/pending" $qp)
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Handle user-room assignments per group
#
# PUT /v4/nodes/rooms/pending
# operationId: changePendingAssignments
# --items item shape: {groupId: int, roomId: int, roomName: string, state: "ACCEPTED"|"DENIED"|"WAITING", userId: int}
export def "nodes-rooms-pending changePendingAssignments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  items: list # List of pending assignments — item shape: {groupId: int, roomId: int, roomName: string, state: "ACCEPTED"|"DENIED"|"WAITING", userId: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/nodes/rooms/pending")
  let body = {"items": $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates room’s metadata
#
# PUT /v4/nodes/rooms/{room_id}
# operationId: updateRoom
export def "nodes-rooms update" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --name: string # Name
  --notes: string # User notes  Use empty string to remove.
  --quota: int # Quota in byte (format: int64)
  --timestamp-creation: string # &#128640; Since v4.22.0  Time the node was created on external file system (format: date-time)
  --timestamp-modification: string # &#128640; Since v4.22.0  Time the content of a node was last modified on external file system (format: date-time)
]: any -> record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({room_id: $room_id} | format pattern "/v4/nodes/rooms/{room_id}"))
  let body = {"name": $name, "notes": $notes, "quota": $quota, "timestampCreation": $timestamp_creation, "timestampModification": $timestamp_modification} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Configure room
#
# PUT /v4/nodes/rooms/{room_id}/config
# operationId: configureRoom
export def "nodes-rooms-config configureRoom" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --admin-group-ids: list # List of group ids  A room requires at least one admin (user or group)
  --admin-ids: list # List of user ids  A room requires at least one admin (user or group)
  --classification: int@classification-completer # Classification ID:  * `1` - public  * `2` - internal  * `3` - confidential  * `4` - strictly confidential    Provided (or default) classification is taken from room  when file gets uploaded without any classification. (format: int32, default: 2)
  --has-activities-log: oneof<nothing, bool> # Is activities log active (for rooms only) (default: true)
  --inherit-permissions: oneof<nothing, bool> # Inherit permissions from parent room  (default: `false` if `parentId` is `0`; otherwise: `true`)
  --new-group-member-acceptance: string@new-group-member-acceptance-completer # Behaviour when new users are added to the group:  * `autoallow`  * `pending`    Only relevant if `adminGroupIds` has items. (default: autoallow)
  --recycle-bin-retention-period: int # Retention period for deleted nodes in days (format: int32)
  --take-over-permissions: oneof<nothing, bool> # Take over existing permissions
]: any -> record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({room_id: $room_id} | format pattern "/v4/nodes/rooms/{room_id}/config"))
  let body = {"adminGroupIds": $admin_group_ids, "adminIds": $admin_ids, "classification": $classification, "hasActivitiesLog": $has_activities_log, "inheritPermissions": $inherit_permissions, "newGroupMemberAcceptance": $new_group_member_acceptance, "recycleBinRetentionPeriod": $recycle_bin_retention_period, "takeOverPermissions": $take_over_permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Encrypt room
#
# PUT /v4/nodes/rooms/{room_id}/encrypt
# operationId: encryptRoom
# --dataRoomRescueKey shape: {privateKeyContainer: record, publicKeyContainer: record}
export def "nodes-rooms-encrypt encryptRoom" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --data-room-rescue-key: record # Key pair container — shape: {privateKeyContainer: record, publicKeyContainer: record}
  --is-encrypted: oneof<nothing, bool> # Encryption state
  --use-data-space-rescue-key: oneof<nothing, bool> # Use system emergency password (rescue key) for files in this room
]: any -> record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({room_id: $room_id} | format pattern "/v4/nodes/rooms/{room_id}/encrypt"))
  let body = {"dataRoomRescueKey": $data_room_rescue_key, "isEncrypted": $is_encrypted, "useDataSpaceRescueKey": $use_data_space_rescue_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request events of a room
#
# GET /v4/nodes/rooms/{room_id}/events
# operationId: requestRoomActivitiesLogAsJson
export def "nodes-rooms-events request-room-activities-log-as-json" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string # Sort string
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --date-start: string # Filter events from given date   e.g. `2015-12-31T23:59:00`
  --date-end: string # Filter events until given date   e.g. `2015-12-31T23:59:00`
  --type: int # Operation ID   cf. `GET /eventlog/operations` (format: int32)
  --user-id: int # User ID (format: int64)
  --status: int # Operation status:  * `0` - Success  * `2` - Error (format: int32)
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<attribute1: string, attribute2: string, attribute3: string, authParentSource: string, authParentTarget: string, customerId: int, id: int, message: string, objectId1: int, objectId2: int, objectName1: string, objectName2: string, objectType1: int, objectType2: int, operationId: int, operationName: string, status: int, time: string, userClient: string, userId: int, userIp: string, userName: string>, range: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "date_start" $date_start "scalar") (serialize-qp "date_end" $date_end "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({room_id: $room_id} | format pattern "/v4/nodes/rooms/{room_id}/events") $qp)
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revoke granted group(s) from room
#
# DELETE /v4/nodes/rooms/{room_id}/groups
# operationId: revokeRoomGroups
export def "nodes-rooms-groups delete" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  ids: list # List of group IDs
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({room_id: $room_id} | format pattern "/v4/nodes/rooms/{room_id}/groups"))
  let body = {"ids": $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request room granted group(s) or / and group(s) that can be granted
#
# GET /v4/nodes/rooms/{room_id}/groups
# operationId: requestRoomGroups
export def "nodes-rooms-groups request" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --qp-sort: string # Sort string
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<id: int, isGranted: bool, name: string, newGroupMemberAcceptance: string, permissions: record>, range: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({room_id: $room_id} | format pattern "/v4/nodes/rooms/{room_id}/groups") $qp)
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add or change room granted group(s)
#
# PUT /v4/nodes/rooms/{room_id}/groups
# operationId: updateRoomGroups
# --items item shape: {id: int, newGroupMemberAcceptance?: "autoallow"|"pending", permissions: record}
export def "nodes-rooms-groups update" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  items: list # List of room-group mappings — item shape: {id: int, newGroupMemberAcceptance?: "autoallow"|"pending", permissions: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({room_id: $room_id} | format pattern "/v4/nodes/rooms/{room_id}/groups"))
  let body = {"items": $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add guest users to a room
#
# PUT /v4/nodes/rooms/{room_id}/guest_users
# operationId: addRoomGuestUsers
# --roomGuestInvitations item shape: {email: string, firstName: string, lastName: string}
export def "nodes-rooms-guest-users create" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  room_guest_invitations: list # List of room-user mappings — item shape: {email: string, firstName: string, lastName: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({room_id: $room_id} | format pattern "/v4/nodes/rooms/{room_id}/guest_users"))
  let body = {"roomGuestInvitations": $room_guest_invitations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove rooms's rescue key pair
#
# DELETE /v4/nodes/rooms/{room_id}/keypair
# operationId: removeRoomRescueKeyPair
export def "nodes-rooms-keypair delete-room-rescue" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # Version (NEW)
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({room_id: $room_id} | format pattern "/v4/nodes/rooms/{room_id}/keypair") $qp)
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request room rescue key
#
# GET /v4/nodes/rooms/{room_id}/keypair
# operationId: requestRoomRescueKeyPair
export def "nodes-rooms-keypair request-room-rescue" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # Version (NEW)
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<privateKeyContainer: record<createdAt: string, createdBy: int, privateKey: string, version: string>, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({room_id: $room_id} | format pattern "/v4/nodes/rooms/{room_id}/keypair") $qp)
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set room's rescue key pair
#
# POST /v4/nodes/rooms/{room_id}/keypair
# operationId: setRoomRescueKeyPair
# --privateKeyContainer shape: {createdAt?: string, createdBy?: int, privateKey: string, version: string}
# --publicKeyContainer shape: {createdAt?: string, createdBy?: int, publicKey: string, version: string}
export def "nodes-rooms-keypair setRoomRescueKeyPair" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  private_key_container: record # Private key container — shape: {createdAt?: string, createdBy?: int, privateKey: string, version: string}
  public_key_container: record # Public key container — shape: {createdAt?: string, createdBy?: int, publicKey: string, version: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({room_id: $room_id} | format pattern "/v4/nodes/rooms/{room_id}/keypair"))
  let body = {"privateKeyContainer": $private_key_container, "publicKeyContainer": $public_key_container} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request all room rescue key pairs
#
# GET /v4/nodes/rooms/{room_id}/keypairs
# operationId: requestRoomRescueKeyPairs
export def "nodes-rooms-keypairs request-room-rescue" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> table<privateKeyContainer: record<createdAt: string, createdBy: int, privateKey: string, version: string>, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({room_id: $room_id} | format pattern "/v4/nodes/rooms/{room_id}/keypairs"))
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create key pair and preserve copy of old private key
#
# POST /v4/nodes/rooms/{room_id}/keypairs
# operationId: createAndPreserveRoomRescueKeyPair
# --previousPrivateKey shape: {createdAt?: string, createdBy?: int, privateKey: string, version: string}
# --privateKeyContainer shape: {createdAt?: string, createdBy?: int, privateKey: string, version: string}
# --publicKeyContainer shape: {createdAt?: string, createdBy?: int, publicKey: string, version: string}
export def "nodes-rooms-keypairs create-and-preserve-room-rescue" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  previous_private_key: record # Private key container — shape: {createdAt?: string, createdBy?: int, privateKey: string, version: string}
  private_key_container: record # Private key container — shape: {createdAt?: string, createdBy?: int, privateKey: string, version: string}
  public_key_container: record # Public key container — shape: {createdAt?: string, createdBy?: int, publicKey: string, version: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({room_id: $room_id} | format pattern "/v4/nodes/rooms/{room_id}/keypairs"))
  let body = {"previousPrivateKey": $previous_private_key, "privateKeyContainer": $private_key_container, "publicKeyContainer": $public_key_container} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request Room Policies
#
# GET /v4/nodes/rooms/{room_id}/policies
# operationId: requestRoomPolicies
export def "nodes-rooms-policies request" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<defaultExpirationPeriod: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({room_id: $room_id} | format pattern "/v4/nodes/rooms/{room_id}/policies"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set room policies
#
# PUT /v4/nodes/rooms/{room_id}/policies
# operationId: setRoomPolicies
export def "nodes-rooms-policies setRoomPolicies" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --default-expiration-period: int # Default policy room expiration period in seconds.  All files in a room will have their expiration date set to this period after their respective upload.   0 means no default expiration policy is set. (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({room_id: $room_id} | format pattern "/v4/nodes/rooms/{room_id}/policies"))
  let body = {"defaultExpirationPeriod": $default_expiration_period} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request list of all assigned S3 tags to the room
#
# GET /v4/nodes/rooms/{room_id}/s3_tags
# operationId: requestRoomS3Tags
export def "nodes-rooms-s3-tags request" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<id: int, isMandatory: bool, key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({room_id: $room_id} | format pattern "/v4/nodes/rooms/{room_id}/s3_tags"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set S3 tags for a room
#
# POST /v4/nodes/rooms/{room_id}/s3_tags
# operationId: setRoomS3Tags
export def "nodes-rooms-s3-tags setRoomS3Tags" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  ids: list # List of S3 tag IDs
]: any -> record<items: table<id: int, isMandatory: bool, key: string, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({room_id: $room_id} | format pattern "/v4/nodes/rooms/{room_id}/s3_tags"))
  let body = {"ids": $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revoke granted user(s) from room
#
# DELETE /v4/nodes/rooms/{room_id}/users
# operationId: revokeRoomUsers
export def "nodes-rooms-users delete" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  ids: list # List of user IDs
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({room_id: $room_id} | format pattern "/v4/nodes/rooms/{room_id}/users"))
  let body = {"ids": $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request room granted user(s) or / and user(s) that can be granted
#
# GET /v4/nodes/rooms/{room_id}/users
# operationId: requestRoomUsers
export def "nodes-rooms-users request" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --qp-sort: string # Sort string
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<displayName: string, email: string, id: int, isGranted: bool, login: string, permissions: record, publicKeyContainer: record, userInfo: record>, range: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({room_id: $room_id} | format pattern "/v4/nodes/rooms/{room_id}/users") $qp)
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add or change room granted user(s)
#
# PUT /v4/nodes/rooms/{room_id}/users
# operationId: updateRoomUsers
# --items item shape: {id: int, permissions: record}
export def "nodes-rooms-users update" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  items: list # List of room-user mappings — item shape: {id: int, permissions: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({room_id: $room_id} | format pattern "/v4/nodes/rooms/{room_id}/users"))
  let body = {"items": $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request list of webhooks that are assigned or can be assigned to this room
#
# GET /v4/nodes/rooms/{room_id}/webhooks
# operationId: requestListOfWebhooksForRoom
export def "nodes-rooms-webhooks request-list-of-webhooks-for" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<isAssigned: bool, webhook: record>, range: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({room_id: $room_id} | format pattern "/v4/nodes/rooms/{room_id}/webhooks") $qp)
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assign or unassign webhooks to room
#
# PUT /v4/nodes/rooms/{room_id}/webhooks
# operationId: handleRoomWebhookAssignments
# --items item shape: {isAssigned: bool, webhookId: int}
export def "nodes-rooms-webhooks handleRoomWebhookAssignments" [
  room_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  items: list # Assign a webhook to a room to use it for node actions within the room  — item shape: {isAssigned: bool, webhookId: int}
]: any -> record<items: table<isAssigned: bool, webhook: record>, range: record<limit: int, offset: int, total: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({room_id: $room_id} | format pattern "/v4/nodes/rooms/{room_id}/webhooks"))
  let body = {"items": $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search nodes
#
# GET /v4/nodes/search
# operationId: searchNodes
export def "nodes-search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --search-string: string # Search string
  --depth-level: int # * `0` - top level nodes only (default)  * `-1` - full tree  * `n` (any positive number) - include `n` levels starting from the current node (format: int32)
  --parent-id: int # Parent node ID.  Only rooms and folders can be parents.  Parent ID `0` or empty is the root node. (format: int64)
  --filter: string # Filter string
  --qp-sort: string # Sort string
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<authParentId: int, branchVersion: int, children: list, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record, encryptionInfo: record, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record>, range: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search_string" $search_string "scalar") (serialize-qp "depth_level" $depth_level "scalar") (serialize-qp "parent_id" $parent_id "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/nodes/search" $qp)
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate download URL for ZIP download
#
# POST /v4/nodes/zip
# operationId: generateDownloadUrlForZipArchive
export def "nodes-zip generateDownloadUrlForZipArchive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  node_ids: list # List of node IDs
]: any -> record<downloadUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/nodes/zip")
  let body = {"nodeIds": $node_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Download files / folders as ZIP archive
#
# POST /v4/nodes/zip/download
# operationId: downloadZipArchive
export def "nodes-zip-download download-zip-archive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  node_ids: list # List of node IDs
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/nodes/zip/download")
  let body = {"nodeIds": $node_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove node
#
# DELETE /v4/nodes/{node_id}
# operationId: removeNode
export def "nodes delete-by-node_id" [
  node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({node_id: $node_id} | format pattern "/v4/nodes/{node_id}"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request node
#
# GET /v4/nodes/{node_id}
# operationId: requestNode
export def "nodes request" [
  node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({node_id: $node_id} | format pattern "/v4/nodes/{node_id}"))
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request list of node comments
#
# GET /v4/nodes/{node_id}/comments
# operationId: requestNodeComments
export def "nodes-comments request" [
  node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --hide-deleted: oneof<nothing, bool> # Hide deleted comments (default: false)
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<createdAt: string, createdBy: record, id: int, isChanged: bool, isDeleted: bool, text: string, updatedAt: string, updatedBy: record>, range: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "hide_deleted" $hide_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_id: $node_id} | format pattern "/v4/nodes/{node_id}/comments") $qp)
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create node comment
#
# POST /v4/nodes/{node_id}/comments
# operationId: createNodeComment
export def "nodes-comments create" [
  node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  text: string # Comment text
]: any -> record<createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, id: int, isChanged: bool, isDeleted: bool, text: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({node_id: $node_id} | format pattern "/v4/nodes/{node_id}/comments"))
  let body = {"text": $text} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Copy node(s)
#
# POST /v4/nodes/{node_id}/copy_to
# operationId: copyNodes
# --items item shape: {id: int, name?: string, timestampCreation?: string, timestampModification?: string}
@deprecated --flag node-ids
export def "nodes-copy-to copy" [
  node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --items: list # List of nodes to be copied — item shape: {id: int, name?: string, timestampCreation?: string, timestampModification?: string}
  --keep-share-links: oneof<nothing, bool> # Preserve Download Share Links and point them to the new node. (default: false)
  --node-ids: list # &#128679; Deprecated since v4.5.0  Node IDs  Please use `items` instead. (DEPRECATED)
  --resolution-strategy: string@resolution-strategy-completer # Node conflict resolution strategy:  * `autorename`  * `overwrite`  * `fail` (default: autorename)
]: any -> record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({node_id: $node_id} | format pattern "/v4/nodes/{node_id}/copy_to"))
  let body = {"items": $items, "keepShareLinks": $keep_share_links, "nodeIds": $node_ids, "resolutionStrategy": $resolution_strategy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Empty recycle bin
#
# DELETE /v4/nodes/{node_id}/deleted_nodes
# operationId: emptyDeletedNodes
export def "nodes-deleted-nodes emptyDeletedNodes" [
  node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({node_id: $node_id} | format pattern "/v4/nodes/{node_id}/deleted_nodes"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request list of deleted nodes
#
# GET /v4/nodes/{node_id}/deleted_nodes
# operationId: requestDeletedNodesSummary
export def "nodes-deleted-nodes request-deleted-nodes-summary" [
  node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter string
  --qp-sort: string # Sort string
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<cntVersions: int, firstDeletedAt: string, lastDeletedAt: string, lastDeletedNodeId: int, name: string, parentId: int, parentPath: string, referenceId: int, timestampCreation: string, timestampModification: string, type: string>, range: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_id: $node_id} | format pattern "/v4/nodes/{node_id}/deleted_nodes") $qp)
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request deleted versions of nodes
#
# GET /v4/nodes/{node_id}/deleted_nodes/versions
# operationId: requestDeletedNodeVersions
export def "nodes-deleted-nodes-versions request" [
  node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string # Node type
  --name: string # Node name
  --qp-sort: string # Sort string
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<accessedAt: string, classification: int, createdAt: string, createdBy: record, deletedAt: string, deletedBy: record, expireAt: string, id: int, isEncrypted: bool, name: string, notes: string, parentId: int, parentPath: string, referenceId: int, size: int, type: string, updatedAt: string, updatedBy: record>, range: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({node_id: $node_id} | format pattern "/v4/nodes/{node_id}/deleted_nodes/versions") $qp)
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unmark a node (room, folder or file) as favorite
#
# DELETE /v4/nodes/{node_id}/favorite
# operationId: removeFavorite
export def "nodes-favorite delete" [
  node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({node_id: $node_id} | format pattern "/v4/nodes/{node_id}/favorite"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Mark a node (room, folder or file) as favorite
#
# POST /v4/nodes/{node_id}/favorite
# operationId: addFavorite
export def "nodes-favorite create" [
  node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({node_id: $node_id} | format pattern "/v4/nodes/{node_id}/favorite"))
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Move node(s)
#
# POST /v4/nodes/{node_id}/move_to
# operationId: moveNodes
# --items item shape: {id: int, name?: string, timestampCreation?: string, timestampModification?: string}
@deprecated --flag node-ids
export def "nodes-move-to move" [
  node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --items: list # List of nodes to be moved — item shape: {id: int, name?: string, timestampCreation?: string, timestampModification?: string}
  --keep-share-links: oneof<nothing, bool> # Preserve Download Share Links and point them to the new node. (default: false)
  --node-ids: list # &#128679; Deprecated since v4.5.0  Node IDs  Please use `items` instead. (DEPRECATED)
  --resolution-strategy: string@resolution-strategy-completer # Node conflict resolution strategy:  * `autorename`  * `overwrite`  * `fail` (default: autorename)
]: any -> record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({node_id: $node_id} | format pattern "/v4/nodes/{node_id}/move_to"))
  let body = {"items": $items, "keepShareLinks": $keep_share_links, "nodeIds": $node_ids, "resolutionStrategy": $resolution_strategy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request list of parent nodes
#
# GET /v4/nodes/{node_id}/parents
# operationId: requestNodeParents
export def "nodes-parents request" [
  node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<id: int, name: string, parentId: int, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({node_id: $node_id} | format pattern "/v4/nodes/{node_id}/parents"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request list of customers
#
# GET /v4/provisioning/customers
# operationId: requestCustomers
export def "provisioning-customers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --qp-sort: string # Sort string
  --include-attributes: oneof<nothing, bool> # Include custom customer attributes.
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-service-token: string # Service Authentication token
]: nothing -> record<items: table<activationCode: string, cntGuestUser: int, cntInternalUser: int, companyName: string, createdAt: string, customerAttributes: record, customerContractType: string, customerUuid: string, id: int, isLocked: bool, lastLoginAt: string, lockStatus: bool, providerCustomerId: string, quotaMax: int, quotaUsed: int, trialDaysLeft: int, updatedAt: string, userMax: int, userUsed: int, webhooksMax: int>, range: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "include_attributes" $include_attributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/provisioning/customers" $qp)
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Service-Token": $x_sds_service_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create customer
#
# POST /v4/provisioning/customers
# operationId: createCustomer
# --customerAttributes shape: {items: list}
# --firstAdminUser shape: {authData?: record, authMethods?: list, email?: string, firstName: string, gender?: string, language?: string, lastName: string, login?: string, needsToChangePassword?: bool, needsToChangeUserName?: bool, notifyUser?: bool, password?: string, phone?: string, receiverLanguage?: string, title?: string, userName?: string}
@deprecated --flag activation-code
@deprecated --flag lock-status
export def "provisioning-customers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-service-token: string # Service Authentication token
  --activation-code: string # &#128679; Deprecated since v4.8.0  Customer activation code string:  * valid only for types `free` and `demo`  * for `pay` customers it is empty (DEPRECATED)
  --company-name: string # Company name
  --customer-attributes: record # List of customer attributes — shape: {items: list}
  customer_contract_type: string@customer-contract-type-completer # Customer type
  first_admin_user: record # First administrator user — shape: {authData?: record, authMethods?: list, email?: string, firstName: string, gender?: string, language?: string, lastName: string, login?: string, needsToChangePassword?: bool, needsToChangeUserName?: bool, notifyUser?: bool, password?: string, phone?: string, receiverLanguage?: string, title?: string, userName?: string}
  --is-locked: oneof<nothing, bool> # Customer is locked:  * `false` - unlocked  * `true` - locked    All users of this customer will be blocked and can not login anymore. (default: false)
  --lock-status: oneof<nothing, bool> # &#128679; Deprecated since v4.7.0  Customer lock status:  * `false` - unlocked  * `true` - locked    Please use `isLocked` instead.  All users of this customer will be blocked and can not login anymore. (DEPRECATED, default: false)
  --provider-customer-id: string # Provider customer ID
  quota_max: int # Maximal disc space which can be allocated by customer in bytes. -1 for unlimited (format: int64)
  --trial-days: int # Number of days left for trial period (relevant only for type `demo`)  (not used) (format: int32)
  user_max: int # Maximal number of users (format: int32)
  --webhooks-max: int # &#128640; Since v4.19.0  Maximal number of webhooks (format: int64)
]: any -> record<activationCode: string, companyName: string, createdAt: string, customerAttributes: record<items: list<record>>, customerContractType: string, customerUuid: string, firstAdminUser: record<authData: record<adConfigId: int, login: string, method: string, mustChangePassword: bool, oidConfigId: int, password: string>, authMethods: list<record>, email: string, firstName: string, gender: string, language: string, lastName: string, login: string, needsToChangePassword: bool, needsToChangeUserName: bool, notifyUser: bool, password: string, phone: string, receiverLanguage: string, title: string, userName: string>, id: int, isLocked: bool, lockStatus: bool, providerCustomerId: string, quotaMax: int, trialDays: int, userMax: int, webhooksMax: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/provisioning/customers")
  let body = {"activationCode": $activation_code, "companyName": $company_name, "customerAttributes": $customer_attributes, "customerContractType": $customer_contract_type, "firstAdminUser": $first_admin_user, "isLocked": $is_locked, "lockStatus": $lock_status, "providerCustomerId": $provider_customer_id, "quotaMax": $quota_max, "trialDays": $trial_days, "userMax": $user_max, "webhooksMax": $webhooks_max} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Service-Token": $x_sds_service_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove customer
#
# DELETE /v4/provisioning/customers/{customer_id}
# operationId: removeCustomer
export def "provisioning-customers delete" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-service-token: string # Service Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({customer_id: $customer_id} | format pattern "/v4/provisioning/customers/{customer_id}"))
  let extra_headers = {"X-Sds-Service-Token": $x_sds_service_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get customer
#
# GET /v4/provisioning/customers/{customer_id}
# operationId: requestCustomer
export def "provisioning-customers request" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include-attributes: oneof<nothing, bool> # Include custom customer attributes.
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-service-token: string # Service Authentication token
]: nothing -> record<activationCode: string, cntGuestUser: int, cntInternalUser: int, companyName: string, createdAt: string, customerAttributes: record<items: list<record>>, customerContractType: string, customerUuid: string, id: int, isLocked: bool, lastLoginAt: string, lockStatus: bool, providerCustomerId: string, quotaMax: int, quotaUsed: int, trialDaysLeft: int, updatedAt: string, userMax: int, userUsed: int, webhooksMax: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_attributes" $include_attributes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: $customer_id} | format pattern "/v4/provisioning/customers/{customer_id}") $qp)
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Service-Token": $x_sds_service_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update customer
#
# PUT /v4/provisioning/customers/{customer_id}
# operationId: updateCustomer
@deprecated --flag lock-status
export def "provisioning-customers update" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-service-token: string # Service Authentication token
  --company-name: string # Company name
  customer_contract_type: string@customer-contract-type-completer # Customer type
  --is-locked: oneof<nothing, bool> # Customer is locked:  * `false` - unlocked  * `true` - locked    All users of this customer will be blocked and can not login anymore. (default: false)
  --lock-status: oneof<nothing, bool> # &#128679; Deprecated since v4.7.0  Customer lock status:  * `false` - unlocked  * `true` - locked    Please use `isLocked` instead.  All users of this customer will be blocked and can not login anymore. (DEPRECATED, default: false)
  --provider-customer-id: string # Provider customer ID
  --quota-max: int # Maximal disc space which can be allocated by customer in bytes. -1 for unlimited (format: int64)
  --user-max: int # Maximal number of users (format: int32)
  --webhooks-max: int # &#128640; Since v4.19.0  Maximal number of webhooks (format: int64)
]: any -> record<activationCode: string, companyName: string, createdAt: string, customerAttributes: record<items: list<record>>, customerContractType: string, customerUuid: string, id: int, isLocked: bool, lockStatus: bool, providerCustomerId: string, quotaMax: int, trialDays: int, updatedAt: string, userMax: int, webhooksMax: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({customer_id: $customer_id} | format pattern "/v4/provisioning/customers/{customer_id}"))
  let body = {"companyName": $company_name, "customerContractType": $customer_contract_type, "isLocked": $is_locked, "lockStatus": $lock_status, "providerCustomerId": $provider_customer_id, "quotaMax": $quota_max, "userMax": $user_max, "webhooksMax": $webhooks_max} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Service-Token": $x_sds_service_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request customer attributes
#
# GET /v4/provisioning/customers/{customer_id}/customerAttributes
# operationId: requestCustomerAttributes
export def "provisioning-customers-customer-attributes request" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --qp-sort: string # Sort string
  --x-sds-service-token: string # Service Authentication token
]: nothing -> record<items: table<key: string, value: string>, range: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: $customer_id} | format pattern "/v4/provisioning/customers/{customer_id}/customerAttributes") $qp)
  let extra_headers = {"X-Sds-Service-Token": $x_sds_service_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set customer attributes
#
# POST /v4/provisioning/customers/{customer_id}/customerAttributes
# DEPRECATED
# operationId: setCustomerAttributes
# --items item shape: {key: string, value: string}
@deprecated
export def "provisioning-customers-customer-attributes setCustomerAttributes" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-service-token: string # Service Authentication token
  items: list # List of customer attributes — item shape: {key: string, value: string}
]: any -> record<activationCode: string, cntGuestUser: int, cntInternalUser: int, companyName: string, createdAt: string, customerAttributes: record<items: list<record>>, customerContractType: string, customerUuid: string, id: int, isLocked: bool, lastLoginAt: string, lockStatus: bool, providerCustomerId: string, quotaMax: int, quotaUsed: int, trialDaysLeft: int, updatedAt: string, userMax: int, userUsed: int, webhooksMax: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({customer_id: $customer_id} | format pattern "/v4/provisioning/customers/{customer_id}/customerAttributes"))
  let body = {"items": $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Service-Token": $x_sds_service_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add or edit customer attributes
#
# PUT /v4/provisioning/customers/{customer_id}/customerAttributes
# operationId: updateCustomerAttributes
# --items item shape: {key: string, value: string}
export def "provisioning-customers-customer-attributes update" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-service-token: string # Service Authentication token
  items: list # List of customer attributes — item shape: {key: string, value: string}
]: any -> record<activationCode: string, cntGuestUser: int, cntInternalUser: int, companyName: string, createdAt: string, customerAttributes: record<items: list<record>>, customerContractType: string, customerUuid: string, id: int, isLocked: bool, lastLoginAt: string, lockStatus: bool, providerCustomerId: string, quotaMax: int, quotaUsed: int, trialDaysLeft: int, updatedAt: string, userMax: int, userUsed: int, webhooksMax: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({customer_id: $customer_id} | format pattern "/v4/provisioning/customers/{customer_id}/customerAttributes"))
  let body = {"items": $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Service-Token": $x_sds_service_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove customer attribute
#
# DELETE /v4/provisioning/customers/{customer_id}/customerAttributes/{key}
# operationId: removeCustomerAttribute
export def "provisioning-customers-customer-attributes delete" [
  customer_id: int
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-service-token: string # Service Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({customer_id: $customer_id, key: $key} | format pattern "/v4/provisioning/customers/{customer_id}/customerAttributes/{key}"))
  let extra_headers = {"X-Sds-Service-Token": $x_sds_service_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request list of customer users
#
# GET /v4/provisioning/customers/{customer_id}/users
# operationId: requestCustomerUsers
export def "provisioning-customers-users request" [
  customer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --qp-sort: string # Sort string
  --include-attributes: oneof<nothing, bool> # Include custom user attributes.
  --include-roles: oneof<nothing, bool> # Include roles
  --include-manageable-rooms: oneof<nothing, bool> # Include hasManageableRooms (deprecated)
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-service-token: string # Service Authentication token
]: nothing -> record<items: table<avatarUuid: string, createdAt: string, email: string, expireAt: string, firstName: string, gender: string, hasManageableRooms: bool, homeRoomId: int, id: int, isEncryptionEnabled: bool, isLocked: bool, lastLoginSuccessAt: string, lastName: string, lockStatus: int, login: string, phone: string, title: string, userAttributes: record, userName: string, userRoles: record>, range: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "include_attributes" $include_attributes "scalar") (serialize-qp "include_roles" $include_roles "scalar") (serialize-qp "include_manageable_rooms" $include_manageable_rooms "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({customer_id: $customer_id} | format pattern "/v4/provisioning/customers/{customer_id}/users") $qp)
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Service-Token": $x_sds_service_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request list of tenant webhooks
#
# GET /v4/provisioning/webhooks
# operationId: requestListOfTenantWebhooks
export def "provisioning-webhooks request-list-of-tenant" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --qp-sort: string # Sort string
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-service-token: string # Service Authentication token
]: nothing -> record<items: table<createdAt: string, createdBy: record, eventTypeNames: list, expireAt: string, failStatus: int, id: int, isEnabled: bool, name: string, secret: string, updatedAt: string, updatedBy: record, url: string>, range: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/provisioning/webhooks" $qp)
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Service-Token": $x_sds_service_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create tenant webhook
#
# POST /v4/provisioning/webhooks
# operationId: createTenantWebhook
export def "provisioning-webhooks create-tenant" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-service-token: string # Service Authentication token
  event_type_names: list # List of names of event types
  --is-enabled: oneof<nothing, bool> # Is enabled
  name: string # Name
  --secret: string # Secret; used for event message signatures
  --trigger-example-event: oneof<nothing, bool> # If set to true, an example event is being created
  --body-url: string # URL (must begin with the `HTTPS` scheme)
]: any -> record<createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, eventTypeNames: list<string>, expireAt: string, failStatus: int, id: int, isEnabled: bool, name: string, secret: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/provisioning/webhooks")
  let body = {"eventTypeNames": $event_type_names, "isEnabled": $is_enabled, "name": $name, "secret": $secret, "triggerExampleEvent": $trigger_example_event, "url": $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Service-Token": $x_sds_service_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request list of event types
#
# GET /v4/provisioning/webhooks/event_types
# operationId: requestListOfEventTypesForTenant
export def "provisioning-webhooks-event-types request-list-of-event-types-for-tenant" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-service-token: string # Service Authentication token
]: nothing -> record<items: table<id: int, name: string, usableCustomerAdminWebhook: bool, usableNodeWebhook: bool, usablePushNotification: bool, usableTenantWebhook: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/provisioning/webhooks/event_types")
  let extra_headers = {"X-Sds-Service-Token": $x_sds_service_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove tenant webhook
#
# DELETE /v4/provisioning/webhooks/{webhook_id}
# operationId: removeTenantWebhook
export def "provisioning-webhooks delete-tenant" [
  webhook_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-service-token: string # Service Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({webhook_id: $webhook_id} | format pattern "/v4/provisioning/webhooks/{webhook_id}"))
  let extra_headers = {"X-Sds-Service-Token": $x_sds_service_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request tenant webhook
#
# GET /v4/provisioning/webhooks/{webhook_id}
# operationId: requestTenantWebhook
export def "provisioning-webhooks request-tenant" [
  webhook_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-service-token: string # Service Authentication token
]: nothing -> record<createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, eventTypeNames: list<string>, expireAt: string, failStatus: int, id: int, isEnabled: bool, name: string, secret: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({webhook_id: $webhook_id} | format pattern "/v4/provisioning/webhooks/{webhook_id}"))
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Service-Token": $x_sds_service_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update tenant webhook
#
# PUT /v4/provisioning/webhooks/{webhook_id}
# operationId: updateTenantWebhook
export def "provisioning-webhooks update-tenant" [
  webhook_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-service-token: string # Service Authentication token
  --event-type-names: list # List of names of event types
  --is-enabled: oneof<nothing, bool> # Is enabled
  --name: string # Name
  --secret: string # Secret; used for event message signatures
  --trigger-example-event: oneof<nothing, bool> # If set to true, an example event is being created
  --body-url: string # URL (must begin with the `HTTPS` scheme)
]: any -> record<createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, eventTypeNames: list<string>, expireAt: string, failStatus: int, id: int, isEnabled: bool, name: string, secret: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({webhook_id: $webhook_id} | format pattern "/v4/provisioning/webhooks/{webhook_id}"))
  let body = {"eventTypeNames": $event_type_names, "isEnabled": $is_enabled, "name": $name, "secret": $secret, "triggerExampleEvent": $trigger_example_event, "url": $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Service-Token": $x_sds_service_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reset tenant webhook lifetime
#
# POST /v4/provisioning/webhooks/{webhook_id}/reset_lifetime
# operationId: resetTenantWebhookLifetime
export def "provisioning-webhooks-reset-lifetime reset-tenant" [
  webhook_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-service-token: string # Service Authentication token
]: nothing -> record<createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, eventTypeNames: list<string>, expireAt: string, failStatus: int, id: int, isEnabled: bool, name: string, secret: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({webhook_id: $webhook_id} | format pattern "/v4/provisioning/webhooks/{webhook_id}/reset_lifetime"))
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Service-Token": $x_sds_service_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request public Download Share information
#
# GET /v4/public/shares/downloads/{access_key}
# operationId: requestPublicDownloadShareInfo
export def "public-shares-downloads request-public-download-share-info" [
  access_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
]: nothing -> record<createdAt: string, creatorName: string, creatorUsername: string, expireAt: string, fileKey: record<iv: string, key: string, tag: string, version: string>, fileName: string, hasDownloadLimit: bool, isEncrypted: bool, isProtected: bool, limitReached: bool, mediaType: string, name: string, notes: string, privateKeyContainer: record<createdAt: string, createdBy: int, privateKey: string, version: string>, size: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({access_key: $access_key} | format pattern "/v4/public/shares/downloads/{access_key}"))
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check public Download Share password
#
# HEAD /v4/public/shares/downloads/{access_key}
# operationId: checkPublicDownloadSharePassword
export def "public-shares-downloads check-public-download-share-password" [
  access_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --password: string # Download share password
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "password" $password "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({access_key: $access_key} | format pattern "/v4/public/shares/downloads/{access_key}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate download URL
#
# POST /v4/public/shares/downloads/{access_key}
# operationId: generateDownloadUrlPublic
export def "public-shares-downloads generateDownloadUrlPublic" [
  access_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --password: string # Password (only for password-protected shares)
]: any -> record<downloadUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({access_key: $access_key} | format pattern "/v4/public/shares/downloads/{access_key}"))
  let body = {"password": $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Download file with token
#
# GET /v4/public/shares/downloads/{access_key}/{token}
# Docs: https://tools.ietf.org/html/rfc7233 — Range Requests
# operationId: downloadFileViaTokenPublic
export def "public-shares-downloads download-file-via" [
  access_key: string
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --generic-mimetype: oneof<nothing, bool> # Always return `application/octet-stream` instead of specific mimetype
  --inline: oneof<nothing, bool> # Use Content-Disposition: `inline` instead of `attachment`
  --range: string # Range   e.g. `bytes=0-999`
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "generic_mimetype" $generic_mimetype "scalar") (serialize-qp "inline" $inline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({access_key: $access_key, token_arg: $token_arg} | format pattern "/v4/public/shares/downloads/{access_key}/{token_arg}") $qp)
  let extra_headers = {"Range": $range} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download file with token
#
# HEAD /v4/public/shares/downloads/{access_key}/{token}
# Docs: https://tools.ietf.org/html/rfc7233 — Range Requests
# operationId: downloadFileViaTokenPublic_1
export def "public-shares-downloads download-file-via-by-access_key-token" [
  access_key: string
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --generic-mimetype: oneof<nothing, bool> # Always return `application/octet-stream` instead of specific mimetype
  --inline: oneof<nothing, bool> # Use Content-Disposition: `inline` instead of `attachment`
  --range: string # Range   e.g. `bytes=0-999`
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "generic_mimetype" $generic_mimetype "scalar") (serialize-qp "inline" $inline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({access_key: $access_key, token_arg: $token_arg} | format pattern "/v4/public/shares/downloads/{access_key}/{token_arg}") $qp)
  let extra_headers = {"Range": $range} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request public Upload Share information
#
# GET /v4/public/shares/uploads/{access_key}
# operationId: requestPublicUploadShareInfo
export def "public-shares-uploads request-public-upload-share-info" [
  access_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-share-password: string # Upload share password. Should be base64-encoded.  Plain X-Sds-Share-Passwords are *deprecated* and will be removed in the future
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
]: nothing -> record<createdAt: string, creatorName: string, creatorUsername: string, expireAt: string, isEncrypted: bool, isProtected: bool, name: string, notes: string, remainingSize: int, remainingSlots: int, showUploadedFiles: bool, uploadedFiles: table<createdAt: string, hash: string, name: string, size: int>, userUserPublicKeyList: record<items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({access_key: $access_key} | format pattern "/v4/public/shares/uploads/{access_key}"))
  let extra_headers = {"X-Sds-Share-Password": $x_sds_share_password, "X-Sds-Date-Format": $x_sds_date_format} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new file upload channel
#
# POST /v4/public/shares/uploads/{access_key}
# operationId: createShareUploadChannel
export def "public-shares-uploads create-share-upload-channel" [
  access_key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --direct-s3-upload: oneof<nothing, bool> # &#128640; Since v4.15.0  Upload direct to S3 (default: false)
  name: string # File name
  --password: string # Password
  --size: int # File size in byte (format: int64)
  --timestamp-creation: string # &#128640; Since v4.22.0  Time the node was created on external file system  (default: current server datetime in UTC format) (format: date-time)
  --timestamp-modification: string # &#128640; Since v4.22.0  Time the content of a node was last modified on external file system  (default: current server datetime in UTC format) (format: date-time)
]: any -> record<uploadId: string, uploadUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({access_key: $access_key} | format pattern "/v4/public/shares/uploads/{access_key}"))
  let body = {"directS3Upload": $direct_s3_upload, "name": $name, "password": $password, "size": $size, "timestampCreation": $timestamp_creation, "timestampModification": $timestamp_modification} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancel file upload
#
# DELETE /v4/public/shares/uploads/{access_key}/{upload_id}
# operationId: cancelFileUploadViaShare
export def "public-shares-uploads cancel-file-upload-via" [
  access_key: string
  upload_id: string
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
  let full_url = (build-url $base ({access_key: $access_key, upload_id: $upload_id} | format pattern "/v4/public/shares/uploads/{access_key}/{upload_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request status of S3 file upload
#
# GET /v4/public/shares/uploads/{access_key}/{upload_id}
# operationId: requestUploadStatusPublic
export def "public-shares-uploads request-upload-status" [
  access_key: string
  upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<errorDetails: record<code: int, debugInfo: string, errorCode: int, message: string>, fileName: string, size: int, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({access_key: $access_key, upload_id: $upload_id} | format pattern "/v4/public/shares/uploads/{access_key}/{upload_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload file
#
# POST /v4/public/shares/uploads/{access_key}/{upload_id}
# Docs: https://tools.ietf.org/html/rfc7233 — Range Requests
# operationId: uploadFileAsMultipartPublic_1
export def "public-shares-uploads upload-file-as-multipart-by-access_key-upload_id" [
  access_key: string
  upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-range: string # Content-Range   e.g. `bytes 0-999/3980`
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  file: string # File (format: binary)
]: any -> record<hash: string, size: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({access_key: $access_key, upload_id: $upload_id} | format pattern "/v4/public/shares/uploads/{access_key}/{upload_id}"))
  let body = {"file": $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Range": $content_range, "X-Sds-Date-Format": $x_sds_date_format} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Complete file upload
#
# PUT /v4/public/shares/uploads/{access_key}/{upload_id}
# Docs: https://tools.ietf.org/html/rfc7233 — Range Requests
# operationId: completeFileUploadViaShare
# --items item shape: {fileKey: record, userId: int}
export def "public-shares-uploads completeFileUploadViaShare" [
  access_key: string
  upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --items: list # List of user file keys — item shape: {fileKey: record, userId: int}
]: any -> record<createdAt: string, hash: string, name: string, size: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({access_key: $access_key, upload_id: $upload_id} | format pattern "/v4/public/shares/uploads/{access_key}/{upload_id}"))
  let body = {"items": $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Complete S3 file upload
#
# PUT /v4/public/shares/uploads/{access_key}/{upload_id}/s3
# operationId: completeS3FileUploadViaShare
# --parts item shape: {partEtag: string, partNumber: int}
# --userFileKeyList item shape: {fileKey: record, userId: int}
export def "public-shares-uploads-s3 completeS3FileUploadViaShare" [
  access_key: string
  upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  parts: list # List of S3 file upload parts — item shape: {partEtag: string, partNumber: int}
  --user-file-key-list: list # List of user file keys — item shape: {fileKey: record, userId: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({access_key: $access_key, upload_id: $upload_id} | format pattern "/v4/public/shares/uploads/{access_key}/{upload_id}/s3"))
  let body = {"parts": $parts, "userFileKeyList": $user_file_key_list} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generate presigned URLs for S3 file upload
#
# POST /v4/public/shares/uploads/{access_key}/{upload_id}/s3_urls
# operationId: generatePresignedUrlsPublic
export def "public-shares-uploads-s3-urls generatePresignedUrlsPublic" [
  access_key: string
  upload_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  first_part_number: int # First part number of a range of requested presigned URLs (for S3 it is: `1`) (format: int32)
  last_part_number: int # Last part number of a range of requested presigned URLs (format: int32)
  size: int # `Content-Length` header size for each presigned URL (in bytes)  *MUST* be >= 5 MB except the last part. (format: int64)
]: any -> record<urls: table<partNumber: int, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({access_key: $access_key, upload_id: $upload_id} | format pattern "/v4/public/shares/uploads/{access_key}/{upload_id}/s3_urls"))
  let body = {"firstPartNumber": $first_part_number, "lastPartNumber": $last_part_number, "size": $size} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request third-party software dependencies
#
# GET /v4/public/software/third_party_dependencies
# operationId: requestThirdPartyDependencies
export def "public-software-third-party-dependencies request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<artifactId: string, description: string, groupId: string, id: string, licenses: list<string>, name: string, type: string, url: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/public/software/third_party_dependencies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request software version information
#
# GET /v4/public/software/version
# operationId: requestSoftwareVersion
export def "public-software-version request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
]: nothing -> record<buildDate: string, isDracoonCloud: bool, restApiVersion: string, scmRevisionNumber: string, sdsServerVersion: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/public/software/version")
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request system information
#
# GET /v4/public/system/info
# Docs: https://tools.ietf.org/html/rfc5646 — Tags for Identifying Languages
# operationId: requestSystemInfo
export def "public-system-info request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-enabled: oneof<nothing, bool> # Show only enabled authentication methods
]: nothing -> record<authMethods: table<isEnabled: bool, name: string, priority: int>, hideLoginInputFields: bool, languageDefault: string, s3EnforceDirectUpload: bool, s3Hosts: list<string>, useS3Storage: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "is_enabled" $is_enabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/public/system/info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request Active Directory authentication information
#
# GET /v4/public/system/info/auth/ad
# operationId: requestActiveDirectoryAuthInfo
export def "public-system-info-auth-ad request-active-directory" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-global-available: oneof<nothing, bool> # Show only global available items
]: nothing -> record<items: table<alias: string, id: int, isGlobalAvailable: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "is_global_available" $is_global_available "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/public/system/info/auth/ad" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request OpenID Connect provider authentication information
#
# GET /v4/public/system/info/auth/openid
# operationId: requestOpenIdAuthInfo
export def "public-system-info-auth-openid request-open" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --is-global-available: oneof<nothing, bool> # Show only global available items
]: nothing -> record<items: table<id: int, isGlobalAvailable: bool, issuer: string, mappingClaim: string, name: string, userManagementUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "is_global_available" $is_global_available "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/public/system/info/auth/openid" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request system time
#
# GET /v4/public/time
# operationId: requestSystemTime
export def "public-time request-system" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
]: nothing -> record<time: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/public/time")
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request list of subscription scopes
#
# GET /v4/resources/user/notifications/scopes
# operationId: requestSubscriptionScopes
export def "resources-user-notifications-scopes request-subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<items: table<id: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/resources/user/notifications/scopes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request user avatar
#
# GET /v4/resources/users/{user_id}/avatar/{uuid}
# operationId: requestUserAvatar
export def "resources-users-avatar request" [
  user_id: int
  uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<avatarUri: string, avatarUuid: string, isCustomAvatar: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id, uuid: $uuid} | format pattern "/v4/resources/users/{user_id}/avatar/{uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request all roles with assigned rights
#
# GET /v4/roles
# operationId: requestRoles
export def "roles request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<description: string, id: int, items: list, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/roles")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Revoke granted role from group(s)
#
# DELETE /v4/roles/{role_id}/groups
# operationId: revokeRoleGroups
export def "roles-groups delete" [
  role_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  ids: list # List of group IDs
]: any -> record<items: table<id: int, isMember: bool, name: string>, range: record<limit: int, offset: int, total: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({role_id: $role_id} | format pattern "/v4/roles/{role_id}/groups"))
  let body = {"ids": $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request groups with specific role
#
# GET /v4/roles/{role_id}/groups
# operationId: requestRoleGroups
export def "roles-groups request" [
  role_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<id: int, isMember: bool, name: string>, range: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({role_id: $role_id} | format pattern "/v4/roles/{role_id}/groups") $qp)
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assign group(s) to the role
#
# POST /v4/roles/{role_id}/groups
# operationId: addRoleGroups
export def "roles-groups create" [
  role_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  ids: list # List of group IDs
]: any -> record<items: table<id: int, isMember: bool, name: string>, range: record<limit: int, offset: int, total: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({role_id: $role_id} | format pattern "/v4/roles/{role_id}/groups"))
  let body = {"ids": $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Revoke granted role from user(s)
#
# DELETE /v4/roles/{role_id}/users
# operationId: revokeRoleUsers
export def "roles-users delete" [
  role_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  ids: list # List of user IDs
]: any -> record<items: table<displayName: string, id: int, isMember: bool, userInfo: record>, range: record<limit: int, offset: int, total: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({role_id: $role_id} | format pattern "/v4/roles/{role_id}/users"))
  let body = {"ids": $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request users with specific role
#
# GET /v4/roles/{role_id}/users
# operationId: requestRoleUsers
export def "roles-users request" [
  role_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<displayName: string, id: int, isMember: bool, userInfo: record>, range: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({role_id: $role_id} | format pattern "/v4/roles/{role_id}/users") $qp)
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Assign user(s) to the role
#
# POST /v4/roles/{role_id}/users
# operationId: addRoleUsers
export def "roles-users create" [
  role_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  ids: list # List of user IDs
]: any -> record<items: table<displayName: string, id: int, isMember: bool, userInfo: record>, range: record<limit: int, offset: int, total: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({role_id: $role_id} | format pattern "/v4/roles/{role_id}/users"))
  let body = {"ids": $ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request customer settings
#
# GET /v4/settings
# operationId: requestSettings
export def "settings request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<homeRoomParentId: int, homeRoomParentName: string, homeRoomQuota: int, homeRoomsActive: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/settings")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set customer settings
#
# PUT /v4/settings
# operationId: setSettings
export def "settings setSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --home-room-parent-name: string # Homeroom Parent Name
  --home-room-quota: int # Homeroom Quota in bytes (format: int64)
  --home-rooms-active: oneof<nothing, bool> # Homerooms active
]: any -> record<homeRoomParentId: int, homeRoomParentName: string, homeRoomQuota: int, homeRoomsActive: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/settings")
  let body = {"homeRoomParentName": $home_room_parent_name, "homeRoomQuota": $home_room_quota, "homeRoomsActive": $home_rooms_active} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove system rescue key pair
#
# DELETE /v4/settings/keypair
# operationId: removeSystemRescueKeyPair
export def "settings-keypair delete-system-rescue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # Version (NEW)
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/settings/keypair" $qp)
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request system rescue key pair
#
# GET /v4/settings/keypair
# operationId: requestSystemRescueKeyPair
export def "settings-keypair request-system-rescue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # Version (NEW)
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<privateKeyContainer: record<createdAt: string, createdBy: int, privateKey: string, version: string>, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/settings/keypair" $qp)
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Activate client-side encryption for customer
#
# POST /v4/settings/keypair
# operationId: setSystemRescueKeyPair
# --privateKeyContainer shape: {createdAt?: string, createdBy?: int, privateKey: string, version: string}
# --publicKeyContainer shape: {createdAt?: string, createdBy?: int, publicKey: string, version: string}
export def "settings-keypair setSystemRescueKeyPair" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  private_key_container: record # Private key container — shape: {createdAt?: string, createdBy?: int, privateKey: string, version: string}
  public_key_container: record # Public key container — shape: {createdAt?: string, createdBy?: int, publicKey: string, version: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/settings/keypair")
  let body = {"privateKeyContainer": $private_key_container, "publicKeyContainer": $public_key_container} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request all system rescue key pairs
#
# GET /v4/settings/keypairs
# operationId: requestAllSystemRescueKeyPairs
export def "settings-keypairs request-all-system-rescue" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> table<privateKeyContainer: record<createdAt: string, createdBy: int, privateKey: string, version: string>, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/settings/keypairs")
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create system rescue key pair and preserve copy of old private key
#
# POST /v4/settings/keypairs
# operationId: createAndPreserveKeyPair
# --previousPrivateKey shape: {createdAt?: string, createdBy?: int, privateKey: string, version: string}
# --privateKeyContainer shape: {createdAt?: string, createdBy?: int, privateKey: string, version: string}
# --publicKeyContainer shape: {createdAt?: string, createdBy?: int, publicKey: string, version: string}
export def "settings-keypairs create-and-preserve" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  previous_private_key: record # Private key container — shape: {createdAt?: string, createdBy?: int, privateKey: string, version: string}
  private_key_container: record # Private key container — shape: {createdAt?: string, createdBy?: int, privateKey: string, version: string}
  public_key_container: record # Public key container — shape: {createdAt?: string, createdBy?: int, publicKey: string, version: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/settings/keypairs")
  let body = {"previousPrivateKey": $previous_private_key, "privateKeyContainer": $private_key_container, "publicKeyContainer": $public_key_container} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request list of notification channels
#
# GET /v4/settings/notifications/channels
# operationId: requestNotificationChannels
export def "settings-notifications-channels request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<frequency: int, id: int, isEnabled: bool, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/settings/notifications/channels")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Toggle notification channels
#
# PUT /v4/settings/notifications/channels
# operationId: toggleNotificationChannels
export def "settings-notifications-channels toggleNotificationChannels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  channel_id: int # Channel ID (format: int32)
  --is-enabled: oneof<nothing, bool> # Determines whether channel is enabled
]: any -> record<items: table<frequency: int, id: int, isEnabled: bool, name: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/settings/notifications/channels")
  let body = {"channelId": $channel_id, "isEnabled": $is_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request list of webhooks
#
# GET /v4/settings/webhooks
# operationId: requestListOfWebhooks
export def "settings-webhooks request-list-of" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --qp-sort: string # Sort string
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<createdAt: string, createdBy: record, eventTypeNames: list, expireAt: string, failStatus: int, id: int, isEnabled: bool, name: string, secret: string, updatedAt: string, updatedBy: record, url: string>, range: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/settings/webhooks" $qp)
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create webhook
#
# POST /v4/settings/webhooks
# operationId: createWebhook
export def "settings-webhooks create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  event_type_names: list # List of names of event types
  --is-enabled: oneof<nothing, bool> # Is enabled
  name: string # Name
  --secret: string # Secret; used for event message signatures
  --trigger-example-event: oneof<nothing, bool> # If set to true, an example event is being created
  --body-url: string # URL (must begin with the `HTTPS` scheme)
]: any -> record<createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, eventTypeNames: list<string>, expireAt: string, failStatus: int, id: int, isEnabled: bool, name: string, secret: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/settings/webhooks")
  let body = {"eventTypeNames": $event_type_names, "isEnabled": $is_enabled, "name": $name, "secret": $secret, "triggerExampleEvent": $trigger_example_event, "url": $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request list of event types
#
# GET /v4/settings/webhooks/event_types
# operationId: requestListOfEventTypesForConfigManager
export def "settings-webhooks-event-types request-list-of-event-types-for-config-manager" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<id: int, name: string, usableCustomerAdminWebhook: bool, usableNodeWebhook: bool, usablePushNotification: bool, usableTenantWebhook: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/settings/webhooks/event_types")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove webhook
#
# DELETE /v4/settings/webhooks/{webhook_id}
# operationId: removeWebhook
export def "settings-webhooks delete" [
  webhook_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({webhook_id: $webhook_id} | format pattern "/v4/settings/webhooks/{webhook_id}"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request webhook
#
# GET /v4/settings/webhooks/{webhook_id}
# operationId: requestWebhook
export def "settings-webhooks request" [
  webhook_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, eventTypeNames: list<string>, expireAt: string, failStatus: int, id: int, isEnabled: bool, name: string, secret: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({webhook_id: $webhook_id} | format pattern "/v4/settings/webhooks/{webhook_id}"))
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update webhook
#
# PUT /v4/settings/webhooks/{webhook_id}
# operationId: updateWebhook
export def "settings-webhooks update" [
  webhook_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --event-type-names: list # List of names of event types
  --is-enabled: oneof<nothing, bool> # Is enabled
  --name: string # Name
  --secret: string # Secret; used for event message signatures
  --trigger-example-event: oneof<nothing, bool> # If set to true, an example event is being created
  --body-url: string # URL (must begin with the `HTTPS` scheme)
]: any -> record<createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, eventTypeNames: list<string>, expireAt: string, failStatus: int, id: int, isEnabled: bool, name: string, secret: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({webhook_id: $webhook_id} | format pattern "/v4/settings/webhooks/{webhook_id}"))
  let body = {"eventTypeNames": $event_type_names, "isEnabled": $is_enabled, "name": $name, "secret": $secret, "triggerExampleEvent": $trigger_example_event, "url": $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reset webhook lifetime
#
# POST /v4/settings/webhooks/{webhook_id}/reset_lifetime
# operationId: resetWebhookLifetime
export def "settings-webhooks-reset-lifetime reset" [
  webhook_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, eventTypeNames: list<string>, expireAt: string, failStatus: int, id: int, isEnabled: bool, name: string, secret: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({webhook_id: $webhook_id} | format pattern "/v4/settings/webhooks/{webhook_id}/reset_lifetime"))
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove Download Shares
#
# DELETE /v4/shares/downloads
# operationId: deleteDownloadShares
export def "shares-downloads delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  share_ids: list # List of share IDs
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/shares/downloads")
  let body = {"shareIds": $share_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request list of Download Shares
#
# GET /v4/shares/downloads
# operationId: requestDownloadShares
export def "shares-downloads list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter string
  --qp-sort: string # Sort string
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<accessKey: string, classification: int, cntDownloads: int, createdAt: string, createdBy: record, dataUrl: string, expireAt: string, id: int, internalNotes: string, isEncrypted: bool, isProtected: bool, maxDownloads: int, name: string, nodeId: int, nodePath: string, nodeType: string, notes: string, notifyCreator: bool, recipients: string, showCreatorName: bool, showCreatorUsername: bool, smsRecipients: string, updatedAt: string, updatedBy: record>, range: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/shares/downloads" $qp)
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new Download Share
#
# POST /v4/shares/downloads
# operationId: createDownloadShare
# --expiration shape: {enableExpiration: bool, expireAt?: string}
# --fileKey shape: {iv: string, key: string, tag: string, version: string}
# --keyPair shape: {privateKeyContainer: record, publicKeyContainer: record}
@deprecated --flag creator-language
@deprecated --flag mail-body
@deprecated --flag mail-recipients
@deprecated --flag mail-subject
@deprecated --flag notify-creator
@deprecated --flag send-mail
@deprecated --flag send-sms
@deprecated --flag sms-recipients
export def "shares-downloads create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --creator-language: string # &#128679; Deprecated since v4.20.0  Language tag for messages to creator (DEPRECATED)
  --expiration: record # Expiration information — shape: {enableExpiration: bool, expireAt?: string}
  --file-key: record # File key information — shape: {iv: string, key: string, tag: string, version: string}
  --internal-notes: string # &#128640; Since v4.11.0  Internal notes
  --key-pair: record # Key pair container — shape: {privateKeyContainer: record, publicKeyContainer: record}
  --mail-body: string # &#128679; Deprecated since v4.11.0  Notification email content (DEPRECATED)
  --mail-recipients: string # &#128679; Deprecated since v4.11.0  CSV string of recipient email addresses (DEPRECATED)
  --mail-subject: string # &#128679; Deprecated since v4.11.0  Notification email subject (DEPRECATED)
  --max-downloads: int # Max allowed downloads (format: int32)
  --name: string # Alias name  (default: name of the shared node)
  node_id: int # Source node ID (format: int64)
  --notes: string # User notes
  --notify-creator: oneof<nothing, bool> # &#128679; Deprecated since v4.20.0  Notify creator on every download. (DEPRECATED, default: false)
  --password: string # Access password, not allowed for encrypted shares
  --receiver-language: string # Language tag for messages to receiver
  --send-mail: oneof<nothing, bool> # &#128679; Deprecated since v4.11.0  Notify recipients via email  Please use `POST /shares/downloads/{share_id}/email` API instead. (DEPRECATED, default: false)
  --send-sms: oneof<nothing, bool> # &#128679; Deprecated since v4.11.0  Send share password via SMS  Please use `textMessageRecipients` attribute instead. (DEPRECATED, default: false)
  --show-creator-name: oneof<nothing, bool> # Show creator first and last name. (default: false)
  --show-creator-username: oneof<nothing, bool> # Show creator email address. (default: false)
  --sms-recipients: string # &#128679; Deprecated since v4.11.0  CSV string of recipient MSISDNs (DEPRECATED)
  --text-message-recipients: list # &#128640; Since v4.11.0  List of recipient FQTNs  E.123 / E.164 Format
]: any -> record<accessKey: string, classification: int, cntDownloads: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, dataUrl: string, expireAt: string, id: int, internalNotes: string, isEncrypted: bool, isProtected: bool, maxDownloads: int, name: string, nodeId: int, nodePath: string, nodeType: string, notes: string, notifyCreator: bool, recipients: string, showCreatorName: bool, showCreatorUsername: bool, smsRecipients: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/shares/downloads")
  let body = {"creatorLanguage": $creator_language, "expiration": $expiration, "fileKey": $file_key, "internalNotes": $internal_notes, "keyPair": $key_pair, "mailBody": $mail_body, "mailRecipients": $mail_recipients, "mailSubject": $mail_subject, "maxDownloads": $max_downloads, "name": $name, "nodeId": $node_id, "notes": $notes, "notifyCreator": $notify_creator, "password": $password, "receiverLanguage": $receiver_language, "sendMail": $send_mail, "sendSms": $send_sms, "showCreatorName": $show_creator_name, "showCreatorUsername": $show_creator_username, "smsRecipients": $sms_recipients, "textMessageRecipients": $text_message_recipients} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a list of Download Shares
#
# PUT /v4/shares/downloads
# operationId: updateDownloadShares
# --expiration shape: {enableExpiration: bool, expireAt?: string}
export def "shares-downloads update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --expiration: record # Expiration information — shape: {enableExpiration: bool, expireAt?: string}
  --max-downloads: int # Max allowed downloads (format: int32)
  object_ids: list # List of ids
  --reset-max-downloads: oneof<nothing, bool> # Set 'true' to reset 'maxDownloads' for Download Share.
  --show-creator-name: oneof<nothing, bool> # Show creator first and last name.
  --show-creator-username: oneof<nothing, bool> # Show creator email address.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/shares/downloads")
  let body = {"expiration": $expiration, "maxDownloads": $max_downloads, "objectIds": $object_ids, "resetMaxDownloads": $reset_max_downloads, "showCreatorName": $show_creator_name, "showCreatorUsername": $show_creator_username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove Download Share
#
# DELETE /v4/shares/downloads/{share_id}
# operationId: removeDownloadShare
export def "shares-downloads delete-by-share_id" [
  share_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({share_id: $share_id} | format pattern "/v4/shares/downloads/{share_id}"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request Download Share
#
# GET /v4/shares/downloads/{share_id}
# operationId: requestDownloadShare
export def "shares-downloads request" [
  share_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<accessKey: string, classification: int, cntDownloads: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, dataUrl: string, expireAt: string, id: int, internalNotes: string, isEncrypted: bool, isProtected: bool, maxDownloads: int, name: string, nodeId: int, nodePath: string, nodeType: string, notes: string, notifyCreator: bool, recipients: string, showCreatorName: bool, showCreatorUsername: bool, smsRecipients: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({share_id: $share_id} | format pattern "/v4/shares/downloads/{share_id}"))
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Download Share
#
# PUT /v4/shares/downloads/{share_id}
# operationId: updateDownloadShare
# --expiration shape: {enableExpiration: bool, expireAt?: string}
@deprecated --flag notify-creator
export def "shares-downloads update-by-share_id" [
  share_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --default-country: string # Country shorthand symbol (cf. ISO 3166-2)
  --expiration: record # Expiration information — shape: {enableExpiration: bool, expireAt?: string}
  --internal-notes: string # &#128640; Since v4.11.0  Internal notes
  --max-downloads: int # Max allowed downloads (format: int32)
  --name: string # Alias name
  --notes: string # User notes
  --notify-creator: oneof<nothing, bool> # &#128679; Deprecated since v4.20.0  Notify creator on every download. (DEPRECATED)
  --password: string # Access password, not allowed for encrypted shares
  --receiver-language: string # Language tag for messages to receiver
  --reset-max-downloads: oneof<nothing, bool> # Set 'true' to reset 'maxDownloads' for Download Share.
  --reset-password: oneof<nothing, bool> # Set 'true' to reset 'password' for Download Share.
  --show-creator-name: oneof<nothing, bool> # Show creator first and last name.
  --show-creator-username: oneof<nothing, bool> # Show creator email address.
  --text-message-recipients: list # List of recipient FQTNs  E.123 / E.164 Format
]: any -> record<accessKey: string, classification: int, cntDownloads: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, dataUrl: string, expireAt: string, id: int, internalNotes: string, isEncrypted: bool, isProtected: bool, maxDownloads: int, name: string, nodeId: int, nodePath: string, nodeType: string, notes: string, notifyCreator: bool, recipients: string, showCreatorName: bool, showCreatorUsername: bool, smsRecipients: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({share_id: $share_id} | format pattern "/v4/shares/downloads/{share_id}"))
  let body = {"defaultCountry": $default_country, "expiration": $expiration, "internalNotes": $internal_notes, "maxDownloads": $max_downloads, "name": $name, "notes": $notes, "notifyCreator": $notify_creator, "password": $password, "receiverLanguage": $receiver_language, "resetMaxDownloads": $reset_max_downloads, "resetPassword": $reset_password, "showCreatorName": $show_creator_name, "showCreatorUsername": $show_creator_username, "textMessageRecipients": $text_message_recipients} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send an existing Download Share link via email
#
# POST /v4/shares/downloads/{share_id}/email
# operationId: sendDownloadShareLinkViaEmail
export def "shares-downloads-email send-download-share-link-via" [
  share_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --body-body: string # Notification email content
  --receiver-language: string # Language tag for messages to receiver
  recipients: list # List of recipient email addresses
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({share_id: $share_id} | format pattern "/v4/shares/downloads/{share_id}/email"))
  let body = {"body": $body_body, "receiverLanguage": $receiver_language, "recipients": $recipients} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request Download Share via QR Code
#
# GET /v4/shares/downloads/{share_id}/qr
# operationId: requestDownloadShareQr
export def "shares-downloads-qr request" [
  share_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<accessKey: string, classification: int, cntDownloads: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, dataUrl: string, expireAt: string, id: int, internalNotes: string, isEncrypted: bool, isProtected: bool, maxDownloads: int, name: string, nodeId: int, nodePath: string, nodeType: string, notes: string, notifyCreator: bool, recipients: string, showCreatorName: bool, showCreatorUsername: bool, smsRecipients: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({share_id: $share_id} | format pattern "/v4/shares/downloads/{share_id}/qr"))
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove Upload Shares
#
# DELETE /v4/shares/uploads
# operationId: deleteUploadShares
export def "shares-uploads delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  share_ids: list # List of share IDs
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/shares/uploads")
  let body = {"shareIds": $share_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request list of Upload Shares
#
# GET /v4/shares/uploads
# operationId: requestUploadShares
export def "shares-uploads list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter string
  --qp-sort: string # Sort string
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<accessKey: string, cntFiles: int, cntUploads: int, createdAt: string, createdBy: record, dataUrl: string, expireAt: string, filesExpiryPeriod: int, id: int, internalNotes: string, isEncrypted: bool, isProtected: bool, maxSize: int, maxSlots: int, name: string, notes: string, notifyCreator: bool, recipients: string, showCreatorName: bool, showCreatorUsername: bool, showUploadedFiles: bool, smsRecipients: string, targetId: int, targetPath: string, targetType: string, updatedAt: string, updatedBy: record>, range: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/shares/uploads" $qp)
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new Upload Share
#
# POST /v4/shares/uploads
# operationId: createUploadShare
# --expiration shape: {enableExpiration: bool, expireAt?: string}
@deprecated --flag creator-language
@deprecated --flag mail-body
@deprecated --flag mail-recipients
@deprecated --flag mail-subject
@deprecated --flag notify-creator
@deprecated --flag send-mail
@deprecated --flag send-sms
@deprecated --flag sms-recipients
export def "shares-uploads create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --creator-language: string # &#128679; Deprecated since v4.20.0  Language tag for messages to creator (DEPRECATED)
  --expiration: record # Expiration information — shape: {enableExpiration: bool, expireAt?: string}
  --files-expiry-period: int # Number of days after which uploaded files expire (format: int32)
  --internal-notes: string # &#128640; Since v4.11.0  Internal notes
  --mail-body: string # &#128679; Deprecated since v4.11.0  Notification email content (DEPRECATED)
  --mail-recipients: string # &#128679; Deprecated since v4.11.0  CSV string of recipient email addresses (DEPRECATED)
  --mail-subject: string # &#128679; Deprecated since v4.11.0  Notification email subject (DEPRECATED)
  --max-size: int # Maximal total size of uploaded files (in bytes) (format: int64)
  --max-slots: int # Maximal amount of files to upload (format: int32)
  --name: string # Alias name  (default: name of the shared node)
  --notes: string # User notes
  --notify-creator: oneof<nothing, bool> # &#128679; Deprecated since v4.20.0  Notify creator on every upload. (DEPRECATED, default: false)
  --password: string # Password
  --receiver-language: string # Language tag for messages to receiver
  --send-mail: oneof<nothing, bool> # &#128679; Deprecated since v4.11.0  Notify recipients via email  Please use `POST /shares/uploads/{share_id}/email` API instead. (DEPRECATED, default: false)
  --send-sms: oneof<nothing, bool> # &#128679; Deprecated since v4.11.0  Send share password via SMS  Please use `textMessageRecipients` attribute instead. (DEPRECATED, default: false)
  --show-creator-name: oneof<nothing, bool> # &#128640; Since v4.11.0  Show creator first and last name. (default: false)
  --show-creator-username: oneof<nothing, bool> # &#128640; Since v4.11.0  Show creator email address. (default: false)
  --show-uploaded-files: oneof<nothing, bool> # Allow display of already uploaded files (default: false)
  --sms-recipients: string # &#128679; Deprecated since v4.11.0  CSV string of recipient MSISDNs (DEPRECATED)
  target_id: int # Target room or folder ID (format: int64)
  --text-message-recipients: list # &#128640; Since v4.11.0  List of recipient FQTNs  E.123 / E.164 Format
]: any -> record<accessKey: string, cntFiles: int, cntUploads: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, dataUrl: string, expireAt: string, filesExpiryPeriod: int, id: int, internalNotes: string, isEncrypted: bool, isProtected: bool, maxSize: int, maxSlots: int, name: string, notes: string, notifyCreator: bool, recipients: string, showCreatorName: bool, showCreatorUsername: bool, showUploadedFiles: bool, smsRecipients: string, targetId: int, targetPath: string, targetType: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/shares/uploads")
  let body = {"creatorLanguage": $creator_language, "expiration": $expiration, "filesExpiryPeriod": $files_expiry_period, "internalNotes": $internal_notes, "mailBody": $mail_body, "mailRecipients": $mail_recipients, "mailSubject": $mail_subject, "maxSize": $max_size, "maxSlots": $max_slots, "name": $name, "notes": $notes, "notifyCreator": $notify_creator, "password": $password, "receiverLanguage": $receiver_language, "sendMail": $send_mail, "sendSms": $send_sms, "showCreatorName": $show_creator_name, "showCreatorUsername": $show_creator_username, "showUploadedFiles": $show_uploaded_files, "smsRecipients": $sms_recipients, "targetId": $target_id, "textMessageRecipients": $text_message_recipients} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update List of Upload Shares
#
# PUT /v4/shares/uploads
# operationId: updateUploadShares
# --expiration shape: {enableExpiration: bool, expireAt?: string}
export def "shares-uploads update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --expiration: record # Expiration information — shape: {enableExpiration: bool, expireAt?: string}
  --files-expiry-period: int # Number of days after which uploaded files expire (format: int32)
  --max-size: int # Maximal total size of uploaded files (in bytes) (format: int64)
  --max-slots: int # Maximal amount of files to upload (format: int32)
  object_ids: list # List of ids
  --reset-files-expiry-period: oneof<nothing, bool> # Set 'true' to reset 'filesExpiryPeriod' for Upload Share
  --reset-max-size: oneof<nothing, bool> # Set 'true' to reset 'maxSize' for Upload Share
  --reset-max-slots: oneof<nothing, bool> # Set 'true' to reset 'maxSlots' for Upload Share
  --show-creator-name: oneof<nothing, bool> # Show creator first and last name.
  --show-creator-username: oneof<nothing, bool> # Show creator email address.
  --show-uploaded-files: oneof<nothing, bool> # Allow display of already uploaded files
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/shares/uploads")
  let body = {"expiration": $expiration, "filesExpiryPeriod": $files_expiry_period, "maxSize": $max_size, "maxSlots": $max_slots, "objectIds": $object_ids, "resetFilesExpiryPeriod": $reset_files_expiry_period, "resetMaxSize": $reset_max_size, "resetMaxSlots": $reset_max_slots, "showCreatorName": $show_creator_name, "showCreatorUsername": $show_creator_username, "showUploadedFiles": $show_uploaded_files} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove Upload Share
#
# DELETE /v4/shares/uploads/{share_id}
# operationId: removeUploadShare
export def "shares-uploads delete-by-share_id" [
  share_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({share_id: $share_id} | format pattern "/v4/shares/uploads/{share_id}"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request Upload Share
#
# GET /v4/shares/uploads/{share_id}
# operationId: requestUploadShare
export def "shares-uploads request" [
  share_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<accessKey: string, cntFiles: int, cntUploads: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, dataUrl: string, expireAt: string, filesExpiryPeriod: int, id: int, internalNotes: string, isEncrypted: bool, isProtected: bool, maxSize: int, maxSlots: int, name: string, notes: string, notifyCreator: bool, recipients: string, showCreatorName: bool, showCreatorUsername: bool, showUploadedFiles: bool, smsRecipients: string, targetId: int, targetPath: string, targetType: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({share_id: $share_id} | format pattern "/v4/shares/uploads/{share_id}"))
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Upload Share
#
# PUT /v4/shares/uploads/{share_id}
# operationId: updateUploadShare
# --expiration shape: {enableExpiration: bool, expireAt?: string}
@deprecated --flag notify-creator
export def "shares-uploads update-by-share_id" [
  share_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --default-country: string # Country shorthand symbol (cf. ISO 3166-2)
  --expiration: record # Expiration information — shape: {enableExpiration: bool, expireAt?: string}
  --files-expiry-period: int # Number of days after which uploaded files expire (format: int32)
  --internal-notes: string # &#128640; Since v4.11.0  Internal notes
  --max-size: int # Maximal total size of uploaded files (in bytes) (format: int64)
  --max-slots: int # Maximal amount of files to upload (format: int32)
  --name: string # Alias name
  --notes: string # User notes
  --notify-creator: oneof<nothing, bool> # &#128679; Deprecated since v4.20.0  Notify creator on every upload. (DEPRECATED)
  --password: string # Password
  --receiver-language: string # Language tag for messages to receiver
  --reset-files-expiry-period: oneof<nothing, bool> # Set 'true' to reset 'filesExpiryPeriod' for Upload Share
  --reset-max-size: oneof<nothing, bool> # Set 'true' to reset 'maxSize' for Upload Share
  --reset-max-slots: oneof<nothing, bool> # Set 'true' to reset 'maxSlots' for Upload Share
  --reset-password: oneof<nothing, bool> # Set 'true' to reset 'password' for Upload Share.
  --show-creator-name: oneof<nothing, bool> # Show creator first and last name.
  --show-creator-username: oneof<nothing, bool> # Show creator email address.
  --show-uploaded-files: oneof<nothing, bool> # Allow display of already uploaded files
  --text-message-recipients: list # List of recipient FQTNs  E.123 / E.164 Format
]: any -> record<accessKey: string, cntFiles: int, cntUploads: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, dataUrl: string, expireAt: string, filesExpiryPeriod: int, id: int, internalNotes: string, isEncrypted: bool, isProtected: bool, maxSize: int, maxSlots: int, name: string, notes: string, notifyCreator: bool, recipients: string, showCreatorName: bool, showCreatorUsername: bool, showUploadedFiles: bool, smsRecipients: string, targetId: int, targetPath: string, targetType: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({share_id: $share_id} | format pattern "/v4/shares/uploads/{share_id}"))
  let body = {"defaultCountry": $default_country, "expiration": $expiration, "filesExpiryPeriod": $files_expiry_period, "internalNotes": $internal_notes, "maxSize": $max_size, "maxSlots": $max_slots, "name": $name, "notes": $notes, "notifyCreator": $notify_creator, "password": $password, "receiverLanguage": $receiver_language, "resetFilesExpiryPeriod": $reset_files_expiry_period, "resetMaxSize": $reset_max_size, "resetMaxSlots": $reset_max_slots, "resetPassword": $reset_password, "showCreatorName": $show_creator_name, "showCreatorUsername": $show_creator_username, "showUploadedFiles": $show_uploaded_files, "textMessageRecipients": $text_message_recipients} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send an existing Upload Share link via email
#
# POST /v4/shares/uploads/{share_id}/email
# operationId: sendUploadShareLinkViaEmail
export def "shares-uploads-email send-upload-share-link-via" [
  share_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --body-body: string # Notification email content
  --receiver-language: string # Language tag for messages to receiver
  recipients: list # List of recipient email addresses
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({share_id: $share_id} | format pattern "/v4/shares/uploads/{share_id}/email"))
  let body = {"body": $body_body, "receiverLanguage": $receiver_language, "recipients": $recipients} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request Upload Share via QR Code
#
# GET /v4/shares/uploads/{share_id}/qr
# operationId: requestUploadShareQr
export def "shares-uploads-qr request" [
  share_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<accessKey: string, cntFiles: int, cntUploads: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, dataUrl: string, expireAt: string, filesExpiryPeriod: int, id: int, internalNotes: string, isEncrypted: bool, isProtected: bool, maxSize: int, maxSlots: int, name: string, notes: string, notifyCreator: bool, recipients: string, showCreatorName: bool, showCreatorUsername: bool, showUploadedFiles: bool, smsRecipients: string, targetId: int, targetPath: string, targetType: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({share_id: $share_id} | format pattern "/v4/shares/uploads/{share_id}/qr"))
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Test Active Directory configuration
#
# POST /v4/system/config/actions/test/ad
# operationId: testAdConfig
export def "system-config-actions-test-ad test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  ldap_users_domain: string # Search scope of Active Directory; only users below this node can log on.
  server_admin_name: string # Distinguished Name (DN) of Active Directory administrative account
  server_admin_password: string # Password of Active Directory administrative account
  server_ip: string # IPv4 or IPv6 address or host name
  server_port: int # Port (format: int32)
  --ssl-finger-print: string # SSL finger print of Active Directory server.  Mandatory for LDAPS connections.  Format: `Algorithm/Fingerprint`
  --use-ldaps: oneof<nothing, bool> # Determines whether LDAPS should be used instead of plain LDAP. (default: false)
]: any -> record<ldapUsersDomain: string, serverAdminName: string, serverAdminPassword: string, serverIp: string, serverPort: int, sslFingerPrint: string, useLdaps: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/actions/test/ad")
  let body = {"ldapUsersDomain": $ldap_users_domain, "serverAdminName": $server_admin_name, "serverAdminPassword": $server_admin_password, "serverIp": $server_ip, "serverPort": $server_port, "sslFingerPrint": $ssl_finger_print, "useLdaps": $use_ldaps} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Test RADIUS server availability
#
# POST /v4/system/config/actions/test/radius
# operationId: testRadiusConfig
export def "system-config-actions-test-radius test" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/actions/test/radius")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request list of Active Directory configurations
#
# GET /v4/system/config/auth/ads
# operationId: requestAdConfigs
export def "system-config-auth-ads list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<adExportGroup: string, alias: string, createHomeFolder: bool, homeFolderParent: int, id: int, ldapUsersDomain: string, sdsImportGroup: int, serverAdminName: string, serverIp: string, serverPort: int, sslFingerPrint: string, useLdaps: bool, userFilter: string, userImport: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/auth/ads")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Active Directory configuration
#
# POST /v4/system/config/auth/ads
# operationId: createAdConfig
export def "system-config-auth-ads create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --ad-export-group: string # If `userImport` is set to `true`,  the user must be member of this Active Directory group to receive a newly created DRACOON account.
  alias: string # Unique name for an Active Directory configuration
  --create-home-folder: oneof<nothing, bool> # DEPRECATED, will be ignored  Determines whether a room is created for each user that is created by automatic import (like a home folder).  Room's name will equal the user's login name. (default: false)
  --home-folder-parent: int # DEPRECATED, will be ignored  ID of the room in which the individual rooms for users will be created. (format: int64)
  ldap_users_domain: string # Search scope of Active Directory; only users below this node can log on.
  --sds-import-group: int # User group that is assigned to users who are created by automatic import.  Reset with `0` (format: int64)
  server_admin_name: string # Distinguished Name (DN) of Active Directory administrative account
  server_admin_password: string # Password of Active Directory administrative account
  server_ip: string # IPv4 or IPv6 address or host name
  server_port: int # Port (format: int32)
  --ssl-finger-print: string # SSL finger print of Active Directory server.  Mandatory for LDAPS connections.  Format: `Algorithm/Fingerprint`
  --use-ldaps: oneof<nothing, bool> # Determines whether LDAPS should be used instead of plain LDAP. (default: false)
  user_filter: string # Name of Active Directory attribute that is used as login name.
  --user-import: oneof<nothing, bool> # Determines if a DRACOON account is automatically created for a new user  who successfully logs on with his / her AD / IDP account. (default: false)
]: any -> record<adExportGroup: string, alias: string, createHomeFolder: bool, homeFolderParent: int, id: int, ldapUsersDomain: string, sdsImportGroup: int, serverAdminName: string, serverIp: string, serverPort: int, sslFingerPrint: string, useLdaps: bool, userFilter: string, userImport: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/auth/ads")
  let body = {"adExportGroup": $ad_export_group, "alias": $alias, "createHomeFolder": $create_home_folder, "homeFolderParent": $home_folder_parent, "ldapUsersDomain": $ldap_users_domain, "sdsImportGroup": $sds_import_group, "serverAdminName": $server_admin_name, "serverAdminPassword": $server_admin_password, "serverIp": $server_ip, "serverPort": $server_port, "sslFingerPrint": $ssl_finger_print, "useLdaps": $use_ldaps, "userFilter": $user_filter, "userImport": $user_import} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove Active Directory configuration
#
# DELETE /v4/system/config/auth/ads/{ad_id}
# operationId: removeAdConfig
export def "system-config-auth-ads delete" [
  ad_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({ad_id: $ad_id} | format pattern "/v4/system/config/auth/ads/{ad_id}"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request Active Directory configuration
#
# GET /v4/system/config/auth/ads/{ad_id}
# operationId: requestAdConfig
export def "system-config-auth-ads request" [
  ad_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<adExportGroup: string, alias: string, createHomeFolder: bool, homeFolderParent: int, id: int, ldapUsersDomain: string, sdsImportGroup: int, serverAdminName: string, serverIp: string, serverPort: int, sslFingerPrint: string, useLdaps: bool, userFilter: string, userImport: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({ad_id: $ad_id} | format pattern "/v4/system/config/auth/ads/{ad_id}"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Active Directory configuration
#
# PUT /v4/system/config/auth/ads/{ad_id}
# operationId: updateAdConfig
export def "system-config-auth-ads update" [
  ad_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --ad-export-group: string # If `userImport` is set to `true`,  the user must be member of this Active Directory group to receive a newly created DRACOON account.
  --alias: string # Unique name for an Active Directory configuration
  --create-home-folder: oneof<nothing, bool> # DEPRECATED, will be ignored  Determines whether a room is created for each user that is created by automatic import (like a home folder).  Room's name will equal the user's login name. (default: false)
  --home-folder-parent: int # DEPRECATED, will be ignored  ID of the room in which the individual rooms for users will be created. (format: int64)
  --ldap-users-domain: string # Search scope of Active Directory; only users below this node can log on.
  --sds-import-group: int # User group that is assigned to users who are created by automatic import.  Reset with `0` (format: int64)
  --server-admin-name: string # Distinguished Name (DN) of Active Directory administrative account
  --server-admin-password: string # Password of Active Directory administrative account
  --server-ip: string # IPv4 or IPv6 address or host name
  --server-port: int # Port (format: int32)
  --ssl-finger-print: string # SSL finger print of Active Directory server.  Mandatory for LDAPS connections.  Format: `Algorithm/Fingerprint`
  --use-ldaps: oneof<nothing, bool> # Determines whether LDAPS should be used instead of plain LDAP.
  --user-filter: string # Name of Active Directory attribute that is used as login name.
  --user-import: oneof<nothing, bool> # Determines if a DRACOON account is automatically created for a new user  who successfully logs on with his / her AD / IDP account.
]: any -> record<adExportGroup: string, alias: string, createHomeFolder: bool, homeFolderParent: int, id: int, ldapUsersDomain: string, sdsImportGroup: int, serverAdminName: string, serverIp: string, serverPort: int, sslFingerPrint: string, useLdaps: bool, userFilter: string, userImport: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({ad_id: $ad_id} | format pattern "/v4/system/config/auth/ads/{ad_id}"))
  let body = {"adExportGroup": $ad_export_group, "alias": $alias, "createHomeFolder": $create_home_folder, "homeFolderParent": $home_folder_parent, "ldapUsersDomain": $ldap_users_domain, "sdsImportGroup": $sds_import_group, "serverAdminName": $server_admin_name, "serverAdminPassword": $server_admin_password, "serverIp": $server_ip, "serverPort": $server_port, "sslFingerPrint": $ssl_finger_print, "useLdaps": $use_ldaps, "userFilter": $user_filter, "userImport": $user_import} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request list of OpenID Connect IDP configurations
#
# GET /v4/system/config/auth/openid/idps
# Docs: http://openid.net/developers/specs — OpenID Specifications
# operationId: requestOpenIdIdpConfigs
export def "system-config-auth-openid-idps list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> table<authorizationEndPointUrl: string, clientId: string, clientSecret: string, fallbackMappingClaim: string, flow: string, id: int, issuer: string, jwksEndPointUrl: string, mappingClaim: string, name: string, pkceChallengeMethod: string, pkceEnabled: bool, redirectUris: list<string>, scopes: list<string>, tokenEndPointUrl: string, userImportEnabled: bool, userImportGroup: int, userInfoEndPointUrl: string, userInfoSource: string, userManagementUrl: string, userUpdateEnabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/auth/openid/idps")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create OpenID Connect IDP configuration
#
# POST /v4/system/config/auth/openid/idps
# Docs: http://openid.net/developers/specs — OpenID Specifications
# operationId: createOpenIdIdpConfig
export def "system-config-auth-openid-idps create-open" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  authorization_end_point_url: string # URL of the authorization endpoint
  client_id: string # ID of the OpenID client
  client_secret: string # Secret, which client uses at authentication.
  --fallback-mapping-claim: string # Name of the claim which is used for the user mapping fallback.
  --flow: string@flow-completer # &#128640; Since v4.11.0  Flow, which is used at authentication
  issuer: string # Issuer identifier of the IDP  The value is a case sensitive URL.
  jwks_end_point_url: string # URL of the JWKS endpoint
  mapping_claim: string # Name of the claim which is used for the user mapping.
  name: string # Name of the IDP
  --pkce-challenge-method: string # PKCE code challenge method.  cf. [RFC 7636](https://tools.ietf.org/html/rfc7636) (default: plain)
  --pkce-enabled: oneof<nothing, bool> # Determines whether PKCE is enabled.  cf. [RFC 7636](https://tools.ietf.org/html/rfc7636) (default: false)
  redirect_uris: list # URIs, to which a user is redirected after authorization.
  scopes: list # List of requested scopes
  token_end_point_url: string # URL of the token endpoint
  --user-import-enabled: oneof<nothing, bool> # Determines if a DRACOON account is automatically created for a new user  who successfully logs on with his / her AD / IDP account. (default: false)
  --user-import-group: int # User group that is assigned to users who are created by automatic import.  Reset with `0` (format: int64)
  user_info_end_point_url: string # URL of the user info endpoint
  --user-info-source: string@user-info-source-completer # &#128640; Since v4.23.0  Source, which is used to get user information at the import or update of a user.
  --user-management-url: string # URL of the user management UI.  Use empty string to remove.
  --user-update-enabled: oneof<nothing, bool> # Determines if the DRACOON account is updated with data from AD / IDP.  For OpenID Connect, the scopes `email` and `profile` are needed. (default: false)
]: any -> record<authorizationEndPointUrl: string, clientId: string, clientSecret: string, fallbackMappingClaim: string, flow: string, id: int, issuer: string, jwksEndPointUrl: string, mappingClaim: string, name: string, pkceChallengeMethod: string, pkceEnabled: bool, redirectUris: list<string>, scopes: list<string>, tokenEndPointUrl: string, userImportEnabled: bool, userImportGroup: int, userInfoEndPointUrl: string, userInfoSource: string, userManagementUrl: string, userUpdateEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/auth/openid/idps")
  let body = {"authorizationEndPointUrl": $authorization_end_point_url, "clientId": $client_id, "clientSecret": $client_secret, "fallbackMappingClaim": $fallback_mapping_claim, "flow": $flow, "issuer": $issuer, "jwksEndPointUrl": $jwks_end_point_url, "mappingClaim": $mapping_claim, "name": $name, "pkceChallengeMethod": $pkce_challenge_method, "pkceEnabled": $pkce_enabled, "redirectUris": $redirect_uris, "scopes": $scopes, "tokenEndPointUrl": $token_end_point_url, "userImportEnabled": $user_import_enabled, "userImportGroup": $user_import_group, "userInfoEndPointUrl": $user_info_end_point_url, "userInfoSource": $user_info_source, "userManagementUrl": $user_management_url, "userUpdateEnabled": $user_update_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove OpenID Connect IDP configuration
#
# DELETE /v4/system/config/auth/openid/idps/{idp_id}
# Docs: http://openid.net/developers/specs — OpenID Specifications
# operationId: removeOpenIdIdpConfig
export def "system-config-auth-openid-idps delete-open" [
  idp_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({idp_id: $idp_id} | format pattern "/v4/system/config/auth/openid/idps/{idp_id}"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request OpenID Connect IDP configuration
#
# GET /v4/system/config/auth/openid/idps/{idp_id}
# Docs: http://openid.net/developers/specs — OpenID Specifications
# operationId: requestOpenIdIdpConfig
export def "system-config-auth-openid-idps request-open" [
  idp_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<authorizationEndPointUrl: string, clientId: string, clientSecret: string, fallbackMappingClaim: string, flow: string, id: int, issuer: string, jwksEndPointUrl: string, mappingClaim: string, name: string, pkceChallengeMethod: string, pkceEnabled: bool, redirectUris: list<string>, scopes: list<string>, tokenEndPointUrl: string, userImportEnabled: bool, userImportGroup: int, userInfoEndPointUrl: string, userInfoSource: string, userManagementUrl: string, userUpdateEnabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({idp_id: $idp_id} | format pattern "/v4/system/config/auth/openid/idps/{idp_id}"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update OpenID Connect IDP configuration
#
# PUT /v4/system/config/auth/openid/idps/{idp_id}
# Docs: http://openid.net/developers/specs — OpenID Specifications
# operationId: updateOpenIdIdpConfig
export def "system-config-auth-openid-idps update-open" [
  idp_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --authorization-end-point-url: string # URL of the authorization endpoint
  --client-id: string # ID of the OpenID client
  --client-secret: string # Secret, which client uses at authentication.
  --fallback-mapping-claim: string # Name of the claim which is used for the user mapping fallback.
  --flow: string@flow-completer # &#128640; Since v4.11.0  Flow, which is used at authentication
  --issuer: string # Issuer identifier of the IDP  The value is a case sensitive URL.
  --jwks-end-point-url: string # URL of the JWKS endpoint
  --mapping-claim: string # Name of the claim which is used for the user mapping.
  --name: string # Name of the IDP
  --pkce-challenge-method: string # PKCE code challenge method.  cf. [RFC 7636](https://tools.ietf.org/html/rfc7636)
  --pkce-enabled: oneof<nothing, bool> # Determines whether PKCE is enabled.  cf. [RFC 7636](https://tools.ietf.org/html/rfc7636) (default: false)
  --redirect-uris: list # URIs, to which a user is redirected after authorization.
  --reset-fallback-mapping-claim: oneof<nothing, bool> # Set `true` to reset `fallbackMappingClaim`.
  --scopes: list # List of requested scopes  Usually `openid` and the names of the requested claims.
  --token-end-point-url: string # URL of the token endpoint
  --user-import-enabled: oneof<nothing, bool> # Determines if a DRACOON account is automatically created for a new user  who successfully logs on with his / her AD / IDP account. (default: false)
  --user-import-group: int # User group that is assigned to users who are created by automatic import.  Reset with `0` (format: int64)
  --user-info-end-point-url: string # URL of the user info endpoint
  --user-info-source: string@user-info-source-completer # &#128640; Since v4.23.0  Source, which is used to get user information at the import or update of a user.
  --user-management-url: string # URL of the user management UI.  Use empty string to remove.
  --user-update-enabled: oneof<nothing, bool> # Determines if the DRACOON account is updated with data from AD / IDP.  For OpenID Connect, the scopes `email` and `profile` are needed. (default: false)
]: any -> record<authorizationEndPointUrl: string, clientId: string, clientSecret: string, fallbackMappingClaim: string, flow: string, id: int, issuer: string, jwksEndPointUrl: string, mappingClaim: string, name: string, pkceChallengeMethod: string, pkceEnabled: bool, redirectUris: list<string>, scopes: list<string>, tokenEndPointUrl: string, userImportEnabled: bool, userImportGroup: int, userInfoEndPointUrl: string, userInfoSource: string, userManagementUrl: string, userUpdateEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({idp_id: $idp_id} | format pattern "/v4/system/config/auth/openid/idps/{idp_id}"))
  let body = {"authorizationEndPointUrl": $authorization_end_point_url, "clientId": $client_id, "clientSecret": $client_secret, "fallbackMappingClaim": $fallback_mapping_claim, "flow": $flow, "issuer": $issuer, "jwksEndPointUrl": $jwks_end_point_url, "mappingClaim": $mapping_claim, "name": $name, "pkceChallengeMethod": $pkce_challenge_method, "pkceEnabled": $pkce_enabled, "redirectUris": $redirect_uris, "resetFallbackMappingClaim": $reset_fallback_mapping_claim, "scopes": $scopes, "tokenEndPointUrl": $token_end_point_url, "userImportEnabled": $user_import_enabled, "userImportGroup": $user_import_group, "userInfoEndPointUrl": $user_info_end_point_url, "userInfoSource": $user_info_source, "userManagementUrl": $user_management_url, "userUpdateEnabled": $user_update_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove RADIUS configuration
#
# DELETE /v4/system/config/auth/radius
# operationId: removeRadiusConfig
export def "system-config-auth-radius delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/auth/radius")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request RADIUS configuration
#
# GET /v4/system/config/auth/radius
# operationId: requestRadiusConfig
export def "system-config-auth-radius request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<failoverServer: record<failoverEnabled: bool, failoverIpAddress: string, failoverPort: int>, ipAddress: string, otpPinFirst: bool, port: int, sharedSecret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/auth/radius")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create RADIUS configuration
#
# POST /v4/system/config/auth/radius
# operationId: createRadiusConfig
# --failoverServer shape: {failoverEnabled: bool, failoverIpAddress: string, failoverPort: int}
export def "system-config-auth-radius create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --failover-server: record # Failover server information — shape: {failoverEnabled: bool, failoverIpAddress: string, failoverPort: int}
  ip_address: string # RADIUS Server IP Address
  --otp-pin-first: oneof<nothing, bool> # Sequence order of concatenated PIN and one-time token (default: true)
  port: int # RADIUS Server Port (format: int32)
  shared_secret: string # Shared Secret to access the RADIUS server
]: any -> record<failoverServer: record<failoverEnabled: bool, failoverIpAddress: string, failoverPort: int>, ipAddress: string, otpPinFirst: bool, port: int, sharedSecret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/auth/radius")
  let body = {"failoverServer": $failover_server, "ipAddress": $ip_address, "otpPinFirst": $otp_pin_first, "port": $port, "sharedSecret": $shared_secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update RADIUS configuration
#
# PUT /v4/system/config/auth/radius
# operationId: updateRadiusConfig
# --failoverServer shape: {failoverEnabled: bool, failoverIpAddress: string, failoverPort: int}
export def "system-config-auth-radius update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --failover-server: record # Failover server information — shape: {failoverEnabled: bool, failoverIpAddress: string, failoverPort: int}
  --ip-address: string # RADIUS Server IP Address
  --otp-pin-first: oneof<nothing, bool> # Sequence order of concatenated PIN and one-time token (default: true)
  --port: int # RADIUS Server Port (format: int32)
  --shared-secret: string # Shared Secret to access the RADIUS server
]: any -> record<failoverServer: record<failoverEnabled: bool, failoverIpAddress: string, failoverPort: int>, ipAddress: string, otpPinFirst: bool, port: int, sharedSecret: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/auth/radius")
  let body = {"failoverServer": $failover_server, "ipAddress": $ip_address, "otpPinFirst": $otp_pin_first, "port": $port, "sharedSecret": $shared_secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request list of OAuth clients
#
# GET /v4/system/config/oauth/clients
# operationId: requestOAuthClients
export def "system-config-oauth-clients list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter string
  --qp-sort: string # Sort string
  --x-sds-auth-token: string # Authentication token
]: nothing -> table<accessTokenValidity: int, approvalValidity: int, clientId: string, clientName: string, clientSecret: string, clientType: string, grantTypes: list<string>, isEnabled: bool, isExternal: bool, isStandard: bool, redirectUris: list<string>, refreshTokenValidity: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/system/config/oauth/clients" $qp)
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create OAuth client
#
# POST /v4/system/config/oauth/clients
# operationId: createOAuthClient
export def "system-config-oauth-clients create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --access-token-validity: int # Validity of the access token in seconds. (format: int32)
  --approval-validity: int # &#128640; Since v4.22.0  Validity of the approval interval in seconds. (format: int32)
  --client-id: string # ID of the OAuth client
  client_name: string # Name, which is shown at the client configuration and authorization.
  --client-secret: string # Secret, which client uses at authentication.
  --client-type: string@client-type-completer # Determines whether client is a confidential or public client.
  grant_types: list@grant-types-completer # Authorized grant types  * `authorization_code`  * `implicit`  * `password`  * `client_credentials`  * `refresh_token`    cf. [RFC 6749](https://tools.ietf.org/html/rfc6749)
  redirect_uris: list # URIs, to which a user is redirected after authorization.
  --refresh-token-validity: int # Validity of the refresh token in seconds. (format: int32)
]: any -> record<accessTokenValidity: int, approvalValidity: int, clientId: string, clientName: string, clientSecret: string, clientType: string, grantTypes: list<string>, isEnabled: bool, isExternal: bool, isStandard: bool, redirectUris: list<string>, refreshTokenValidity: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/oauth/clients")
  let body = {"accessTokenValidity": $access_token_validity, "approvalValidity": $approval_validity, "clientId": $client_id, "clientName": $client_name, "clientSecret": $client_secret, "clientType": $client_type, "grantTypes": $grant_types, "redirectUris": $redirect_uris, "refreshTokenValidity": $refresh_token_validity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove OAuth client
#
# DELETE /v4/system/config/oauth/clients/{client_id}
# operationId: removeOAuthClient
export def "system-config-oauth-clients delete" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({client_id: $client_id} | format pattern "/v4/system/config/oauth/clients/{client_id}"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request OAuth client
#
# GET /v4/system/config/oauth/clients/{client_id}
# operationId: requestOAuthClient
export def "system-config-oauth-clients request" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<accessTokenValidity: int, approvalValidity: int, clientId: string, clientName: string, clientSecret: string, clientType: string, grantTypes: list<string>, isEnabled: bool, isExternal: bool, isStandard: bool, redirectUris: list<string>, refreshTokenValidity: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({client_id: $client_id} | format pattern "/v4/system/config/oauth/clients/{client_id}"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update OAuth client
#
# PUT /v4/system/config/oauth/clients/{client_id}
# operationId: updateOAuthClient
export def "system-config-oauth-clients update" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --access-token-validity: int # Validity of the access token in seconds. (format: int32)
  --approval-validity: int # &#128640; Since v4.22.0  Validity of the approval interval in seconds. (format: int32)
  --client-name: string # Name, which is shown at the client configuration and authorization.
  --client-secret: string # Secret, which client uses at authentication.
  --client-type: string@client-type-completer # Determines whether client is a confidential or public client.
  grant_types: list@grant-types-completer # Authorized grant types  * `authorization_code`  * `implicit`  * `password`  * `client_credentials`  * `refresh_token`    cf. [RFC 6749](https://tools.ietf.org/html/rfc6749)
  --is-enabled: oneof<nothing, bool> # Determines whether client is enabled.
  --redirect-uris: list # URIs, to which a user is redirected after authorization.
  --refresh-token-validity: int # Validity of the refresh token in seconds. (format: int32)
]: any -> record<accessTokenValidity: int, approvalValidity: int, clientId: string, clientName: string, clientSecret: string, clientType: string, grantTypes: list<string>, isEnabled: bool, isExternal: bool, isStandard: bool, redirectUris: list<string>, refreshTokenValidity: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({client_id: $client_id} | format pattern "/v4/system/config/oauth/clients/{client_id}"))
  let body = {"accessTokenValidity": $access_token_validity, "approvalValidity": $approval_validity, "clientName": $client_name, "clientSecret": $client_secret, "clientType": $client_type, "grantTypes": $grant_types, "isEnabled": $is_enabled, "redirectUris": $redirect_uris, "refreshTokenValidity": $refresh_token_validity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request classification policies
#
# GET /v4/system/config/policies/classifications
# operationId: requestClassificationPoliciesConfig
export def "system-config-policies-classifications request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<shareClassificationPolicies: record<classificationRequiresSharePassword: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/policies/classifications")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change classification policies
#
# PUT /v4/system/config/policies/classifications
# operationId: changeClassificationPoliciesConfig
# --shareClassificationPolicies shape: {classificationRequiresSharePassword?: "0"|"1"|"2"|"3"|"4"}
export def "system-config-policies-classifications changeClassificationPoliciesConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --share-classification-policies: record # Shares classification policies — shape: {classificationRequiresSharePassword?: "0"|"1"|"2"|"3"|"4"}
]: any -> record<shareClassificationPolicies: record<classificationRequiresSharePassword: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/policies/classifications")
  let body = {"shareClassificationPolicies": $share_classification_policies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request guest user policies
#
# GET /v4/system/config/policies/guest_users
# operationId: requestGuestUsersPoliciesConfig
export def "system-config-policies-guest-users request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<isInviteUsersEnabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/policies/guest_users")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change guest user policies
#
# PUT /v4/system/config/policies/guest_users
# operationId: changeGuestUsersPoliciesConfig
export def "system-config-policies-guest-users changeGuestUsersPoliciesConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --is-invite-users-enabled: oneof<nothing, bool> # Determines whether the invite of users to rooms is enabled.
]: any -> record<isInviteUsersEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/policies/guest_users")
  let body = {"isInviteUsersEnabled": $is_invite_users_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request MFA policies
#
# GET /v4/system/config/policies/mfa
# operationId: requestMfaPoliciesConfig
export def "system-config-policies-mfa request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<isMfaEnforced: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/policies/mfa")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change MFA policies
#
# PUT /v4/system/config/policies/mfa
# operationId: changeMfaPoliciesConfig
export def "system-config-policies-mfa changeMfaPoliciesConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --is-mfa-enforced: oneof<nothing, bool> # Determines whether multi-factor authentication is enforced
]: any -> record<isMfaEnforced: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/policies/mfa")
  let body = {"isMfaEnforced": $is_mfa_enforced} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request password policies
#
# GET /v4/system/config/policies/passwords
# operationId: requestPasswordPoliciesConfig
export def "system-config-policies-passwords request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<encryptionPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>, loginPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, numberOfArchivedPasswords: int, passwordExpiration: record<enabled: bool, maxPasswordAge: int>, rejectDictionaryWords: bool, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, userLockout: record<enabled: bool, lockoutPeriod: int, maxNumberOfLoginFailures: int>>, sharesPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, rejectDictionaryWords: bool, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/policies/passwords")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change password policies
#
# PUT /v4/system/config/policies/passwords
# operationId: changePasswordPoliciesConfig
# --encryptionPasswordPolicies shape: {characterRules?: record, minLength?: int, rejectKeyboardPatterns?: bool, rejectUserInfo?: bool}
# --loginPasswordPolicies shape: {characterRules?: record, enforceLoginPasswordChange?: bool, minLength?: int, numberOfArchivedPasswords?: int, passwordExpiration?: record, rejectDictionaryWords?: bool, rejectKeyboardPatterns?: bool, rejectUserInfo?: bool, userLockout?: record}
# --sharesPasswordPolicies shape: {characterRules?: record, minLength?: int, rejectDictionaryWords?: bool, rejectKeyboardPatterns?: bool, rejectUserInfo?: bool}
export def "system-config-policies-passwords changePasswordPoliciesConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --encryption-password-policies: record # Request model for updating encryption password policies — shape: {characterRules?: record, minLength?: int, rejectKeyboardPatterns?: bool, rejectUserInfo?: bool}
  --login-password-policies: record # Request model for updating login password policies — shape: {characterRules?: record, enforceLoginPasswordChange?: bool, minLength?: int, numberOfArchivedPasswords?: int, passwordExpiration?: record, rejectDictionaryWords?: bool, rejectKeyboardPatterns?: bool, rejectUserInfo?: bool, userLockout?: record}
  --shares-password-policies: record # Request model for updating shares password policies — shape: {characterRules?: record, minLength?: int, rejectDictionaryWords?: bool, rejectKeyboardPatterns?: bool, rejectUserInfo?: bool}
]: any -> record<encryptionPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>, loginPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, numberOfArchivedPasswords: int, passwordExpiration: record<enabled: bool, maxPasswordAge: int>, rejectDictionaryWords: bool, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, userLockout: record<enabled: bool, lockoutPeriod: int, maxNumberOfLoginFailures: int>>, sharesPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, rejectDictionaryWords: bool, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/policies/passwords")
  let body = {"encryptionPasswordPolicies": $encryption_password_policies, "loginPasswordPolicies": $login_password_policies, "sharesPasswordPolicies": $shares_password_policies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Enforce login password change for all users
#
# POST /v4/system/config/policies/passwords/enforce_change
# operationId: enforceLoginPasswordChange
export def "system-config-policies-passwords-enforce-change enforceLoginPasswordChange" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/policies/passwords/enforce_change")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request password policies for a certain password type
#
# GET /v4/system/config/policies/passwords/{password_type}
# operationId: requestPasswordPoliciesForPasswordType
export def "system-config-policies-passwords request-password-policies-for-password-type" [
  password_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<encryptionPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>, loginPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, numberOfArchivedPasswords: int, passwordExpiration: record<enabled: bool, maxPasswordAge: int>, rejectDictionaryWords: bool, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, userLockout: record<enabled: bool, lockoutPeriod: int, maxNumberOfLoginFailures: int>>, sharesPasswordPolicies: record<characterRules: record<mustContainCharacters: list, numberOfCharacteristicsToEnforce: int>, minLength: int, rejectDictionaryWords: bool, rejectKeyboardPatterns: bool, rejectUserInfo: bool, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({password_type: $password_type} | format pattern "/v4/system/config/policies/passwords/{password_type}"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request authentication settings
#
# GET /v4/system/config/settings/auth
# operationId: requestAuthConfig
export def "system-config-settings-auth request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<authMethods: table<isEnabled: bool, name: string, priority: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/settings/auth")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update authentication settings
#
# PUT /v4/system/config/settings/auth
# operationId: updateAuthConfig
# --authMethods item shape: {isEnabled: bool, name: string, priority: int}
export def "system-config-settings-auth update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  auth_methods: list # List of authentication methods — item shape: {isEnabled: bool, name: string, priority: int}
]: any -> record<authMethods: table<isEnabled: bool, name: string, priority: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/settings/auth")
  let body = {"authMethods": $auth_methods} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request system defaults
#
# GET /v4/system/config/settings/defaults
# Docs: https://tools.ietf.org/html/rfc5646 — Tags for Identifying Languages
# operationId: requestSystemDefaults
export def "system-config-settings-defaults request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<downloadShareDefaultExpirationPeriod: int, fileDefaultExpirationPeriod: int, hideLoginInputFields: bool, languageDefault: string, nonmemberViewerDefault: bool, uploadShareDefaultExpirationPeriod: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/settings/defaults")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update system defaults
#
# PUT /v4/system/config/settings/defaults
# Docs: https://tools.ietf.org/html/rfc5646 — Tags for Identifying Languages
# operationId: updateSystemDefaults
export def "system-config-settings-defaults update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --download-share-default-expiration-period: int # Default expiration period for Download Shares in days. (format: int32)
  --file-default-expiration-period: int # Default expiration period for all uploaded files in days. (format: int32)
  --language-default: string # Define which language should be default.
  --nonmember-viewer-default: oneof<nothing, bool> # &#128640; Since v4.12.0  Defines if new users get the role Non Member Viewer by default
  --upload-share-default-expiration-period: int # Default expiration period for Upload Shares in days. (format: int32)
]: any -> record<downloadShareDefaultExpirationPeriod: int, fileDefaultExpirationPeriod: int, hideLoginInputFields: bool, languageDefault: string, nonmemberViewerDefault: bool, uploadShareDefaultExpirationPeriod: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/settings/defaults")
  let body = {"downloadShareDefaultExpirationPeriod": $download_share_default_expiration_period, "fileDefaultExpirationPeriod": $file_default_expiration_period, "languageDefault": $language_default, "nonmemberViewerDefault": $nonmember_viewer_default, "uploadShareDefaultExpirationPeriod": $upload_share_default_expiration_period} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request eventlog settings
#
# GET /v4/system/config/settings/eventlog
# operationId: requestEventlogConfig
export def "system-config-settings-eventlog request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<enabled: bool, logIpEnabled: bool, retentionPeriod: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/settings/eventlog")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update eventlog settings
#
# PUT /v4/system/config/settings/eventlog
# operationId: updateEventlogConfig
export def "system-config-settings-eventlog update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --enabled: oneof<nothing, bool> # Is eventlog enabled?
  --log-ip-enabled: oneof<nothing, bool> # Determines whether user’s IP address is logged.
  --retention-period: int # Retention period (in days) of event log entries.  After that period, all entries are deleted.  Recommended value: 7 (format: int32)
]: any -> record<enabled: bool, logIpEnabled: bool, retentionPeriod: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/settings/eventlog")
  let body = {"enabled": $enabled, "logIpEnabled": $log_ip_enabled, "retentionPeriod": $retention_period} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request general settings
#
# GET /v4/system/config/settings/general
# operationId: requestGeneralSettings
export def "system-config-settings-general request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<authTokenRestrictions: record<accessTokenValidity: int, refreshTokenValidity: int, restrictionEnabled: bool>, cryptoEnabled: bool, emailNotificationButtonEnabled: bool, eulaEnabled: bool, hideLoginInputFields: bool, mediaServerEnabled: bool, s3TagsEnabled: bool, sharePasswordSmsEnabled: bool, useS3Storage: bool, weakPasswordEnabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/settings/general")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update general settings
#
# PUT /v4/system/config/settings/general
# operationId: updateGeneralSettings
# --authTokenRestrictions shape: {accessTokenValidity?: int, overwriteEnabled: bool, refreshTokenValidity?: int}
@deprecated --flag hide-login-input-fields
@deprecated --flag media-server-enabled
@deprecated --flag weak-password-enabled
export def "system-config-settings-general update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --auth-token-restrictions: record # Request model for updating auth token settings — shape: {accessTokenValidity?: int, overwriteEnabled: bool, refreshTokenValidity?: int}
  --crypto-enabled: oneof<nothing, bool> # Activation status of client-side encryption.  Can only be enabled once; disabling is not possible.
  --email-notification-button-enabled: oneof<nothing, bool> # Enable email notification button
  --eula-enabled: oneof<nothing, bool> # Each user has to confirm the EULA at first login.
  --hide-login-input-fields: oneof<nothing, bool> # &#128679; Deprecated since v4.13.0  Defines if login fields should be hidden (DEPRECATED)
  --media-server-enabled: oneof<nothing, bool> # &#128679; Deprecated since v4.12.0  Determines if the media server is enabled (DEPRECATED)
  --s3-tags-enabled: oneof<nothing, bool> # &#128640; Since v4.9.0  Defines if S3 tags are enabled
  --share-password-sms-enabled: oneof<nothing, bool> # Allow sending of share passwords via SMS
  --weak-password-enabled: oneof<nothing, bool> # &#128679; Deprecated since v4.14.0  Allow weak password  * A weak password has to fulfill the following criteria:     * is at least 8 characters long     * contains letters and numbers  * A strong password has to fulfill the following criteria in addition:     * contains at least one special character     * contains upper and lower case characters  Please use `PUT /system/config/policies/passwords` API to change configured password policies. (DEPRECATED)
]: any -> record<authTokenRestrictions: record<accessTokenValidity: int, refreshTokenValidity: int, restrictionEnabled: bool>, cryptoEnabled: bool, emailNotificationButtonEnabled: bool, eulaEnabled: bool, hideLoginInputFields: bool, mediaServerEnabled: bool, s3TagsEnabled: bool, sharePasswordSmsEnabled: bool, useS3Storage: bool, weakPasswordEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/settings/general")
  let body = {"authTokenRestrictions": $auth_token_restrictions, "cryptoEnabled": $crypto_enabled, "emailNotificationButtonEnabled": $email_notification_button_enabled, "eulaEnabled": $eula_enabled, "hideLoginInputFields": $hide_login_input_fields, "mediaServerEnabled": $media_server_enabled, "s3TagsEnabled": $s3_tags_enabled, "sharePasswordSmsEnabled": $share_password_sms_enabled, "weakPasswordEnabled": $weak_password_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request infrastructure properties
#
# GET /v4/system/config/settings/infrastructure
# operationId: requestInfrastructureProperties
export def "system-config-settings-infrastructure request-infrastructure-properties" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<isDracoonCloud: bool, mediaServerConfigEnabled: bool, s3DefaultRegion: string, s3EnforceDirectUpload: bool, smsConfigEnabled: bool, tenantUuid: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/settings/infrastructure")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request syslog settings
#
# GET /v4/system/config/settings/syslog
# operationId: requestSyslogConfig
export def "system-config-settings-syslog request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<enabled: bool, host: string, logIpEnabled: bool, port: int, protocol: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/settings/syslog")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update syslog settings
#
# PUT /v4/system/config/settings/syslog
# operationId: updateSyslogConfig
export def "system-config-settings-syslog update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --enabled: oneof<nothing, bool> # Is syslog enabled?
  --host: string # Syslog server (IP or FQDN)
  --log-ip-enabled: oneof<nothing, bool> # Determines whether user’s IP address is logged.
  --port: int # Syslog server port (format: int32)
  --protocol: string@protocol-completer # Protocol to connect to syslog server
]: any -> record<enabled: bool, host: string, logIpEnabled: bool, port: int, protocol: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/settings/syslog")
  let body = {"enabled": $enabled, "host": $host, "logIpEnabled": $log_ip_enabled, "port": $port, "protocol": $protocol} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request S3 storage configuration
#
# GET /v4/system/config/storage/s3
# operationId: request3Config
export def "system-config-storage-s3 request3Config" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<accessKeyDefined: bool, bucketName: string, bucketUrl: string, endpointUrl: string, region: string, secretKeyDefined: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/storage/s3")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create S3 storage configuration
#
# POST /v4/system/config/storage/s3
# operationId: createS3Config
@deprecated --flag bucket-name
@deprecated --flag endpoint-url
export def "system-config-storage-s3 create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  access_key: string # Access Key ID
  --bucket-name: string # &#128679; Deprecated since v4.24.0  S3 bucket name  use `bucketUrl` instead (DEPRECATED)
  --bucket-url: string # S3 object storage bucket URL
  --endpoint-url: string # &#128679; Deprecated since v4.24.0  S3 object storage endpoint URL  use `bucketUrl` instead (DEPRECATED)
  --region: string # S3 region
  secret_key: string # Secret Access Key
]: any -> record<accessKeyDefined: bool, bucketName: string, bucketUrl: string, endpointUrl: string, region: string, secretKeyDefined: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/storage/s3")
  let body = {"accessKey": $access_key, "bucketName": $bucket_name, "bucketUrl": $bucket_url, "endpointUrl": $endpoint_url, "region": $region, "secretKey": $secret_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update S3 storage configuration
#
# PUT /v4/system/config/storage/s3
# operationId: updateS3Config
@deprecated --flag bucket-name
@deprecated --flag endpoint-url
export def "system-config-storage-s3 update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --access-key: string # Access Key ID
  --bucket-name: string # &#128679; Deprecated since v4.24.0  S3 bucket name  use `bucketUrl` instead (DEPRECATED)
  --bucket-url: string # S3 object storage bucket URL
  --endpoint-url: string # &#128679; Deprecated since v4.24.0  S3 object storage endpoint URL  use `bucketUrl` instead (DEPRECATED)
  --region: string # S3 region
  --secret-key: string # Secret Access Key
]: any -> record<accessKeyDefined: bool, bucketName: string, bucketUrl: string, endpointUrl: string, region: string, secretKeyDefined: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/storage/s3")
  let body = {"accessKey": $access_key, "bucketName": $bucket_name, "bucketUrl": $bucket_url, "endpointUrl": $endpoint_url, "region": $region, "secretKey": $secret_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request list of configured S3 tags
#
# GET /v4/system/config/storage/s3/tags
# operationId: requestS3TagList
export def "system-config-storage-s3-tags request-s3-tag-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<id: int, isMandatory: bool, key: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/storage/s3/tags")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create S3 tag
#
# POST /v4/system/config/storage/s3/tags
# operationId: createS3Tag
export def "system-config-storage-s3-tags create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --is-mandatory: oneof<nothing, bool> # Determines whether S3 is mandatory or not (default: false)
  key: string # S3 tag key
  value: string # S3 tag value
]: any -> record<id: int, isMandatory: bool, key: string, value: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/system/config/storage/s3/tags")
  let body = {"isMandatory": $is_mandatory, "key": $key, "value": $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove S3 tag
#
# DELETE /v4/system/config/storage/s3/tags/{id}
# operationId: removeS3Tag
export def "system-config-storage-s3-tags delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v4/system/config/storage/s3/tags/{id}"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request S3 tag
#
# GET /v4/system/config/storage/s3/tags/{id}
# operationId: requestS3Tag
export def "system-config-storage-s3-tags request" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<id: int, isMandatory: bool, key: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v4/system/config/storage/s3/tags/{id}"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel file upload
#
# DELETE /v4/uploads/{token}
# operationId: cancelFileUploadByToken
export def "uploads cancel-file" [
  token_arg: string
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
  let full_url = (build-url $base ({token_arg: $token_arg} | format pattern "/v4/uploads/{token_arg}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload file
#
# POST /v4/uploads/{token}
# Docs: https://tools.ietf.org/html/rfc7233 — Range Requests
# operationId: uploadFileByTokenAsMultipart_1
export def "uploads upload-file-by-token" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --content-range: string # Content-Range   e.g. `bytes 0-999/3980`
  file: string # File (format: binary)
]: any -> record<hash: string, size: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({token_arg: $token_arg} | format pattern "/v4/uploads/{token_arg}"))
  let body = {"file": $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Content-Range": $content_range} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Complete file upload
#
# PUT /v4/uploads/{token}
# operationId: completeFileUploadByToken
# --fileKey shape: {iv: string, key: string, tag: string, version: string}
# --userFileKeyList shape: {items?: list}
@deprecated --flag user-file-key-list
export def "uploads completeFileUploadByToken" [
  token_arg: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --file-key: record # File key information — shape: {iv: string, key: string, tag: string, version: string}
  --file-name: string # New file name to store with
  --keep-share-links: oneof<nothing, bool> # Preserve Download Share Links and point them to the new node. (default: false)
  --resolution-strategy: string@resolution-strategy-completer # Node conflict resolution strategy:  * `autorename`  * `overwrite`  * `fail` (default: autorename)
  --user-file-key-list: record # Mandatory for encrypted shares (DEPRECATED) — shape: {items?: list}
]: any -> record<authParentId: int, branchVersion: int, children: list<any>, classification: int, cntChildren: int, cntComments: int, cntDeletedVersions: int, cntDownloadShares: int, cntFiles: int, cntFolders: int, cntRooms: int, cntUploadShares: int, createdAt: string, createdBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>, encryptionInfo: record<dataSpaceKeyState: string, roomKeyState: string, userKeyState: string>, expireAt: string, fileType: string, hasActivitiesLog: bool, hash: string, id: int, inheritPermissions: bool, isBrowsable: bool, isEncrypted: bool, isFavorite: bool, mediaToken: string, mediaType: string, name: string, notes: string, parentId: int, parentPath: string, permissions: record<change: bool, create: bool, delete: bool, deleteRecycleBin: bool, manage: bool, manageDownloadShare: bool, manageUploadShare: bool, read: bool, readRecycleBin: bool, restoreRecycleBin: bool>, quota: int, recycleBinRetentionPeriod: int, referenceId: int, size: int, timestampCreation: string, timestampModification: string, type: string, updatedAt: string, updatedBy: record<avatarUuid: string, displayName: string, email: string, firstName: string, id: int, lastName: string, title: string, userName: string, userType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({token_arg: $token_arg} | format pattern "/v4/uploads/{token_arg}"))
  let body = {"fileKey": $file_key, "fileName": $file_name, "keepShareLinks": $keep_share_links, "resolutionStrategy": $resolution_strategy, "userFileKeyList": $user_file_key_list} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request user account information
#
# GET /v4/user/account
# operationId: requestUserInfo
export def "user-account request-user-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --more-info: oneof<nothing, bool> # Get more info for this user  e.g. list of user groups
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<authData: record<adConfigId: int, login: string, method: string, mustChangePassword: bool, oidConfigId: int, password: string>, authMethods: table<authId: string, isEnabled: bool, options: list>, email: string, expireAt: string, firstName: string, gender: string, hasManageableRooms: bool, homeRoomId: int, id: int, isEncryptionEnabled: bool, isLocked: bool, language: string, lastLoginFailAt: string, lastLoginFailIp: string, lastLoginSuccessAt: string, lastLoginSuccessIp: string, lastName: string, lockStatus: int, login: string, mustSetEmail: bool, needsToAcceptEULA: bool, needsToChangePassword: bool, needsToChangeUserName: bool, phone: string, title: string, userAttributes: record<items: list<record>>, userGroups: table<id: int, isMember: bool, name: string>, userName: string, userRoles: record<items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "more_info" $more_info "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/user/account" $qp)
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update user account
#
# PUT /v4/user/account
# operationId: updateUserAccount
@deprecated --flag gender
@deprecated --flag login
@deprecated --flag title
export def "user-account update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --accept-eula: oneof<nothing, bool> # Accept EULA  Present, if EULA is system global active.  cf. `GET system/config/settings/general` - `eulaEnabled`  If accepted can not be undone.
  --email: string # Email 
  --first-name: string # User first name
  --gender: string # &#128679; Deprecated since v4.12.0  Gender  Do NOT use `gender`! It will be ignored. (DEPRECATED, default: n)
  --language: string # &#128640; Since v4.20.0  IETF language tag
  --last-name: string # User last name
  --login: string # &#128679; Deprecated since v4.13.0  User login name (DEPRECATED)
  --phone: string # Phone number
  --title: string # &#128679; Deprecated since v4.18.0  Job title (DEPRECATED)
  --user-name: string # &#128640; Since v4.13.0  Username
]: any -> record<authData: record<adConfigId: int, login: string, method: string, mustChangePassword: bool, oidConfigId: int, password: string>, authMethods: table<authId: string, isEnabled: bool, options: list>, email: string, expireAt: string, firstName: string, gender: string, hasManageableRooms: bool, homeRoomId: int, id: int, isEncryptionEnabled: bool, isLocked: bool, language: string, lastLoginFailAt: string, lastLoginFailIp: string, lastLoginSuccessAt: string, lastLoginSuccessIp: string, lastName: string, lockStatus: int, login: string, mustSetEmail: bool, needsToAcceptEULA: bool, needsToChangePassword: bool, needsToChangeUserName: bool, phone: string, title: string, userAttributes: record<items: list<record>>, userGroups: table<id: int, isMember: bool, name: string>, userName: string, userRoles: record<items: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/user/account")
  let body = {"acceptEULA": $accept_eula, "email": $email, "firstName": $first_name, "gender": $gender, "language": $language, "lastName": $last_name, "login": $login, "phone": $phone, "title": $title, "userName": $user_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reset avatar
#
# DELETE /v4/user/account/avatar
# operationId: resetAvatar
export def "user-account-avatar reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<avatarUri: string, avatarUuid: string, isCustomAvatar: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/user/account/avatar")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request avatar
#
# GET /v4/user/account/avatar
# operationId: requestAvatar
export def "user-account-avatar request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<avatarUri: string, avatarUuid: string, isCustomAvatar: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/user/account/avatar")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change avatar
#
# POST /v4/user/account/avatar
# operationId: uploadAvatarAsMultipart
export def "user-account-avatar upload-avatar-as-multipart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  file: string # File (format: binary)
]: any -> record<avatarUri: string, avatarUuid: string, isCustomAvatar: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/user/account/avatar")
  let body = {"file": $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Request customer information for user
#
# GET /v4/user/account/customer
# operationId: requestCustomerInfo
export def "user-account-customer request-customer-info" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<accountsLimit: int, accountsUsed: int, cntGuestUser: int, cntInternalUser: int, customerEncryptionEnabled: bool, id: int, isProviderCustomer: bool, name: string, spaceLimit: int, spaceUsed: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/user/account/customer")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Activate client-side encryption for customer
#
# PUT /v4/user/account/customer
# DEPRECATED
# operationId: enableCustomerEncryption
# --dataSpaceRescueKey shape: {privateKeyContainer: record, publicKeyContainer: record}
@deprecated
export def "user-account-customer enable-customer-encryption" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  data_space_rescue_key: record # Key pair container — shape: {privateKeyContainer: record, publicKeyContainer: record}
  --enable-customer-encryption: oneof<nothing, bool> # Set `true` to enable encryption for this customer
]: any -> record<accountsLimit: int, accountsUsed: int, cntGuestUser: int, cntInternalUser: int, customerEncryptionEnabled: bool, id: int, isProviderCustomer: bool, name: string, spaceLimit: int, spaceUsed: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/user/account/customer")
  let body = {"dataSpaceRescueKey": $data_space_rescue_key, "enableCustomerEncryption": $enable_customer_encryption} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request customer's key pair
#
# GET /v4/user/account/customer/keypair
# DEPRECATED
# operationId: requestCustomerKeyPair
@deprecated
export def "user-account-customer-keypair request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<privateKeyContainer: record<createdAt: string, createdBy: int, privateKey: string, version: string>, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/user/account/customer/keypair")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove user's key pair
#
# DELETE /v4/user/account/keypair
# operationId: removeUserKeyPair
export def "user-account-keypair delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # Version (NEW)
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/user/account/keypair" $qp)
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request user's key pair
#
# GET /v4/user/account/keypair
# operationId: requestUserKeyPair
export def "user-account-keypair request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --version: string # Version (NEW)
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<privateKeyContainer: record<createdAt: string, createdBy: int, privateKey: string, version: string>, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "version" $version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/user/account/keypair" $qp)
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set user's key pair
#
# POST /v4/user/account/keypair
# operationId: setUserKeyPair
# --privateKeyContainer shape: {createdAt?: string, createdBy?: int, privateKey: string, version: string}
# --publicKeyContainer shape: {createdAt?: string, createdBy?: int, publicKey: string, version: string}
export def "user-account-keypair setUserKeyPair" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  private_key_container: record # Private key container — shape: {createdAt?: string, createdBy?: int, privateKey: string, version: string}
  public_key_container: record # Public key container — shape: {createdAt?: string, createdBy?: int, publicKey: string, version: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/user/account/keypair")
  let body = {"privateKeyContainer": $private_key_container, "publicKeyContainer": $public_key_container} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request all user key pairs
#
# GET /v4/user/account/keypairs
# operationId: requestUserKeyPairs
export def "user-account-keypairs request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> table<privateKeyContainer: record<createdAt: string, createdBy: int, privateKey: string, version: string>, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/user/account/keypairs")
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create key pair and preserve copy of old private key
#
# POST /v4/user/account/keypairs
# operationId: createAndPreserveUserKeyPair
# --previousPrivateKey shape: {createdAt?: string, createdBy?: int, privateKey: string, version: string}
# --privateKeyContainer shape: {createdAt?: string, createdBy?: int, privateKey: string, version: string}
# --publicKeyContainer shape: {createdAt?: string, createdBy?: int, publicKey: string, version: string}
export def "user-account-keypairs create-and-preserve" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  previous_private_key: record # Private key container — shape: {createdAt?: string, createdBy?: int, privateKey: string, version: string}
  private_key_container: record # Private key container — shape: {createdAt?: string, createdBy?: int, privateKey: string, version: string}
  public_key_container: record # Public key container — shape: {createdAt?: string, createdBy?: int, publicKey: string, version: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/user/account/keypairs")
  let body = {"previousPrivateKey": $previous_private_key, "privateKeyContainer": $private_key_container, "publicKeyContainer": $public_key_container} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Using emergency-code
#
# DELETE /v4/user/account/mfa
# operationId: useEmergencyCode
export def "user-account-mfa useEmergencyCode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --emergency-code: string
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "emergency_code" $emergency_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/user/account/mfa" $qp)
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request information about the user's mfa status
#
# GET /v4/user/account/mfa
# operationId: getMfaStatusForUser
export def "user-account-mfa get-mfa-status-for" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<mfaEnforced: bool, mfaSetups: table<createdAt: string, id: int, mfaType: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/user/account/mfa")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request information to setup TOTP as second authentication factor
#
# GET /v4/user/account/mfa/totp
# operationId: getTotpSetupInformation
export def "user-account-mfa-totp get-totp-setup-information" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<id: int, otpUri: string, qrCode: string, secret: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/user/account/mfa/totp")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Confirm second factor TOTP setup with a generated OTP
#
# POST /v4/user/account/mfa/totp
# operationId: confirmTotpSetup
export def "user-account-mfa-totp confirmTotpSetup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  id: int # ID (format: int64)
  otp: string # Generated valid OTP
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/user/account/mfa/totp")
  let body = {"id": $id, "otp": $otp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disable a MFA TOTP setup with generated OTP
#
# DELETE /v4/user/account/mfa/totp/{id}
# operationId: deleteMfaTotpSetup
export def "user-account-mfa-totp delete-mfa-totp-setup" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --valid-otp: string
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "valid_otp" $valid_otp "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/v4/user/account/mfa/totp/{id}") $qp)
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change user's password
#
# PUT /v4/user/account/password
# operationId: changeUserPassword
export def "user-account-password changeUserPassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  new_password: string # New password
  old_password: string # Old password
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/user/account/password")
  let body = {"newPassword": $new_password, "oldPassword": $old_password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Invalidate authentication token
#
# POST /v4/user/logout
# DEPRECATED
# operationId: logout
@deprecated
export def "user-logout logout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --everywhere: oneof<nothing, bool> # Invalidate all tokens
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "everywhere" $everywhere "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/user/logout" $qp)
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request list of notification configurations
#
# GET /v4/user/notifications/config
# operationId: requestListOfNotificationConfigs
export def "user-notifications-config request-list-of" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<channelIds: list, eventTypeName: string, id: int, scopeId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/user/notifications/config")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update notification configuration
#
# PUT /v4/user/notifications/config/{id}
# operationId: updateNotificationConfig
export def "user-notifications-config update" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  channel_ids: list # List of notification channel IDs.  Leave empty to disable notifications.
]: any -> record<channelIds: list<int>, eventTypeName: string, id: int, scopeId: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/v4/user/notifications/config/{id}"))
  let body = {"channelIds": $channel_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request list of OAuth client approvals
#
# GET /v4/user/oauth/approvals
# operationId: requestOAuthApprovals
export def "user-oauth-approvals request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-sort: string # Sort string
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> table<clientId: string, clientName: string, expiresAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/user/oauth/approvals" $qp)
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove OAuth client approval
#
# DELETE /v4/user/oauth/approvals/{client_id}
# operationId: removeOAuthApproval
export def "user-oauth-approvals delete" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({client_id: $client_id} | format pattern "/v4/user/oauth/approvals/{client_id}"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request list of OAuth client authorizations
#
# GET /v4/user/oauth/authorizations
# operationId: requestOAuthAuthorizations
export def "user-oauth-authorizations request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter string
  --qp-sort: string # Sort string
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> table<clientId: string, clientName: string, createdAt: string, expiresAt: string, id: int, isCurrentAuthorization: bool, isStandard: bool, usedAt: string, userAgentCategory: string, userAgentInfo: string, userAgentOs: string, userAgentType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/user/oauth/authorizations" $qp)
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove all OAuth authorizations of a client
#
# DELETE /v4/user/oauth/authorizations/{client_id}
# operationId: removeOAuthAuthorizations
export def "user-oauth-authorizations delete-by-client_id" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({client_id: $client_id} | format pattern "/v4/user/oauth/authorizations/{client_id}"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a OAuth authorization
#
# DELETE /v4/user/oauth/authorizations/{client_id}/{authorization_id}
# operationId: removeOAuthAuthorization
export def "user-oauth-authorizations delete-by-client_id-authorization_id" [
  client_id: string
  authorization_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({client_id: $client_id, authorization_id: $authorization_id} | format pattern "/v4/user/oauth/authorizations/{client_id}/{authorization_id}"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# (authenticated) Ping
#
# GET /v4/user/ping
# operationId: pingUser
export def "user-ping ping" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/user/ping")
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request user profile attributes
#
# GET /v4/user/profileAttributes
# operationId: requestProfileAttributes
export def "user-profile-attributes request" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --qp-sort: string # Sort string
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<key: string, value: string>, range: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/user/profileAttributes" $qp)
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set user profile attributes
#
# POST /v4/user/profileAttributes
# DEPRECATED
# operationId: setProfileAttributes
# --items item shape: {key: string, value: string}
@deprecated
export def "user-profile-attributes setProfileAttributes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  items: list # List of key-value pairs — item shape: {key: string, value: string}
]: any -> record<items: table<key: string, value: string>, range: record<limit: int, offset: int, total: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/user/profileAttributes")
  let body = {"items": $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add or edit user profile attributes
#
# PUT /v4/user/profileAttributes
# operationId: updateProfileAttributes
# --items item shape: {key: string, value: string}
export def "user-profile-attributes update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  items: list # List of key-value pairs — item shape: {key: string, value: string}
]: any -> record<items: table<key: string, value: string>, range: record<limit: int, offset: int, total: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/user/profileAttributes")
  let body = {"items": $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove user profile attribute
#
# DELETE /v4/user/profileAttributes/{key}
# operationId: removeProfileAttribute
export def "user-profile-attributes delete" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({key: $key} | format pattern "/v4/user/profileAttributes/{key}"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Download Share subscriptions
#
# GET /v4/user/subscriptions/download_shares
# operationId: listDownloadShareSubscriptions
export def "user-subscriptions-download-shares list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter string
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --offset: int # Range offset (format: int32)
  --qp-sort: string # Sort string
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<authParentId: int, id: int>, range: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/user/subscriptions/download_shares" $qp)
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Subscribe or Unsubscribe a List of Download Shares for notifications
#
# PUT /v4/user/subscriptions/download_shares
# operationId: subscribeDownloadShares
export def "user-subscriptions-download-shares subscribe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --is-subscribed: oneof<nothing, bool> # Creates or deletes a subscription on each item in an array of objects.
  object_ids: list # List of ids
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/user/subscriptions/download_shares")
  let body = {"isSubscribed": $is_subscribed, "objectIds": $object_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unsubscribe Download Share from notifications
#
# DELETE /v4/user/subscriptions/download_shares/{share_id}
# operationId: unsubscribeDownloadShare
export def "user-subscriptions-download-shares unsubscribe" [
  share_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({share_id: $share_id} | format pattern "/v4/user/subscriptions/download_shares/{share_id}"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Subscribe Download Share for notifications
#
# POST /v4/user/subscriptions/download_shares/{share_id}
# operationId: subscribeDownloadShare
export def "user-subscriptions-download-shares subscribe-by-share_id" [
  share_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<authParentId: int, id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({share_id: $share_id} | format pattern "/v4/user/subscriptions/download_shares/{share_id}"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List node subscriptions
#
# GET /v4/user/subscriptions/nodes
# operationId: listNodeSubscriptions
export def "user-subscriptions-nodes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter string
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --offset: int # Range offset (format: int32)
  --qp-sort: string # Sort string
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<authParentId: int, id: int, type: string>, range: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/user/subscriptions/nodes" $qp)
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Subscribe or Unsubscribe a List of nodes for notifications
#
# PUT /v4/user/subscriptions/nodes
# operationId: updateNodeSubscriptions
export def "user-subscriptions-nodes update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --is-subscribed: oneof<nothing, bool> # Creates or deletes a subscription on each item in an array of objects.
  object_ids: list # List of ids
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/user/subscriptions/nodes")
  let body = {"isSubscribed": $is_subscribed, "objectIds": $object_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unsubscribe node from notifications
#
# DELETE /v4/user/subscriptions/nodes/{node_id}
# operationId: unsubscribeNode
export def "user-subscriptions-nodes unsubscribe" [
  node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({node_id: $node_id} | format pattern "/v4/user/subscriptions/nodes/{node_id}"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Subscribe node for notifications
#
# POST /v4/user/subscriptions/nodes/{node_id}
# operationId: subscribeNode
export def "user-subscriptions-nodes subscribe" [
  node_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<authParentId: int, id: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({node_id: $node_id} | format pattern "/v4/user/subscriptions/nodes/{node_id}"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List Upload Share subscriptions
#
# GET /v4/user/subscriptions/upload_shares
# operationId: listUploadShareSubscriptions
export def "user-subscriptions-upload-shares list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter string
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --offset: int # Range offset (format: int32)
  --qp-sort: string # Sort string
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<id: int, targetNodeId: int>, range: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/user/subscriptions/upload_shares" $qp)
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Subscribe or Unsubscribe a List of Upload Shares for notifications
#
# PUT /v4/user/subscriptions/upload_shares
# operationId: subscribeUploadShares
export def "user-subscriptions-upload-shares subscribe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
  --is-subscribed: oneof<nothing, bool> # Creates or deletes a subscription on each item in an array of objects.
  object_ids: list # List of ids
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/user/subscriptions/upload_shares")
  let body = {"isSubscribed": $is_subscribed, "objectIds": $object_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unsubscribe Upload Share from notifications
#
# DELETE /v4/user/subscriptions/upload_shares/{share_id}
# operationId: unsubscribeUploadShare
export def "user-subscriptions-upload-shares unsubscribe" [
  share_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({share_id: $share_id} | format pattern "/v4/user/subscriptions/upload_shares/{share_id}"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Subscribe Upload Share for notifications
#
# POST /v4/user/subscriptions/upload_shares/{share_id}
# operationId: subscribeUploadShare
export def "user-subscriptions-upload-shares subscribe-by-share_id" [
  share_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<id: int, targetNodeId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({share_id: $share_id} | format pattern "/v4/user/subscriptions/upload_shares/{share_id}"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request users
#
# GET /v4/users
# operationId: requestUsers
export def "users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --qp-sort: string # Sort string
  --include-attributes: oneof<nothing, bool> # Include custom user attributes.
  --include-roles: oneof<nothing, bool> # Include roles
  --include-manageable-rooms: oneof<nothing, bool> # Include hasManageableRooms (deprecated)
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<avatarUuid: string, createdAt: string, email: string, expireAt: string, firstName: string, gender: string, hasManageableRooms: bool, homeRoomId: int, id: int, isEncryptionEnabled: bool, isLocked: bool, lastLoginSuccessAt: string, lastName: string, lockStatus: int, login: string, phone: string, title: string, userAttributes: record, userName: string, userRoles: record>, range: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "include_attributes" $include_attributes "scalar") (serialize-qp "include_roles" $include_roles "scalar") (serialize-qp "include_manageable_rooms" $include_manageable_rooms "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v4/users" $qp)
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new user
#
# POST /v4/users
# operationId: createUser
# --authData shape: {adConfigId?: int, login?: string, method: string, mustChangePassword?: bool, oidConfigId?: int, password?: string}
# --authMethods item shape: {authId: string, isEnabled: bool, options?: list}
# --expiration shape: {enableExpiration: bool, expireAt?: string}
# --mfaConfig shape: {mfaEnforced?: bool}
@deprecated --flag auth-methods
@deprecated --flag gender
@deprecated --flag login
@deprecated --flag needs-to-change-password
@deprecated --flag password
@deprecated --flag title
export def "users create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --auth-data: record # User Authentication Data — shape: {adConfigId?: int, login?: string, method: string, mustChangePassword?: bool, oidConfigId?: int, password?: string}
  --auth-methods: list # &#128679; Deprecated since v4.13.0  Authentication methods:  * `sql`  * `active_directory`  * `radius`  * `openid`  use `authData` instead (DEPRECATED) — item shape: {authId: string, isEnabled: bool, options?: list}
  --email: string # Email 
  --expiration: record # Expiration information — shape: {enableExpiration: bool, expireAt?: string}
  first_name: string # User first name
  --gender: string # &#128679; Deprecated since v4.12.0  Gender  Do NOT use `gender`! It will be ignored. (DEPRECATED, default: n)
  --is-nonmember-viewer: oneof<nothing, bool> # &#128640; Since v4.12.0  Determines whether user has the role NONMEMBER_VIEWER
  last_name: string # User last name
  --login: string # &#128679; Deprecated since v4.13.0  User login name (DEPRECATED)
  --mfa-config: record # Multi-factor authentication configuration — shape: {mfaEnforced?: bool}
  --needs-to-change-password: oneof<nothing, bool> # &#128679; Deprecated since v4.13.0  Determines whether user has to change his / her initial password.  use `authDate.mustChangePassword` instead (DEPRECATED)
  --notify-user: oneof<nothing, bool> # &#128640; Since v4.9.0  Notify user about his new account  * default: `true` for `basic` auth type  * default: `false` for `active_directory`, `openid` and `radius` auth types
  --password: string # &#128679; Deprecated since v4.13.0  An initial password may be preset  use `authData` instead (DEPRECATED)
  --phone: string # Phone number
  --receiver-language: string # IETF language tag
  --title: string # &#128679; Deprecated since v4.18.0  Job title (DEPRECATED)
  --user-name: string # &#128640; Since v4.13.0  Username
]: any -> record<authData: record<adConfigId: int, login: string, method: string, mustChangePassword: bool, oidConfigId: int, password: string>, authMethods: table<authId: string, isEnabled: bool, options: list>, avatarUuid: string, email: string, expireAt: string, firstName: string, gender: string, hasManageableRooms: bool, homeRoomId: int, id: int, isEncryptionEnabled: bool, isLocked: bool, isMfaEnabled: bool, isMfaEnforced: bool, lastLoginSuccessAt: string, lastName: string, lockStatus: int, login: string, phone: string, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>, title: string, userAttributes: record<items: list<record>>, userName: string, userRoles: record<items: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v4/users")
  let body = {"authData": $auth_data, "authMethods": $auth_methods, "email": $email, "expiration": $expiration, "firstName": $first_name, "gender": $gender, "isNonmemberViewer": $is_nonmember_viewer, "lastName": $last_name, "login": $login, "mfaConfig": $mfa_config, "needsToChangePassword": $needs_to_change_password, "notifyUser": $notify_user, "password": $password, "phone": $phone, "receiverLanguage": $receiver_language, "title": $title, "userName": $user_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove user
#
# DELETE /v4/users/{user_id}
# operationId: removeUser
export def "users delete" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/v4/users/{user_id}"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request user
#
# GET /v4/users/{user_id}
# operationId: requestUser
export def "users request" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --effective-roles: oneof<nothing, bool> # Filter users with DIRECT or DIRECT **AND** EFFECTIVE roles.  * `false`: DIRECT roles  * `true`: DIRECT **AND** EFFECTIVE roles  DIRECT means: e.g. user gets role **directly** granted from someone with _grant permission_ right.  EFFECTIVE means: e.g. user gets role through **group membership**.
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<authData: record<adConfigId: int, login: string, method: string, mustChangePassword: bool, oidConfigId: int, password: string>, authMethods: table<authId: string, isEnabled: bool, options: list>, avatarUuid: string, email: string, expireAt: string, firstName: string, gender: string, hasManageableRooms: bool, homeRoomId: int, id: int, isEncryptionEnabled: bool, isLocked: bool, isMfaEnabled: bool, isMfaEnforced: bool, lastLoginSuccessAt: string, lastName: string, lockStatus: int, login: string, phone: string, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>, title: string, userAttributes: record<items: list<record>>, userName: string, userRoles: record<items: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "effective_roles" $effective_roles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/v4/users/{user_id}") $qp)
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update user's metadata
#
# PUT /v4/users/{user_id}
# operationId: updateUser
# --authData shape: {adConfigId?: int, login?: string, method?: string, oidConfigId?: int}
# --authMethods item shape: {authId: string, isEnabled: bool, options?: list}
# --expiration shape: {enableExpiration: bool, expireAt?: string}
# --mfaConfig shape: {mfaEnforced?: bool}
@deprecated --flag auth-methods
@deprecated --flag gender
@deprecated --flag lock-status
@deprecated --flag title
export def "users update" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  --auth-data: record # User Authentication Data Update Request — shape: {adConfigId?: int, login?: string, method?: string, oidConfigId?: int}
  --auth-methods: list # &#128679; Deprecated since v4.13.0  Authentication methods:  * `sql`  * `active_directory`  * `radius`  * `openid`  use `authData` instead (DEPRECATED) — item shape: {authId: string, isEnabled: bool, options?: list}
  --email: string # Email 
  --expiration: record # Expiration information — shape: {enableExpiration: bool, expireAt?: string}
  --first-name: string # User first name
  --gender: string # &#128679; Deprecated since v4.12.0  Gender  Do NOT use `gender`! It will be ignored. (DEPRECATED, default: n)
  --is-locked: oneof<nothing, bool> # User is locked:  * `false` - unlocked  * `true` - locked    User is locked and can not login anymore. (default: false)
  --last-name: string # User last name
  --lock-status: int # &#128679; Deprecated since v4.7.0  User lock status:  * `0` - locked  * `1` - Web access allowed  * `2` - Web and mobile access allowed    Please use `isLocked` instead. (DEPRECATED, format: int32)
  --mfa-config: record # Multi-factor authentication configuration — shape: {mfaEnforced?: bool}
  --phone: string # Phone number
  --receiver-language: string # IETF language tag
  --title: string # &#128679; Deprecated since v4.18.0  Job title (DEPRECATED)
  --user-name: string # &#128640; Since v4.13.0  Username
]: any -> record<authData: record<adConfigId: int, login: string, method: string, mustChangePassword: bool, oidConfigId: int, password: string>, authMethods: table<authId: string, isEnabled: bool, options: list>, avatarUuid: string, email: string, expireAt: string, firstName: string, gender: string, hasManageableRooms: bool, homeRoomId: int, id: int, isEncryptionEnabled: bool, isLocked: bool, isMfaEnabled: bool, isMfaEnforced: bool, lastLoginSuccessAt: string, lastName: string, lockStatus: int, login: string, phone: string, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>, title: string, userAttributes: record<items: list<record>>, userName: string, userRoles: record<items: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/v4/users/{user_id}"))
  let body = {"authData": $auth_data, "authMethods": $auth_methods, "email": $email, "expiration": $expiration, "firstName": $first_name, "gender": $gender, "isLocked": $is_locked, "lastName": $last_name, "lockStatus": $lock_status, "mfaConfig": $mfa_config, "phone": $phone, "receiverLanguage": $receiver_language, "title": $title, "userName": $user_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Request groups that user is a member of or / and can become a member
#
# GET /v4/users/{user_id}/groups
# operationId: requestUserGroups
export def "users-groups request" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<id: int, isMember: bool, name: string>, range: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/v4/users/{user_id}/groups") $qp)
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request rooms where the user is last admin
#
# GET /v4/users/{user_id}/last_admin_rooms
# operationId: requestLastAdminRoomsUsers
export def "users-last-admin-rooms request" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<id: int, lastAdminInGroup: bool, lastAdminInGroupId: int, name: string, parentId: int, parentPath: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/v4/users/{user_id}/last_admin_rooms"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request emergency MFA code
#
# POST /v4/users/{user_id}/mfa/emergency_code
# operationId: requestEmergencyMfaCode
export def "users-mfa-emergency-code request" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<code: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/v4/users/{user_id}/mfa/emergency_code"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request user's granted roles
#
# GET /v4/users/{user_id}/roles
# operationId: requestUserRoles
export def "users-roles request" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<description: string, id: int, items: list, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/v4/users/{user_id}/roles"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request rooms granted to the user or / and rooms that can be granted
#
# GET /v4/users/{user_id}/rooms
# DEPRECATED
# operationId: requestUsersRooms
@deprecated
export def "users-rooms request" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<children: list, cntDownloadShares: int, cntUploadShares: int, createdAt: string, createdBy: record, hasRecycleBin: bool, id: int, isEncrypted: bool, isFavorite: bool, isGranted: bool, name: string, parentId: int, permissions: record, quota: int, recycleBinRetentionPeriod: int, size: int, type: string, updatedAt: string, updatedBy: record>, range: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/v4/users/{user_id}/rooms") $qp)
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request custom user attributes
#
# GET /v4/users/{user_id}/userAttributes
# operationId: requestUserAttributes
export def "users-user-attributes request" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # Range offset (format: int32)
  --limit: int # Range limit.  Maximum 500.   For more results please use paging (`offset` + `limit`). (format: int32)
  --filter: string # Filter string
  --qp-sort: string # Sort string
  --x-sds-auth-token: string # Authentication token
]: nothing -> record<items: table<key: string, value: string>, range: record<limit: int, offset: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/v4/users/{user_id}/userAttributes") $qp)
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set custom user attributes
#
# POST /v4/users/{user_id}/userAttributes
# DEPRECATED
# operationId: setUserAttributes
# --items item shape: {key: string, value: string}
@deprecated
export def "users-user-attributes setUserAttributes" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  items: list # List of key-value pairs — item shape: {key: string, value: string}
]: any -> record<authData: record<adConfigId: int, login: string, method: string, mustChangePassword: bool, oidConfigId: int, password: string>, authMethods: table<authId: string, isEnabled: bool, options: list>, avatarUuid: string, email: string, expireAt: string, firstName: string, gender: string, hasManageableRooms: bool, homeRoomId: int, id: int, isEncryptionEnabled: bool, isLocked: bool, isMfaEnabled: bool, isMfaEnforced: bool, lastLoginSuccessAt: string, lastName: string, lockStatus: int, login: string, phone: string, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>, title: string, userAttributes: record<items: list<record>>, userName: string, userRoles: record<items: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/v4/users/{user_id}/userAttributes"))
  let body = {"items": $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add or edit custom user attributes
#
# PUT /v4/users/{user_id}/userAttributes
# operationId: updateUserAttributes
# --items item shape: {key: string, value: string}
export def "users-user-attributes update" [
  user_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-date-format: string@x-sds-date-format-completer # Date time format (cf. [RFC 3339](https://www.ietf.org/rfc/rfc3339.txt) & [leettime.de](http://leettime.de/))
  --x-sds-auth-token: string # Authentication token
  items: list # List of key-value pairs — item shape: {key: string, value: string}
]: any -> record<authData: record<adConfigId: int, login: string, method: string, mustChangePassword: bool, oidConfigId: int, password: string>, authMethods: table<authId: string, isEnabled: bool, options: list>, avatarUuid: string, email: string, expireAt: string, firstName: string, gender: string, hasManageableRooms: bool, homeRoomId: int, id: int, isEncryptionEnabled: bool, isLocked: bool, isMfaEnabled: bool, isMfaEnforced: bool, lastLoginSuccessAt: string, lastName: string, lockStatus: int, login: string, phone: string, publicKeyContainer: record<createdAt: string, createdBy: int, publicKey: string, version: string>, title: string, userAttributes: record<items: list<record>>, userName: string, userRoles: record<items: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/v4/users/{user_id}/userAttributes"))
  let body = {"items": $items} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Sds-Date-Format": $x_sds_date_format, "X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove custom user attribute
#
# DELETE /v4/users/{user_id}/userAttributes/{key}
# operationId: removeUserAttribute
export def "users-user-attributes delete" [
  user_id: int
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-sds-auth-token: string # Authentication token
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id, key: $key} | format pattern "/v4/users/{user_id}/userAttributes/{key}"))
  let extra_headers = {"X-Sds-Auth-Token": $x_sds_auth_token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
