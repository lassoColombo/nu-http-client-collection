# Auto-generated client for FusionAuth API v1.67.0
# Source: https://raw.githubusercontent.com/FusionAuth/fusionauth-openapi/main/openapi.yaml
# Auth: --token flag or $env.FUSIONAUTH_API_TOKEN

const BASE_URL = "http://localhost:9011"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o FUSIONAUTH_API_TOKEN | default "" }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["http://localhost:9011" "https://sandbox.fusionauth.io"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def existingUserStrategy-completer [] { ["mustExist" "mustNotExist"] }
def verificationStrategy-completer [] { ["ClickableLink" "FormField"] }
def loginStrategy-completer [] { ["ClickableLink" "FormField"] }
def messageType-completer [] { ["SMS" "Voice"] }
def action-completer [] { ["changePassword" "login" "stepUp"] }
def sendSetPasswordIdentityType-completer [] { ["doNotSend" "email" "phone"] }
def workflow-completer [] { ["bootstrap" "general" "reauthentication"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "well-known-jwksjson retrieveJsonWebKeySetWithId" } } | get name | first)
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

# Returns public keys used by FusionAuth to cryptographically verify JWTs using the JSON Web Key format.
#
# GET /.well-known/jwks.json
# operationId: retrieveJsonWebKeySetWithId
export def "well-known-jwksjson retrieveJsonWebKeySetWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<keys: table<alg: string, crv: string, d: string, dp: string, dq: string, e: string, kid: string, kty: string, n: string, other: record, p: string, q: string, qi: string, use: string, x: string, x5c: list, x5t: string, x5t_S256: string, y: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/.well-known/jwks.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Returns the well known OpenID Configuration JSON document
#
# GET /.well-known/openid-configuration
# operationId: retrieveOpenIdConfigurationWithId
export def "well-known-openid-configuration retrieveOpenIdConfigurationWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<authorization_endpoint: string, backchannel_logout_supported: bool, claims_supported: list<string>, device_authorization_endpoint: string, dpop_signing_alg_values_supported: list<string>, end_session_endpoint: string, frontchannel_logout_supported: bool, grant_types_supported: list<string>, id_token_signing_alg_values_supported: list<string>, issuer: string, jwks_uri: string, response_modes_supported: list<string>, response_types_supported: list<string>, scopes_supported: list<string>, subject_types_supported: list<string>, token_endpoint: string, token_endpoint_auth_methods_supported: list<string>, userinfo_endpoint: string, userinfo_signing_alg_values_supported: list<string>, code_challenge_methods_supported: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/.well-known/openid-configuration")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates an API key. You can optionally specify a unique Id for the key, if not provided one will be generated. an API key can only be created with equal or lesser authority. An API key cannot create another API key unless it is granted  to that API key.  If an API key is locked to a tenant, it can only create API Keys for that same tenant.
#
# POST /api/api-key
# operationId: createAPIKey
# --apiKey shape: {expirationInstant?: int, id?: string, insertInstant?: int, ipAccessControlListId?: string, key?: string, keyManager?: bool, lastUpdateInstant?: int, metaData?: record, name?: string, permissions?: record, retrievable?: bool, tenantId?: string}
export def "api-key createAPIKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --apiKey: record # domain POJO to represent AuthenticationKey — shape: {expirationInstant?: int, id?: string, insertInstant?: int, ipAccessControlListId?: string, key?: string, keyManager?: bool, lastUpdateInstant?: int, metaData?: record, name?: string, permissions?: record, retrievable?: bool, tenantId?: string}
  --sourceKeyId: string # format: uuid
]: any -> record<apiKey: record<expirationInstant: int, id: string, insertInstant: int, ipAccessControlListId: string, key: string, keyManager: bool, lastUpdateInstant: int, metaData: record<attributes: record>, name: string, permissions: record<endpoints: record>, retrievable: bool, tenantId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/api-key")
  let body = {apiKey: $apiKey, sourceKeyId: $sourceKeyId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates an API key. You can optionally specify a unique Id for the key, if not provided one will be generated. an API key can only be created with equal or lesser authority. An API key cannot create another API key unless it is granted  to that API key.  If an API key is locked to a tenant, it can only create API Keys for that same tenant.
#
# POST /api/api-key/{keyId}
# operationId: createAPIKeyWithId
# --apiKey shape: {expirationInstant?: int, id?: string, insertInstant?: int, ipAccessControlListId?: string, key?: string, keyManager?: bool, lastUpdateInstant?: int, metaData?: record, name?: string, permissions?: record, retrievable?: bool, tenantId?: string}
export def "api-key createAPIKeyWithId" [
  keyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --apiKey: record # domain POJO to represent AuthenticationKey — shape: {expirationInstant?: int, id?: string, insertInstant?: int, ipAccessControlListId?: string, key?: string, keyManager?: bool, lastUpdateInstant?: int, metaData?: record, name?: string, permissions?: record, retrievable?: bool, tenantId?: string}
  --sourceKeyId: string # format: uuid
]: any -> record<apiKey: record<expirationInstant: int, id: string, insertInstant: int, ipAccessControlListId: string, key: string, keyManager: bool, lastUpdateInstant: int, metaData: record<attributes: record>, name: string, permissions: record<endpoints: record>, retrievable: bool, tenantId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/api-key/($keyId)")
  let body = {apiKey: $apiKey, sourceKeyId: $sourceKeyId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the API key for the given Id.
#
# DELETE /api/api-key/{keyId}
# operationId: deleteAPIKeyWithId
export def "api-key delete" [
  keyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/api-key/($keyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates an API key with the given Id.
#
# PATCH /api/api-key/{keyId}
# operationId: patchAPIKeyWithId
# --apiKey shape: {expirationInstant?: int, id?: string, insertInstant?: int, ipAccessControlListId?: string, key?: string, keyManager?: bool, lastUpdateInstant?: int, metaData?: record, name?: string, permissions?: record, retrievable?: bool, tenantId?: string}
export def "api-key patch" [
  keyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --apiKey: record # domain POJO to represent AuthenticationKey — shape: {expirationInstant?: int, id?: string, insertInstant?: int, ipAccessControlListId?: string, key?: string, keyManager?: bool, lastUpdateInstant?: int, metaData?: record, name?: string, permissions?: record, retrievable?: bool, tenantId?: string}
  --sourceKeyId: string # format: uuid
]: any -> record<apiKey: record<expirationInstant: int, id: string, insertInstant: int, ipAccessControlListId: string, key: string, keyManager: bool, lastUpdateInstant: int, metaData: record<attributes: record>, name: string, permissions: record<endpoints: record>, retrievable: bool, tenantId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/api-key/($keyId)")
  let body = {apiKey: $apiKey, sourceKeyId: $sourceKeyId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves an authentication API key for the given Id.
#
# GET /api/api-key/{keyId}
# operationId: retrieveAPIKeyWithId
export def "api-key retrieveAPIKeyWithId" [
  keyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<apiKey: record<expirationInstant: int, id: string, insertInstant: int, ipAccessControlListId: string, key: string, keyManager: bool, lastUpdateInstant: int, metaData: record<attributes: record>, name: string, permissions: record<endpoints: record>, retrievable: bool, tenantId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/api-key/($keyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates an API key with the given Id.
#
# PUT /api/api-key/{keyId}
# operationId: updateAPIKeyWithId
# --apiKey shape: {expirationInstant?: int, id?: string, insertInstant?: int, ipAccessControlListId?: string, key?: string, keyManager?: bool, lastUpdateInstant?: int, metaData?: record, name?: string, permissions?: record, retrievable?: bool, tenantId?: string}
export def "api-key updateAPIKeyWithId" [
  keyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --apiKey: record # domain POJO to represent AuthenticationKey — shape: {expirationInstant?: int, id?: string, insertInstant?: int, ipAccessControlListId?: string, key?: string, keyManager?: bool, lastUpdateInstant?: int, metaData?: record, name?: string, permissions?: record, retrievable?: bool, tenantId?: string}
  --sourceKeyId: string # format: uuid
]: any -> record<apiKey: record<expirationInstant: int, id: string, insertInstant: int, ipAccessControlListId: string, key: string, keyManager: bool, lastUpdateInstant: int, metaData: record<attributes: record>, name: string, permissions: record<endpoints: record>, retrievable: bool, tenantId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/api-key/($keyId)")
  let body = {apiKey: $apiKey, sourceKeyId: $sourceKeyId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates an application. You can optionally specify an Id for the application, if not provided one will be generated.
#
# POST /api/application
# operationId: createApplication
# --application shape: {accessControlConfiguration?: record, active?: bool, authenticationTokenConfiguration?: record, cleanSpeakConfiguration?: record, data?: record, emailConfiguration?: record, externalIdentifierConfiguration?: record, formConfiguration?: record, id?: string, insertInstant?: int, jwtConfiguration?: record, lambdaConfiguration?: record, lastUpdateInstant?: int, loginConfiguration?: record, multiFactorConfiguration?: record, name?: string, oauthConfiguration?: record, passwordlessConfiguration?: record, phoneConfiguration?: record, registrationConfiguration?: record, registrationDeletePolicy?: record, roles?: list, samlv2Configuration?: record, scopes?: list, state?: "Active"|"Inactive"|"PendingDelete", tenantId?: string, themeId?: string, universalConfiguration?: record, unverified?: record, verificationEmailTemplateId?: string, verificationStrategy?: "ClickableLink"|"FormField", verifyRegistration?: bool, webAuthnConfiguration?: record}
# --role shape: {description?: string, id?: string, insertInstant?: int, isDefault?: bool, isSuperRole?: bool, lastUpdateInstant?: int, name?: string}
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "application createApplication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --application: record # shape: {accessControlConfiguration?: record, active?: bool, authenticationTokenConfiguration?: record, cleanSpeakConfiguration?: record, data?: record, emailConfiguration?: record, externalIdentifierConfiguration?: record, formConfiguration?: record, id?: string, insertInstant?: int, jwtConfiguration?: record, lambdaConfiguration?: record, lastUpdateInstant?: int, loginConfiguration?: record, multiFactorConfiguration?: record, name?: string, oauthConfiguration?: record, passwordlessConfiguration?: record, phoneConfiguration?: record, registrationConfiguration?: record, registrationDeletePolicy?: record, roles?: list, samlv2Configuration?: record, scopes?: list, state?: "Active"|"Inactive"|"PendingDelete", tenantId?: string, themeId?: string, universalConfiguration?: record, unverified?: record, verificationEmailTemplateId?: string, verificationStrategy?: "ClickableLink"|"FormField", verifyRegistration?: bool, webAuthnConfiguration?: record}
  --role: record # A role given to a user for a specific application. — shape: {description?: string, id?: string, insertInstant?: int, isDefault?: bool, isSuperRole?: bool, lastUpdateInstant?: int, name?: string}
  --sourceApplicationId: string # format: uuid
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<application: record<accessControlConfiguration: record<uiIPAccessControlListId: string>, active: bool, authenticationTokenConfiguration: record<enabled: bool>, cleanSpeakConfiguration: record<apiKey: string, applicationIds: list, url: string, usernameModeration: record, enabled: bool>, data: record, emailConfiguration: record<emailUpdateEmailTemplateId: string, emailVerificationEmailTemplateId: string, emailVerifiedEmailTemplateId: string, forgotPasswordEmailTemplateId: string, loginIdInUseOnCreateEmailTemplateId: string, loginIdInUseOnUpdateEmailTemplateId: string, loginNewDeviceEmailTemplateId: string, loginSuspiciousEmailTemplateId: string, passwordResetSuccessEmailTemplateId: string, passwordUpdateEmailTemplateId: string, passwordlessEmailTemplateId: string, setPasswordEmailTemplateId: string, twoFactorMethodAddEmailTemplateId: string, twoFactorMethodRemoveEmailTemplateId: string>, externalIdentifierConfiguration: record<twoFactorTrustIdTimeToLiveInSeconds: int>, formConfiguration: record<adminRegistrationFormId: string, selfServiceFormConfiguration: record, selfServiceFormId: string>, id: string, insertInstant: int, jwtConfiguration: record<accessTokenKeyId: string, idTokenKeyId: string, refreshTokenExpirationPolicy: string, refreshTokenOneTimeUseConfiguration: record, refreshTokenRevocationPolicy: record, refreshTokenSlidingWindowConfiguration: record, refreshTokenTimeToLiveInMinutes: int, refreshTokenUsagePolicy: string, timeToLiveInSeconds: int, enabled: bool>, lambdaConfiguration: record<accessTokenPopulateId: string, idTokenPopulateId: string, multiFactorRequirementId: string, samlv2PopulateId: string, selfServiceRegistrationValidationId: string, userinfoPopulateId: string>, lastUpdateInstant: int, loginConfiguration: record<allowTokenRefresh: bool, generateRefreshTokens: bool, requireAuthentication: bool>, multiFactorConfiguration: record<email: record, loginPolicy: string, sms: record, trustPolicy: string, voice: record>, name: string, oauthConfiguration: record<authorizedOriginURLs: list, authorizedRedirectURLs: list, authorizedResourceUris: list, authorizedURLValidationPolicy: string, clientAuthenticationPolicy: string, clientId: string, clientSecret: string, consentMode: string, debug: bool, deviceVerificationURL: string, enabledGrants: list, generateRefreshTokens: bool, logoutBehavior: string, logoutURL: string, proofKeyForCodeExchangePolicy: string, providedScopePolicy: record, relationship: string, requireClientAuthentication: bool, requireRegistration: bool, scopeHandlingPolicy: string, unknownScopePolicy: string>, passwordlessConfiguration: record<emailLoginStrategy: string, phoneLoginStrategy: string, enabled: bool>, phoneConfiguration: record<forgotPasswordTemplateId: string, identityUpdateTemplateId: string, loginIdInUseOnCreateTemplateId: string, loginIdInUseOnUpdateTemplateId: string, loginNewDeviceTemplateId: string, loginSuspiciousTemplateId: string, passwordResetSuccessTemplateId: string, passwordUpdateTemplateId: string, passwordlessTemplateId: string, setPasswordTemplateId: string, twoFactorMethodAddTemplateId: string, twoFactorMethodRemoveTemplateId: string, verificationCompleteTemplateId: string, verificationTemplateId: string>, registrationConfiguration: record<birthDate: record, completeRegistration: bool, confirmPassword: bool, firstName: record, formId: string, fullName: record, lastName: record, loginIdType: string, middleName: record, mobilePhone: record, preferredLanguages: record, type: string, enabled: bool>, registrationDeletePolicy: record<unverified: record>, roles: list<record>, samlv2Configuration: record<assertionEncryptionConfiguration: record, audience: string, authorizedRedirectURLs: list, debug: bool, defaultVerificationKeyId: string, initiatedLogin: record, issuer: string, keyId: string, loginHintConfiguration: record, logout: record, logoutURL: string, requireSignedRequests: bool, xmlSignatureC14nMethod: string, xmlSignatureLocation: string, callbackURL: string, enabled: bool>, scopes: list<record>, state: string, tenantId: string, themeId: string, universalConfiguration: record<universal: bool>, unverified: record<behavior: string>, verificationEmailTemplateId: string, verificationStrategy: string, verifyRegistration: bool, webAuthnConfiguration: record<bootstrapWorkflow: record, reauthenticationWorkflow: record, enabled: bool>>, applications: table<accessControlConfiguration: record, active: bool, authenticationTokenConfiguration: record, cleanSpeakConfiguration: record, data: record, emailConfiguration: record, externalIdentifierConfiguration: record, formConfiguration: record, id: string, insertInstant: int, jwtConfiguration: record, lambdaConfiguration: record, lastUpdateInstant: int, loginConfiguration: record, multiFactorConfiguration: record, name: string, oauthConfiguration: record, passwordlessConfiguration: record, phoneConfiguration: record, registrationConfiguration: record, registrationDeletePolicy: record, roles: list, samlv2Configuration: record, scopes: list, state: string, tenantId: string, themeId: string, universalConfiguration: record, unverified: record, verificationEmailTemplateId: string, verificationStrategy: string, verifyRegistration: bool, webAuthnConfiguration: record>, role: record<description: string, id: string, insertInstant: int, isDefault: bool, isSuperRole: bool, lastUpdateInstant: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/application")
  let body = {application: $application, role: $role, sourceApplicationId: $sourceApplicationId, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves all the applications that are currently inactive. OR Retrieves the application for the given Id or all the applications if the Id is null.
#
# GET /api/application
# operationId: retrieveApplication
export def "application retrieveApplication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --inactive: string
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
]: nothing -> record<application: record<accessControlConfiguration: record<uiIPAccessControlListId: string>, active: bool, authenticationTokenConfiguration: record<enabled: bool>, cleanSpeakConfiguration: record<apiKey: string, applicationIds: list, url: string, usernameModeration: record, enabled: bool>, data: record, emailConfiguration: record<emailUpdateEmailTemplateId: string, emailVerificationEmailTemplateId: string, emailVerifiedEmailTemplateId: string, forgotPasswordEmailTemplateId: string, loginIdInUseOnCreateEmailTemplateId: string, loginIdInUseOnUpdateEmailTemplateId: string, loginNewDeviceEmailTemplateId: string, loginSuspiciousEmailTemplateId: string, passwordResetSuccessEmailTemplateId: string, passwordUpdateEmailTemplateId: string, passwordlessEmailTemplateId: string, setPasswordEmailTemplateId: string, twoFactorMethodAddEmailTemplateId: string, twoFactorMethodRemoveEmailTemplateId: string>, externalIdentifierConfiguration: record<twoFactorTrustIdTimeToLiveInSeconds: int>, formConfiguration: record<adminRegistrationFormId: string, selfServiceFormConfiguration: record, selfServiceFormId: string>, id: string, insertInstant: int, jwtConfiguration: record<accessTokenKeyId: string, idTokenKeyId: string, refreshTokenExpirationPolicy: string, refreshTokenOneTimeUseConfiguration: record, refreshTokenRevocationPolicy: record, refreshTokenSlidingWindowConfiguration: record, refreshTokenTimeToLiveInMinutes: int, refreshTokenUsagePolicy: string, timeToLiveInSeconds: int, enabled: bool>, lambdaConfiguration: record<accessTokenPopulateId: string, idTokenPopulateId: string, multiFactorRequirementId: string, samlv2PopulateId: string, selfServiceRegistrationValidationId: string, userinfoPopulateId: string>, lastUpdateInstant: int, loginConfiguration: record<allowTokenRefresh: bool, generateRefreshTokens: bool, requireAuthentication: bool>, multiFactorConfiguration: record<email: record, loginPolicy: string, sms: record, trustPolicy: string, voice: record>, name: string, oauthConfiguration: record<authorizedOriginURLs: list, authorizedRedirectURLs: list, authorizedResourceUris: list, authorizedURLValidationPolicy: string, clientAuthenticationPolicy: string, clientId: string, clientSecret: string, consentMode: string, debug: bool, deviceVerificationURL: string, enabledGrants: list, generateRefreshTokens: bool, logoutBehavior: string, logoutURL: string, proofKeyForCodeExchangePolicy: string, providedScopePolicy: record, relationship: string, requireClientAuthentication: bool, requireRegistration: bool, scopeHandlingPolicy: string, unknownScopePolicy: string>, passwordlessConfiguration: record<emailLoginStrategy: string, phoneLoginStrategy: string, enabled: bool>, phoneConfiguration: record<forgotPasswordTemplateId: string, identityUpdateTemplateId: string, loginIdInUseOnCreateTemplateId: string, loginIdInUseOnUpdateTemplateId: string, loginNewDeviceTemplateId: string, loginSuspiciousTemplateId: string, passwordResetSuccessTemplateId: string, passwordUpdateTemplateId: string, passwordlessTemplateId: string, setPasswordTemplateId: string, twoFactorMethodAddTemplateId: string, twoFactorMethodRemoveTemplateId: string, verificationCompleteTemplateId: string, verificationTemplateId: string>, registrationConfiguration: record<birthDate: record, completeRegistration: bool, confirmPassword: bool, firstName: record, formId: string, fullName: record, lastName: record, loginIdType: string, middleName: record, mobilePhone: record, preferredLanguages: record, type: string, enabled: bool>, registrationDeletePolicy: record<unverified: record>, roles: list<record>, samlv2Configuration: record<assertionEncryptionConfiguration: record, audience: string, authorizedRedirectURLs: list, debug: bool, defaultVerificationKeyId: string, initiatedLogin: record, issuer: string, keyId: string, loginHintConfiguration: record, logout: record, logoutURL: string, requireSignedRequests: bool, xmlSignatureC14nMethod: string, xmlSignatureLocation: string, callbackURL: string, enabled: bool>, scopes: list<record>, state: string, tenantId: string, themeId: string, universalConfiguration: record<universal: bool>, unverified: record<behavior: string>, verificationEmailTemplateId: string, verificationStrategy: string, verifyRegistration: bool, webAuthnConfiguration: record<bootstrapWorkflow: record, reauthenticationWorkflow: record, enabled: bool>>, applications: table<accessControlConfiguration: record, active: bool, authenticationTokenConfiguration: record, cleanSpeakConfiguration: record, data: record, emailConfiguration: record, externalIdentifierConfiguration: record, formConfiguration: record, id: string, insertInstant: int, jwtConfiguration: record, lambdaConfiguration: record, lastUpdateInstant: int, loginConfiguration: record, multiFactorConfiguration: record, name: string, oauthConfiguration: record, passwordlessConfiguration: record, phoneConfiguration: record, registrationConfiguration: record, registrationDeletePolicy: record, roles: list, samlv2Configuration: record, scopes: list, state: string, tenantId: string, themeId: string, universalConfiguration: record, unverified: record, verificationEmailTemplateId: string, verificationStrategy: string, verifyRegistration: bool, webAuthnConfiguration: record>, role: record<description: string, id: string, insertInstant: int, isDefault: bool, isSuperRole: bool, lastUpdateInstant: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "inactive" $inactive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/application" $qp)
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searches applications with the specified criteria and pagination.
#
# POST /api/application/search
# operationId: searchApplicationsWithId
# --search shape: {name?: string, state?: "Active"|"Inactive"|"PendingDelete", tenantId?: string, universal?: bool, numberOfResults?: int, orderBy?: string, startRow?: int}
export def "application-search searchApplicationsWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: record # Search criteria for Applications — shape: {name?: string, state?: "Active"|"Inactive"|"PendingDelete", tenantId?: string, universal?: bool, numberOfResults?: int, orderBy?: string, startRow?: int}
  --expand: list
]: any -> record<applications: table<accessControlConfiguration: record, active: bool, authenticationTokenConfiguration: record, cleanSpeakConfiguration: record, data: record, emailConfiguration: record, externalIdentifierConfiguration: record, formConfiguration: record, id: string, insertInstant: int, jwtConfiguration: record, lambdaConfiguration: record, lastUpdateInstant: int, loginConfiguration: record, multiFactorConfiguration: record, name: string, oauthConfiguration: record, passwordlessConfiguration: record, phoneConfiguration: record, registrationConfiguration: record, registrationDeletePolicy: record, roles: list, samlv2Configuration: record, scopes: list, state: string, tenantId: string, themeId: string, universalConfiguration: record, unverified: record, verificationEmailTemplateId: string, verificationStrategy: string, verifyRegistration: bool, webAuthnConfiguration: record>, total: int, expandable: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/application/search")
  let body = {search: $search, expand: $expand} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates an application. You can optionally specify an Id for the application, if not provided one will be generated.
#
# POST /api/application/{applicationId}
# operationId: createApplicationWithId
# --application shape: {accessControlConfiguration?: record, active?: bool, authenticationTokenConfiguration?: record, cleanSpeakConfiguration?: record, data?: record, emailConfiguration?: record, externalIdentifierConfiguration?: record, formConfiguration?: record, id?: string, insertInstant?: int, jwtConfiguration?: record, lambdaConfiguration?: record, lastUpdateInstant?: int, loginConfiguration?: record, multiFactorConfiguration?: record, name?: string, oauthConfiguration?: record, passwordlessConfiguration?: record, phoneConfiguration?: record, registrationConfiguration?: record, registrationDeletePolicy?: record, roles?: list, samlv2Configuration?: record, scopes?: list, state?: "Active"|"Inactive"|"PendingDelete", tenantId?: string, themeId?: string, universalConfiguration?: record, unverified?: record, verificationEmailTemplateId?: string, verificationStrategy?: "ClickableLink"|"FormField", verifyRegistration?: bool, webAuthnConfiguration?: record}
# --role shape: {description?: string, id?: string, insertInstant?: int, isDefault?: bool, isSuperRole?: bool, lastUpdateInstant?: int, name?: string}
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "application createApplicationWithId" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --application: record # shape: {accessControlConfiguration?: record, active?: bool, authenticationTokenConfiguration?: record, cleanSpeakConfiguration?: record, data?: record, emailConfiguration?: record, externalIdentifierConfiguration?: record, formConfiguration?: record, id?: string, insertInstant?: int, jwtConfiguration?: record, lambdaConfiguration?: record, lastUpdateInstant?: int, loginConfiguration?: record, multiFactorConfiguration?: record, name?: string, oauthConfiguration?: record, passwordlessConfiguration?: record, phoneConfiguration?: record, registrationConfiguration?: record, registrationDeletePolicy?: record, roles?: list, samlv2Configuration?: record, scopes?: list, state?: "Active"|"Inactive"|"PendingDelete", tenantId?: string, themeId?: string, universalConfiguration?: record, unverified?: record, verificationEmailTemplateId?: string, verificationStrategy?: "ClickableLink"|"FormField", verifyRegistration?: bool, webAuthnConfiguration?: record}
  --role: record # A role given to a user for a specific application. — shape: {description?: string, id?: string, insertInstant?: int, isDefault?: bool, isSuperRole?: bool, lastUpdateInstant?: int, name?: string}
  --sourceApplicationId: string # format: uuid
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<application: record<accessControlConfiguration: record<uiIPAccessControlListId: string>, active: bool, authenticationTokenConfiguration: record<enabled: bool>, cleanSpeakConfiguration: record<apiKey: string, applicationIds: list, url: string, usernameModeration: record, enabled: bool>, data: record, emailConfiguration: record<emailUpdateEmailTemplateId: string, emailVerificationEmailTemplateId: string, emailVerifiedEmailTemplateId: string, forgotPasswordEmailTemplateId: string, loginIdInUseOnCreateEmailTemplateId: string, loginIdInUseOnUpdateEmailTemplateId: string, loginNewDeviceEmailTemplateId: string, loginSuspiciousEmailTemplateId: string, passwordResetSuccessEmailTemplateId: string, passwordUpdateEmailTemplateId: string, passwordlessEmailTemplateId: string, setPasswordEmailTemplateId: string, twoFactorMethodAddEmailTemplateId: string, twoFactorMethodRemoveEmailTemplateId: string>, externalIdentifierConfiguration: record<twoFactorTrustIdTimeToLiveInSeconds: int>, formConfiguration: record<adminRegistrationFormId: string, selfServiceFormConfiguration: record, selfServiceFormId: string>, id: string, insertInstant: int, jwtConfiguration: record<accessTokenKeyId: string, idTokenKeyId: string, refreshTokenExpirationPolicy: string, refreshTokenOneTimeUseConfiguration: record, refreshTokenRevocationPolicy: record, refreshTokenSlidingWindowConfiguration: record, refreshTokenTimeToLiveInMinutes: int, refreshTokenUsagePolicy: string, timeToLiveInSeconds: int, enabled: bool>, lambdaConfiguration: record<accessTokenPopulateId: string, idTokenPopulateId: string, multiFactorRequirementId: string, samlv2PopulateId: string, selfServiceRegistrationValidationId: string, userinfoPopulateId: string>, lastUpdateInstant: int, loginConfiguration: record<allowTokenRefresh: bool, generateRefreshTokens: bool, requireAuthentication: bool>, multiFactorConfiguration: record<email: record, loginPolicy: string, sms: record, trustPolicy: string, voice: record>, name: string, oauthConfiguration: record<authorizedOriginURLs: list, authorizedRedirectURLs: list, authorizedResourceUris: list, authorizedURLValidationPolicy: string, clientAuthenticationPolicy: string, clientId: string, clientSecret: string, consentMode: string, debug: bool, deviceVerificationURL: string, enabledGrants: list, generateRefreshTokens: bool, logoutBehavior: string, logoutURL: string, proofKeyForCodeExchangePolicy: string, providedScopePolicy: record, relationship: string, requireClientAuthentication: bool, requireRegistration: bool, scopeHandlingPolicy: string, unknownScopePolicy: string>, passwordlessConfiguration: record<emailLoginStrategy: string, phoneLoginStrategy: string, enabled: bool>, phoneConfiguration: record<forgotPasswordTemplateId: string, identityUpdateTemplateId: string, loginIdInUseOnCreateTemplateId: string, loginIdInUseOnUpdateTemplateId: string, loginNewDeviceTemplateId: string, loginSuspiciousTemplateId: string, passwordResetSuccessTemplateId: string, passwordUpdateTemplateId: string, passwordlessTemplateId: string, setPasswordTemplateId: string, twoFactorMethodAddTemplateId: string, twoFactorMethodRemoveTemplateId: string, verificationCompleteTemplateId: string, verificationTemplateId: string>, registrationConfiguration: record<birthDate: record, completeRegistration: bool, confirmPassword: bool, firstName: record, formId: string, fullName: record, lastName: record, loginIdType: string, middleName: record, mobilePhone: record, preferredLanguages: record, type: string, enabled: bool>, registrationDeletePolicy: record<unverified: record>, roles: list<record>, samlv2Configuration: record<assertionEncryptionConfiguration: record, audience: string, authorizedRedirectURLs: list, debug: bool, defaultVerificationKeyId: string, initiatedLogin: record, issuer: string, keyId: string, loginHintConfiguration: record, logout: record, logoutURL: string, requireSignedRequests: bool, xmlSignatureC14nMethod: string, xmlSignatureLocation: string, callbackURL: string, enabled: bool>, scopes: list<record>, state: string, tenantId: string, themeId: string, universalConfiguration: record<universal: bool>, unverified: record<behavior: string>, verificationEmailTemplateId: string, verificationStrategy: string, verifyRegistration: bool, webAuthnConfiguration: record<bootstrapWorkflow: record, reauthenticationWorkflow: record, enabled: bool>>, applications: table<accessControlConfiguration: record, active: bool, authenticationTokenConfiguration: record, cleanSpeakConfiguration: record, data: record, emailConfiguration: record, externalIdentifierConfiguration: record, formConfiguration: record, id: string, insertInstant: int, jwtConfiguration: record, lambdaConfiguration: record, lastUpdateInstant: int, loginConfiguration: record, multiFactorConfiguration: record, name: string, oauthConfiguration: record, passwordlessConfiguration: record, phoneConfiguration: record, registrationConfiguration: record, registrationDeletePolicy: record, roles: list, samlv2Configuration: record, scopes: list, state: string, tenantId: string, themeId: string, universalConfiguration: record, unverified: record, verificationEmailTemplateId: string, verificationStrategy: string, verifyRegistration: bool, webAuthnConfiguration: record>, role: record<description: string, id: string, insertInstant: int, isDefault: bool, isSuperRole: bool, lastUpdateInstant: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/application/($applicationId)")
  let body = {application: $application, role: $role, sourceApplicationId: $sourceApplicationId, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Hard deletes an application. This is a dangerous operation and should not be used in most circumstances. This will delete the application, any registrations for that application, metrics and reports for the application, all the roles for the application, and any other data associated with the application. This operation could take a very long time, depending on the amount of data in your database. OR Deactivates the application with the given Id.
#
# DELETE /api/application/{applicationId}
# operationId: deleteApplicationWithId
export def "application delete" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hardDelete: string
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
]: nothing -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hardDelete" $hardDelete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/application/($applicationId)" $qp)
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates, via PATCH, the application with the given Id.
#
# PATCH /api/application/{applicationId}
# operationId: patchApplicationWithId
# --application shape: {accessControlConfiguration?: record, active?: bool, authenticationTokenConfiguration?: record, cleanSpeakConfiguration?: record, data?: record, emailConfiguration?: record, externalIdentifierConfiguration?: record, formConfiguration?: record, id?: string, insertInstant?: int, jwtConfiguration?: record, lambdaConfiguration?: record, lastUpdateInstant?: int, loginConfiguration?: record, multiFactorConfiguration?: record, name?: string, oauthConfiguration?: record, passwordlessConfiguration?: record, phoneConfiguration?: record, registrationConfiguration?: record, registrationDeletePolicy?: record, roles?: list, samlv2Configuration?: record, scopes?: list, state?: "Active"|"Inactive"|"PendingDelete", tenantId?: string, themeId?: string, universalConfiguration?: record, unverified?: record, verificationEmailTemplateId?: string, verificationStrategy?: "ClickableLink"|"FormField", verifyRegistration?: bool, webAuthnConfiguration?: record}
# --role shape: {description?: string, id?: string, insertInstant?: int, isDefault?: bool, isSuperRole?: bool, lastUpdateInstant?: int, name?: string}
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "application patch" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --application: record # shape: {accessControlConfiguration?: record, active?: bool, authenticationTokenConfiguration?: record, cleanSpeakConfiguration?: record, data?: record, emailConfiguration?: record, externalIdentifierConfiguration?: record, formConfiguration?: record, id?: string, insertInstant?: int, jwtConfiguration?: record, lambdaConfiguration?: record, lastUpdateInstant?: int, loginConfiguration?: record, multiFactorConfiguration?: record, name?: string, oauthConfiguration?: record, passwordlessConfiguration?: record, phoneConfiguration?: record, registrationConfiguration?: record, registrationDeletePolicy?: record, roles?: list, samlv2Configuration?: record, scopes?: list, state?: "Active"|"Inactive"|"PendingDelete", tenantId?: string, themeId?: string, universalConfiguration?: record, unverified?: record, verificationEmailTemplateId?: string, verificationStrategy?: "ClickableLink"|"FormField", verifyRegistration?: bool, webAuthnConfiguration?: record}
  --role: record # A role given to a user for a specific application. — shape: {description?: string, id?: string, insertInstant?: int, isDefault?: bool, isSuperRole?: bool, lastUpdateInstant?: int, name?: string}
  --sourceApplicationId: string # format: uuid
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<application: record<accessControlConfiguration: record<uiIPAccessControlListId: string>, active: bool, authenticationTokenConfiguration: record<enabled: bool>, cleanSpeakConfiguration: record<apiKey: string, applicationIds: list, url: string, usernameModeration: record, enabled: bool>, data: record, emailConfiguration: record<emailUpdateEmailTemplateId: string, emailVerificationEmailTemplateId: string, emailVerifiedEmailTemplateId: string, forgotPasswordEmailTemplateId: string, loginIdInUseOnCreateEmailTemplateId: string, loginIdInUseOnUpdateEmailTemplateId: string, loginNewDeviceEmailTemplateId: string, loginSuspiciousEmailTemplateId: string, passwordResetSuccessEmailTemplateId: string, passwordUpdateEmailTemplateId: string, passwordlessEmailTemplateId: string, setPasswordEmailTemplateId: string, twoFactorMethodAddEmailTemplateId: string, twoFactorMethodRemoveEmailTemplateId: string>, externalIdentifierConfiguration: record<twoFactorTrustIdTimeToLiveInSeconds: int>, formConfiguration: record<adminRegistrationFormId: string, selfServiceFormConfiguration: record, selfServiceFormId: string>, id: string, insertInstant: int, jwtConfiguration: record<accessTokenKeyId: string, idTokenKeyId: string, refreshTokenExpirationPolicy: string, refreshTokenOneTimeUseConfiguration: record, refreshTokenRevocationPolicy: record, refreshTokenSlidingWindowConfiguration: record, refreshTokenTimeToLiveInMinutes: int, refreshTokenUsagePolicy: string, timeToLiveInSeconds: int, enabled: bool>, lambdaConfiguration: record<accessTokenPopulateId: string, idTokenPopulateId: string, multiFactorRequirementId: string, samlv2PopulateId: string, selfServiceRegistrationValidationId: string, userinfoPopulateId: string>, lastUpdateInstant: int, loginConfiguration: record<allowTokenRefresh: bool, generateRefreshTokens: bool, requireAuthentication: bool>, multiFactorConfiguration: record<email: record, loginPolicy: string, sms: record, trustPolicy: string, voice: record>, name: string, oauthConfiguration: record<authorizedOriginURLs: list, authorizedRedirectURLs: list, authorizedResourceUris: list, authorizedURLValidationPolicy: string, clientAuthenticationPolicy: string, clientId: string, clientSecret: string, consentMode: string, debug: bool, deviceVerificationURL: string, enabledGrants: list, generateRefreshTokens: bool, logoutBehavior: string, logoutURL: string, proofKeyForCodeExchangePolicy: string, providedScopePolicy: record, relationship: string, requireClientAuthentication: bool, requireRegistration: bool, scopeHandlingPolicy: string, unknownScopePolicy: string>, passwordlessConfiguration: record<emailLoginStrategy: string, phoneLoginStrategy: string, enabled: bool>, phoneConfiguration: record<forgotPasswordTemplateId: string, identityUpdateTemplateId: string, loginIdInUseOnCreateTemplateId: string, loginIdInUseOnUpdateTemplateId: string, loginNewDeviceTemplateId: string, loginSuspiciousTemplateId: string, passwordResetSuccessTemplateId: string, passwordUpdateTemplateId: string, passwordlessTemplateId: string, setPasswordTemplateId: string, twoFactorMethodAddTemplateId: string, twoFactorMethodRemoveTemplateId: string, verificationCompleteTemplateId: string, verificationTemplateId: string>, registrationConfiguration: record<birthDate: record, completeRegistration: bool, confirmPassword: bool, firstName: record, formId: string, fullName: record, lastName: record, loginIdType: string, middleName: record, mobilePhone: record, preferredLanguages: record, type: string, enabled: bool>, registrationDeletePolicy: record<unverified: record>, roles: list<record>, samlv2Configuration: record<assertionEncryptionConfiguration: record, audience: string, authorizedRedirectURLs: list, debug: bool, defaultVerificationKeyId: string, initiatedLogin: record, issuer: string, keyId: string, loginHintConfiguration: record, logout: record, logoutURL: string, requireSignedRequests: bool, xmlSignatureC14nMethod: string, xmlSignatureLocation: string, callbackURL: string, enabled: bool>, scopes: list<record>, state: string, tenantId: string, themeId: string, universalConfiguration: record<universal: bool>, unverified: record<behavior: string>, verificationEmailTemplateId: string, verificationStrategy: string, verifyRegistration: bool, webAuthnConfiguration: record<bootstrapWorkflow: record, reauthenticationWorkflow: record, enabled: bool>>, applications: table<accessControlConfiguration: record, active: bool, authenticationTokenConfiguration: record, cleanSpeakConfiguration: record, data: record, emailConfiguration: record, externalIdentifierConfiguration: record, formConfiguration: record, id: string, insertInstant: int, jwtConfiguration: record, lambdaConfiguration: record, lastUpdateInstant: int, loginConfiguration: record, multiFactorConfiguration: record, name: string, oauthConfiguration: record, passwordlessConfiguration: record, phoneConfiguration: record, registrationConfiguration: record, registrationDeletePolicy: record, roles: list, samlv2Configuration: record, scopes: list, state: string, tenantId: string, themeId: string, universalConfiguration: record, unverified: record, verificationEmailTemplateId: string, verificationStrategy: string, verifyRegistration: bool, webAuthnConfiguration: record>, role: record<description: string, id: string, insertInstant: int, isDefault: bool, isSuperRole: bool, lastUpdateInstant: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/application/($applicationId)")
  let body = {application: $application, role: $role, sourceApplicationId: $sourceApplicationId, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates the application with the given Id. OR Reactivates the application with the given Id.
#
# PUT /api/application/{applicationId}
# operationId: updateApplicationWithId
# --application shape: {accessControlConfiguration?: record, active?: bool, authenticationTokenConfiguration?: record, cleanSpeakConfiguration?: record, data?: record, emailConfiguration?: record, externalIdentifierConfiguration?: record, formConfiguration?: record, id?: string, insertInstant?: int, jwtConfiguration?: record, lambdaConfiguration?: record, lastUpdateInstant?: int, loginConfiguration?: record, multiFactorConfiguration?: record, name?: string, oauthConfiguration?: record, passwordlessConfiguration?: record, phoneConfiguration?: record, registrationConfiguration?: record, registrationDeletePolicy?: record, roles?: list, samlv2Configuration?: record, scopes?: list, state?: "Active"|"Inactive"|"PendingDelete", tenantId?: string, themeId?: string, universalConfiguration?: record, unverified?: record, verificationEmailTemplateId?: string, verificationStrategy?: "ClickableLink"|"FormField", verifyRegistration?: bool, webAuthnConfiguration?: record}
# --role shape: {description?: string, id?: string, insertInstant?: int, isDefault?: bool, isSuperRole?: bool, lastUpdateInstant?: int, name?: string}
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "application updateApplicationWithId" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reactivate: string
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --application: record # shape: {accessControlConfiguration?: record, active?: bool, authenticationTokenConfiguration?: record, cleanSpeakConfiguration?: record, data?: record, emailConfiguration?: record, externalIdentifierConfiguration?: record, formConfiguration?: record, id?: string, insertInstant?: int, jwtConfiguration?: record, lambdaConfiguration?: record, lastUpdateInstant?: int, loginConfiguration?: record, multiFactorConfiguration?: record, name?: string, oauthConfiguration?: record, passwordlessConfiguration?: record, phoneConfiguration?: record, registrationConfiguration?: record, registrationDeletePolicy?: record, roles?: list, samlv2Configuration?: record, scopes?: list, state?: "Active"|"Inactive"|"PendingDelete", tenantId?: string, themeId?: string, universalConfiguration?: record, unverified?: record, verificationEmailTemplateId?: string, verificationStrategy?: "ClickableLink"|"FormField", verifyRegistration?: bool, webAuthnConfiguration?: record}
  --role: record # A role given to a user for a specific application. — shape: {description?: string, id?: string, insertInstant?: int, isDefault?: bool, isSuperRole?: bool, lastUpdateInstant?: int, name?: string}
  --sourceApplicationId: string # format: uuid
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<application: record<accessControlConfiguration: record<uiIPAccessControlListId: string>, active: bool, authenticationTokenConfiguration: record<enabled: bool>, cleanSpeakConfiguration: record<apiKey: string, applicationIds: list, url: string, usernameModeration: record, enabled: bool>, data: record, emailConfiguration: record<emailUpdateEmailTemplateId: string, emailVerificationEmailTemplateId: string, emailVerifiedEmailTemplateId: string, forgotPasswordEmailTemplateId: string, loginIdInUseOnCreateEmailTemplateId: string, loginIdInUseOnUpdateEmailTemplateId: string, loginNewDeviceEmailTemplateId: string, loginSuspiciousEmailTemplateId: string, passwordResetSuccessEmailTemplateId: string, passwordUpdateEmailTemplateId: string, passwordlessEmailTemplateId: string, setPasswordEmailTemplateId: string, twoFactorMethodAddEmailTemplateId: string, twoFactorMethodRemoveEmailTemplateId: string>, externalIdentifierConfiguration: record<twoFactorTrustIdTimeToLiveInSeconds: int>, formConfiguration: record<adminRegistrationFormId: string, selfServiceFormConfiguration: record, selfServiceFormId: string>, id: string, insertInstant: int, jwtConfiguration: record<accessTokenKeyId: string, idTokenKeyId: string, refreshTokenExpirationPolicy: string, refreshTokenOneTimeUseConfiguration: record, refreshTokenRevocationPolicy: record, refreshTokenSlidingWindowConfiguration: record, refreshTokenTimeToLiveInMinutes: int, refreshTokenUsagePolicy: string, timeToLiveInSeconds: int, enabled: bool>, lambdaConfiguration: record<accessTokenPopulateId: string, idTokenPopulateId: string, multiFactorRequirementId: string, samlv2PopulateId: string, selfServiceRegistrationValidationId: string, userinfoPopulateId: string>, lastUpdateInstant: int, loginConfiguration: record<allowTokenRefresh: bool, generateRefreshTokens: bool, requireAuthentication: bool>, multiFactorConfiguration: record<email: record, loginPolicy: string, sms: record, trustPolicy: string, voice: record>, name: string, oauthConfiguration: record<authorizedOriginURLs: list, authorizedRedirectURLs: list, authorizedResourceUris: list, authorizedURLValidationPolicy: string, clientAuthenticationPolicy: string, clientId: string, clientSecret: string, consentMode: string, debug: bool, deviceVerificationURL: string, enabledGrants: list, generateRefreshTokens: bool, logoutBehavior: string, logoutURL: string, proofKeyForCodeExchangePolicy: string, providedScopePolicy: record, relationship: string, requireClientAuthentication: bool, requireRegistration: bool, scopeHandlingPolicy: string, unknownScopePolicy: string>, passwordlessConfiguration: record<emailLoginStrategy: string, phoneLoginStrategy: string, enabled: bool>, phoneConfiguration: record<forgotPasswordTemplateId: string, identityUpdateTemplateId: string, loginIdInUseOnCreateTemplateId: string, loginIdInUseOnUpdateTemplateId: string, loginNewDeviceTemplateId: string, loginSuspiciousTemplateId: string, passwordResetSuccessTemplateId: string, passwordUpdateTemplateId: string, passwordlessTemplateId: string, setPasswordTemplateId: string, twoFactorMethodAddTemplateId: string, twoFactorMethodRemoveTemplateId: string, verificationCompleteTemplateId: string, verificationTemplateId: string>, registrationConfiguration: record<birthDate: record, completeRegistration: bool, confirmPassword: bool, firstName: record, formId: string, fullName: record, lastName: record, loginIdType: string, middleName: record, mobilePhone: record, preferredLanguages: record, type: string, enabled: bool>, registrationDeletePolicy: record<unverified: record>, roles: list<record>, samlv2Configuration: record<assertionEncryptionConfiguration: record, audience: string, authorizedRedirectURLs: list, debug: bool, defaultVerificationKeyId: string, initiatedLogin: record, issuer: string, keyId: string, loginHintConfiguration: record, logout: record, logoutURL: string, requireSignedRequests: bool, xmlSignatureC14nMethod: string, xmlSignatureLocation: string, callbackURL: string, enabled: bool>, scopes: list<record>, state: string, tenantId: string, themeId: string, universalConfiguration: record<universal: bool>, unverified: record<behavior: string>, verificationEmailTemplateId: string, verificationStrategy: string, verifyRegistration: bool, webAuthnConfiguration: record<bootstrapWorkflow: record, reauthenticationWorkflow: record, enabled: bool>>, applications: table<accessControlConfiguration: record, active: bool, authenticationTokenConfiguration: record, cleanSpeakConfiguration: record, data: record, emailConfiguration: record, externalIdentifierConfiguration: record, formConfiguration: record, id: string, insertInstant: int, jwtConfiguration: record, lambdaConfiguration: record, lastUpdateInstant: int, loginConfiguration: record, multiFactorConfiguration: record, name: string, oauthConfiguration: record, passwordlessConfiguration: record, phoneConfiguration: record, registrationConfiguration: record, registrationDeletePolicy: record, roles: list, samlv2Configuration: record, scopes: list, state: string, tenantId: string, themeId: string, universalConfiguration: record, unverified: record, verificationEmailTemplateId: string, verificationStrategy: string, verifyRegistration: bool, webAuthnConfiguration: record>, role: record<description: string, id: string, insertInstant: int, isDefault: bool, isSuperRole: bool, lastUpdateInstant: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reactivate" $reactivate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/application/($applicationId)" $qp)
  let body = {application: $application, role: $role, sourceApplicationId: $sourceApplicationId, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the application for the given Id or all the applications if the Id is null.
#
# GET /api/application/{applicationId}
# operationId: retrieveApplicationWithId
export def "application retrieveApplicationWithId" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
]: nothing -> record<application: record<accessControlConfiguration: record<uiIPAccessControlListId: string>, active: bool, authenticationTokenConfiguration: record<enabled: bool>, cleanSpeakConfiguration: record<apiKey: string, applicationIds: list, url: string, usernameModeration: record, enabled: bool>, data: record, emailConfiguration: record<emailUpdateEmailTemplateId: string, emailVerificationEmailTemplateId: string, emailVerifiedEmailTemplateId: string, forgotPasswordEmailTemplateId: string, loginIdInUseOnCreateEmailTemplateId: string, loginIdInUseOnUpdateEmailTemplateId: string, loginNewDeviceEmailTemplateId: string, loginSuspiciousEmailTemplateId: string, passwordResetSuccessEmailTemplateId: string, passwordUpdateEmailTemplateId: string, passwordlessEmailTemplateId: string, setPasswordEmailTemplateId: string, twoFactorMethodAddEmailTemplateId: string, twoFactorMethodRemoveEmailTemplateId: string>, externalIdentifierConfiguration: record<twoFactorTrustIdTimeToLiveInSeconds: int>, formConfiguration: record<adminRegistrationFormId: string, selfServiceFormConfiguration: record, selfServiceFormId: string>, id: string, insertInstant: int, jwtConfiguration: record<accessTokenKeyId: string, idTokenKeyId: string, refreshTokenExpirationPolicy: string, refreshTokenOneTimeUseConfiguration: record, refreshTokenRevocationPolicy: record, refreshTokenSlidingWindowConfiguration: record, refreshTokenTimeToLiveInMinutes: int, refreshTokenUsagePolicy: string, timeToLiveInSeconds: int, enabled: bool>, lambdaConfiguration: record<accessTokenPopulateId: string, idTokenPopulateId: string, multiFactorRequirementId: string, samlv2PopulateId: string, selfServiceRegistrationValidationId: string, userinfoPopulateId: string>, lastUpdateInstant: int, loginConfiguration: record<allowTokenRefresh: bool, generateRefreshTokens: bool, requireAuthentication: bool>, multiFactorConfiguration: record<email: record, loginPolicy: string, sms: record, trustPolicy: string, voice: record>, name: string, oauthConfiguration: record<authorizedOriginURLs: list, authorizedRedirectURLs: list, authorizedResourceUris: list, authorizedURLValidationPolicy: string, clientAuthenticationPolicy: string, clientId: string, clientSecret: string, consentMode: string, debug: bool, deviceVerificationURL: string, enabledGrants: list, generateRefreshTokens: bool, logoutBehavior: string, logoutURL: string, proofKeyForCodeExchangePolicy: string, providedScopePolicy: record, relationship: string, requireClientAuthentication: bool, requireRegistration: bool, scopeHandlingPolicy: string, unknownScopePolicy: string>, passwordlessConfiguration: record<emailLoginStrategy: string, phoneLoginStrategy: string, enabled: bool>, phoneConfiguration: record<forgotPasswordTemplateId: string, identityUpdateTemplateId: string, loginIdInUseOnCreateTemplateId: string, loginIdInUseOnUpdateTemplateId: string, loginNewDeviceTemplateId: string, loginSuspiciousTemplateId: string, passwordResetSuccessTemplateId: string, passwordUpdateTemplateId: string, passwordlessTemplateId: string, setPasswordTemplateId: string, twoFactorMethodAddTemplateId: string, twoFactorMethodRemoveTemplateId: string, verificationCompleteTemplateId: string, verificationTemplateId: string>, registrationConfiguration: record<birthDate: record, completeRegistration: bool, confirmPassword: bool, firstName: record, formId: string, fullName: record, lastName: record, loginIdType: string, middleName: record, mobilePhone: record, preferredLanguages: record, type: string, enabled: bool>, registrationDeletePolicy: record<unverified: record>, roles: list<record>, samlv2Configuration: record<assertionEncryptionConfiguration: record, audience: string, authorizedRedirectURLs: list, debug: bool, defaultVerificationKeyId: string, initiatedLogin: record, issuer: string, keyId: string, loginHintConfiguration: record, logout: record, logoutURL: string, requireSignedRequests: bool, xmlSignatureC14nMethod: string, xmlSignatureLocation: string, callbackURL: string, enabled: bool>, scopes: list<record>, state: string, tenantId: string, themeId: string, universalConfiguration: record<universal: bool>, unverified: record<behavior: string>, verificationEmailTemplateId: string, verificationStrategy: string, verifyRegistration: bool, webAuthnConfiguration: record<bootstrapWorkflow: record, reauthenticationWorkflow: record, enabled: bool>>, applications: table<accessControlConfiguration: record, active: bool, authenticationTokenConfiguration: record, cleanSpeakConfiguration: record, data: record, emailConfiguration: record, externalIdentifierConfiguration: record, formConfiguration: record, id: string, insertInstant: int, jwtConfiguration: record, lambdaConfiguration: record, lastUpdateInstant: int, loginConfiguration: record, multiFactorConfiguration: record, name: string, oauthConfiguration: record, passwordlessConfiguration: record, phoneConfiguration: record, registrationConfiguration: record, registrationDeletePolicy: record, roles: list, samlv2Configuration: record, scopes: list, state: string, tenantId: string, themeId: string, universalConfiguration: record, unverified: record, verificationEmailTemplateId: string, verificationStrategy: string, verifyRegistration: bool, webAuthnConfiguration: record>, role: record<description: string, id: string, insertInstant: int, isDefault: bool, isSuperRole: bool, lastUpdateInstant: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/application/($applicationId)")
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the Oauth2 configuration for the application for the given Application Id.
#
# GET /api/application/{applicationId}/oauth-configuration
# operationId: retrieveOauthConfigurationWithId
export def "application-oauth-configuration retrieveOauthConfigurationWithId" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
]: nothing -> record<httpSessionMaxInactiveInterval: int, logoutURL: string, oauthConfiguration: record<authorizedOriginURLs: list<string>, authorizedRedirectURLs: list<string>, authorizedResourceUris: list<string>, authorizedURLValidationPolicy: string, clientAuthenticationPolicy: string, clientId: string, clientSecret: string, consentMode: string, debug: bool, deviceVerificationURL: string, enabledGrants: list<any>, generateRefreshTokens: bool, logoutBehavior: string, logoutURL: string, proofKeyForCodeExchangePolicy: string, providedScopePolicy: record<address: record, email: record, phone: record, profile: record>, relationship: string, requireClientAuthentication: bool, requireRegistration: bool, scopeHandlingPolicy: string, unknownScopePolicy: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/application/($applicationId)/oauth-configuration")
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new role for an application. You must specify the Id of the application you are creating the role for. You can optionally specify an Id for the role inside the ApplicationRole object itself, if not provided one will be generated.
#
# POST /api/application/{applicationId}/role
# operationId: createApplicationRole
# --application shape: {accessControlConfiguration?: record, active?: bool, authenticationTokenConfiguration?: record, cleanSpeakConfiguration?: record, data?: record, emailConfiguration?: record, externalIdentifierConfiguration?: record, formConfiguration?: record, id?: string, insertInstant?: int, jwtConfiguration?: record, lambdaConfiguration?: record, lastUpdateInstant?: int, loginConfiguration?: record, multiFactorConfiguration?: record, name?: string, oauthConfiguration?: record, passwordlessConfiguration?: record, phoneConfiguration?: record, registrationConfiguration?: record, registrationDeletePolicy?: record, roles?: list, samlv2Configuration?: record, scopes?: list, state?: "Active"|"Inactive"|"PendingDelete", tenantId?: string, themeId?: string, universalConfiguration?: record, unverified?: record, verificationEmailTemplateId?: string, verificationStrategy?: "ClickableLink"|"FormField", verifyRegistration?: bool, webAuthnConfiguration?: record}
# --role shape: {description?: string, id?: string, insertInstant?: int, isDefault?: bool, isSuperRole?: bool, lastUpdateInstant?: int, name?: string}
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "application-role createApplicationRole" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --application: record # shape: {accessControlConfiguration?: record, active?: bool, authenticationTokenConfiguration?: record, cleanSpeakConfiguration?: record, data?: record, emailConfiguration?: record, externalIdentifierConfiguration?: record, formConfiguration?: record, id?: string, insertInstant?: int, jwtConfiguration?: record, lambdaConfiguration?: record, lastUpdateInstant?: int, loginConfiguration?: record, multiFactorConfiguration?: record, name?: string, oauthConfiguration?: record, passwordlessConfiguration?: record, phoneConfiguration?: record, registrationConfiguration?: record, registrationDeletePolicy?: record, roles?: list, samlv2Configuration?: record, scopes?: list, state?: "Active"|"Inactive"|"PendingDelete", tenantId?: string, themeId?: string, universalConfiguration?: record, unverified?: record, verificationEmailTemplateId?: string, verificationStrategy?: "ClickableLink"|"FormField", verifyRegistration?: bool, webAuthnConfiguration?: record}
  --role: record # A role given to a user for a specific application. — shape: {description?: string, id?: string, insertInstant?: int, isDefault?: bool, isSuperRole?: bool, lastUpdateInstant?: int, name?: string}
  --sourceApplicationId: string # format: uuid
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<application: record<accessControlConfiguration: record<uiIPAccessControlListId: string>, active: bool, authenticationTokenConfiguration: record<enabled: bool>, cleanSpeakConfiguration: record<apiKey: string, applicationIds: list, url: string, usernameModeration: record, enabled: bool>, data: record, emailConfiguration: record<emailUpdateEmailTemplateId: string, emailVerificationEmailTemplateId: string, emailVerifiedEmailTemplateId: string, forgotPasswordEmailTemplateId: string, loginIdInUseOnCreateEmailTemplateId: string, loginIdInUseOnUpdateEmailTemplateId: string, loginNewDeviceEmailTemplateId: string, loginSuspiciousEmailTemplateId: string, passwordResetSuccessEmailTemplateId: string, passwordUpdateEmailTemplateId: string, passwordlessEmailTemplateId: string, setPasswordEmailTemplateId: string, twoFactorMethodAddEmailTemplateId: string, twoFactorMethodRemoveEmailTemplateId: string>, externalIdentifierConfiguration: record<twoFactorTrustIdTimeToLiveInSeconds: int>, formConfiguration: record<adminRegistrationFormId: string, selfServiceFormConfiguration: record, selfServiceFormId: string>, id: string, insertInstant: int, jwtConfiguration: record<accessTokenKeyId: string, idTokenKeyId: string, refreshTokenExpirationPolicy: string, refreshTokenOneTimeUseConfiguration: record, refreshTokenRevocationPolicy: record, refreshTokenSlidingWindowConfiguration: record, refreshTokenTimeToLiveInMinutes: int, refreshTokenUsagePolicy: string, timeToLiveInSeconds: int, enabled: bool>, lambdaConfiguration: record<accessTokenPopulateId: string, idTokenPopulateId: string, multiFactorRequirementId: string, samlv2PopulateId: string, selfServiceRegistrationValidationId: string, userinfoPopulateId: string>, lastUpdateInstant: int, loginConfiguration: record<allowTokenRefresh: bool, generateRefreshTokens: bool, requireAuthentication: bool>, multiFactorConfiguration: record<email: record, loginPolicy: string, sms: record, trustPolicy: string, voice: record>, name: string, oauthConfiguration: record<authorizedOriginURLs: list, authorizedRedirectURLs: list, authorizedResourceUris: list, authorizedURLValidationPolicy: string, clientAuthenticationPolicy: string, clientId: string, clientSecret: string, consentMode: string, debug: bool, deviceVerificationURL: string, enabledGrants: list, generateRefreshTokens: bool, logoutBehavior: string, logoutURL: string, proofKeyForCodeExchangePolicy: string, providedScopePolicy: record, relationship: string, requireClientAuthentication: bool, requireRegistration: bool, scopeHandlingPolicy: string, unknownScopePolicy: string>, passwordlessConfiguration: record<emailLoginStrategy: string, phoneLoginStrategy: string, enabled: bool>, phoneConfiguration: record<forgotPasswordTemplateId: string, identityUpdateTemplateId: string, loginIdInUseOnCreateTemplateId: string, loginIdInUseOnUpdateTemplateId: string, loginNewDeviceTemplateId: string, loginSuspiciousTemplateId: string, passwordResetSuccessTemplateId: string, passwordUpdateTemplateId: string, passwordlessTemplateId: string, setPasswordTemplateId: string, twoFactorMethodAddTemplateId: string, twoFactorMethodRemoveTemplateId: string, verificationCompleteTemplateId: string, verificationTemplateId: string>, registrationConfiguration: record<birthDate: record, completeRegistration: bool, confirmPassword: bool, firstName: record, formId: string, fullName: record, lastName: record, loginIdType: string, middleName: record, mobilePhone: record, preferredLanguages: record, type: string, enabled: bool>, registrationDeletePolicy: record<unverified: record>, roles: list<record>, samlv2Configuration: record<assertionEncryptionConfiguration: record, audience: string, authorizedRedirectURLs: list, debug: bool, defaultVerificationKeyId: string, initiatedLogin: record, issuer: string, keyId: string, loginHintConfiguration: record, logout: record, logoutURL: string, requireSignedRequests: bool, xmlSignatureC14nMethod: string, xmlSignatureLocation: string, callbackURL: string, enabled: bool>, scopes: list<record>, state: string, tenantId: string, themeId: string, universalConfiguration: record<universal: bool>, unverified: record<behavior: string>, verificationEmailTemplateId: string, verificationStrategy: string, verifyRegistration: bool, webAuthnConfiguration: record<bootstrapWorkflow: record, reauthenticationWorkflow: record, enabled: bool>>, applications: table<accessControlConfiguration: record, active: bool, authenticationTokenConfiguration: record, cleanSpeakConfiguration: record, data: record, emailConfiguration: record, externalIdentifierConfiguration: record, formConfiguration: record, id: string, insertInstant: int, jwtConfiguration: record, lambdaConfiguration: record, lastUpdateInstant: int, loginConfiguration: record, multiFactorConfiguration: record, name: string, oauthConfiguration: record, passwordlessConfiguration: record, phoneConfiguration: record, registrationConfiguration: record, registrationDeletePolicy: record, roles: list, samlv2Configuration: record, scopes: list, state: string, tenantId: string, themeId: string, universalConfiguration: record, unverified: record, verificationEmailTemplateId: string, verificationStrategy: string, verifyRegistration: bool, webAuthnConfiguration: record>, role: record<description: string, id: string, insertInstant: int, isDefault: bool, isSuperRole: bool, lastUpdateInstant: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/application/($applicationId)/role")
  let body = {application: $application, role: $role, sourceApplicationId: $sourceApplicationId, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a new role for an application. You must specify the Id of the application you are creating the role for. You can optionally specify an Id for the role inside the ApplicationRole object itself, if not provided one will be generated.
#
# POST /api/application/{applicationId}/role/{roleId}
# operationId: createApplicationRoleWithId
# --application shape: {accessControlConfiguration?: record, active?: bool, authenticationTokenConfiguration?: record, cleanSpeakConfiguration?: record, data?: record, emailConfiguration?: record, externalIdentifierConfiguration?: record, formConfiguration?: record, id?: string, insertInstant?: int, jwtConfiguration?: record, lambdaConfiguration?: record, lastUpdateInstant?: int, loginConfiguration?: record, multiFactorConfiguration?: record, name?: string, oauthConfiguration?: record, passwordlessConfiguration?: record, phoneConfiguration?: record, registrationConfiguration?: record, registrationDeletePolicy?: record, roles?: list, samlv2Configuration?: record, scopes?: list, state?: "Active"|"Inactive"|"PendingDelete", tenantId?: string, themeId?: string, universalConfiguration?: record, unverified?: record, verificationEmailTemplateId?: string, verificationStrategy?: "ClickableLink"|"FormField", verifyRegistration?: bool, webAuthnConfiguration?: record}
# --role shape: {description?: string, id?: string, insertInstant?: int, isDefault?: bool, isSuperRole?: bool, lastUpdateInstant?: int, name?: string}
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "application-role createApplicationRoleWithId" [
  applicationId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --application: record # shape: {accessControlConfiguration?: record, active?: bool, authenticationTokenConfiguration?: record, cleanSpeakConfiguration?: record, data?: record, emailConfiguration?: record, externalIdentifierConfiguration?: record, formConfiguration?: record, id?: string, insertInstant?: int, jwtConfiguration?: record, lambdaConfiguration?: record, lastUpdateInstant?: int, loginConfiguration?: record, multiFactorConfiguration?: record, name?: string, oauthConfiguration?: record, passwordlessConfiguration?: record, phoneConfiguration?: record, registrationConfiguration?: record, registrationDeletePolicy?: record, roles?: list, samlv2Configuration?: record, scopes?: list, state?: "Active"|"Inactive"|"PendingDelete", tenantId?: string, themeId?: string, universalConfiguration?: record, unverified?: record, verificationEmailTemplateId?: string, verificationStrategy?: "ClickableLink"|"FormField", verifyRegistration?: bool, webAuthnConfiguration?: record}
  --role: record # A role given to a user for a specific application. — shape: {description?: string, id?: string, insertInstant?: int, isDefault?: bool, isSuperRole?: bool, lastUpdateInstant?: int, name?: string}
  --sourceApplicationId: string # format: uuid
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<application: record<accessControlConfiguration: record<uiIPAccessControlListId: string>, active: bool, authenticationTokenConfiguration: record<enabled: bool>, cleanSpeakConfiguration: record<apiKey: string, applicationIds: list, url: string, usernameModeration: record, enabled: bool>, data: record, emailConfiguration: record<emailUpdateEmailTemplateId: string, emailVerificationEmailTemplateId: string, emailVerifiedEmailTemplateId: string, forgotPasswordEmailTemplateId: string, loginIdInUseOnCreateEmailTemplateId: string, loginIdInUseOnUpdateEmailTemplateId: string, loginNewDeviceEmailTemplateId: string, loginSuspiciousEmailTemplateId: string, passwordResetSuccessEmailTemplateId: string, passwordUpdateEmailTemplateId: string, passwordlessEmailTemplateId: string, setPasswordEmailTemplateId: string, twoFactorMethodAddEmailTemplateId: string, twoFactorMethodRemoveEmailTemplateId: string>, externalIdentifierConfiguration: record<twoFactorTrustIdTimeToLiveInSeconds: int>, formConfiguration: record<adminRegistrationFormId: string, selfServiceFormConfiguration: record, selfServiceFormId: string>, id: string, insertInstant: int, jwtConfiguration: record<accessTokenKeyId: string, idTokenKeyId: string, refreshTokenExpirationPolicy: string, refreshTokenOneTimeUseConfiguration: record, refreshTokenRevocationPolicy: record, refreshTokenSlidingWindowConfiguration: record, refreshTokenTimeToLiveInMinutes: int, refreshTokenUsagePolicy: string, timeToLiveInSeconds: int, enabled: bool>, lambdaConfiguration: record<accessTokenPopulateId: string, idTokenPopulateId: string, multiFactorRequirementId: string, samlv2PopulateId: string, selfServiceRegistrationValidationId: string, userinfoPopulateId: string>, lastUpdateInstant: int, loginConfiguration: record<allowTokenRefresh: bool, generateRefreshTokens: bool, requireAuthentication: bool>, multiFactorConfiguration: record<email: record, loginPolicy: string, sms: record, trustPolicy: string, voice: record>, name: string, oauthConfiguration: record<authorizedOriginURLs: list, authorizedRedirectURLs: list, authorizedResourceUris: list, authorizedURLValidationPolicy: string, clientAuthenticationPolicy: string, clientId: string, clientSecret: string, consentMode: string, debug: bool, deviceVerificationURL: string, enabledGrants: list, generateRefreshTokens: bool, logoutBehavior: string, logoutURL: string, proofKeyForCodeExchangePolicy: string, providedScopePolicy: record, relationship: string, requireClientAuthentication: bool, requireRegistration: bool, scopeHandlingPolicy: string, unknownScopePolicy: string>, passwordlessConfiguration: record<emailLoginStrategy: string, phoneLoginStrategy: string, enabled: bool>, phoneConfiguration: record<forgotPasswordTemplateId: string, identityUpdateTemplateId: string, loginIdInUseOnCreateTemplateId: string, loginIdInUseOnUpdateTemplateId: string, loginNewDeviceTemplateId: string, loginSuspiciousTemplateId: string, passwordResetSuccessTemplateId: string, passwordUpdateTemplateId: string, passwordlessTemplateId: string, setPasswordTemplateId: string, twoFactorMethodAddTemplateId: string, twoFactorMethodRemoveTemplateId: string, verificationCompleteTemplateId: string, verificationTemplateId: string>, registrationConfiguration: record<birthDate: record, completeRegistration: bool, confirmPassword: bool, firstName: record, formId: string, fullName: record, lastName: record, loginIdType: string, middleName: record, mobilePhone: record, preferredLanguages: record, type: string, enabled: bool>, registrationDeletePolicy: record<unverified: record>, roles: list<record>, samlv2Configuration: record<assertionEncryptionConfiguration: record, audience: string, authorizedRedirectURLs: list, debug: bool, defaultVerificationKeyId: string, initiatedLogin: record, issuer: string, keyId: string, loginHintConfiguration: record, logout: record, logoutURL: string, requireSignedRequests: bool, xmlSignatureC14nMethod: string, xmlSignatureLocation: string, callbackURL: string, enabled: bool>, scopes: list<record>, state: string, tenantId: string, themeId: string, universalConfiguration: record<universal: bool>, unverified: record<behavior: string>, verificationEmailTemplateId: string, verificationStrategy: string, verifyRegistration: bool, webAuthnConfiguration: record<bootstrapWorkflow: record, reauthenticationWorkflow: record, enabled: bool>>, applications: table<accessControlConfiguration: record, active: bool, authenticationTokenConfiguration: record, cleanSpeakConfiguration: record, data: record, emailConfiguration: record, externalIdentifierConfiguration: record, formConfiguration: record, id: string, insertInstant: int, jwtConfiguration: record, lambdaConfiguration: record, lastUpdateInstant: int, loginConfiguration: record, multiFactorConfiguration: record, name: string, oauthConfiguration: record, passwordlessConfiguration: record, phoneConfiguration: record, registrationConfiguration: record, registrationDeletePolicy: record, roles: list, samlv2Configuration: record, scopes: list, state: string, tenantId: string, themeId: string, universalConfiguration: record, unverified: record, verificationEmailTemplateId: string, verificationStrategy: string, verifyRegistration: bool, webAuthnConfiguration: record>, role: record<description: string, id: string, insertInstant: int, isDefault: bool, isSuperRole: bool, lastUpdateInstant: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/application/($applicationId)/role/($roleId)")
  let body = {application: $application, role: $role, sourceApplicationId: $sourceApplicationId, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Hard deletes an application role. This is a dangerous operation and should not be used in most circumstances. This permanently removes the given role from all users that had it.
#
# DELETE /api/application/{applicationId}/role/{roleId}
# operationId: deleteApplicationRoleWithId
export def "application-role delete" [
  applicationId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
]: nothing -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/application/($applicationId)/role/($roleId)")
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates, via PATCH, the application role with the given Id for the application.
#
# PATCH /api/application/{applicationId}/role/{roleId}
# operationId: patchApplicationRoleWithId
# --application shape: {accessControlConfiguration?: record, active?: bool, authenticationTokenConfiguration?: record, cleanSpeakConfiguration?: record, data?: record, emailConfiguration?: record, externalIdentifierConfiguration?: record, formConfiguration?: record, id?: string, insertInstant?: int, jwtConfiguration?: record, lambdaConfiguration?: record, lastUpdateInstant?: int, loginConfiguration?: record, multiFactorConfiguration?: record, name?: string, oauthConfiguration?: record, passwordlessConfiguration?: record, phoneConfiguration?: record, registrationConfiguration?: record, registrationDeletePolicy?: record, roles?: list, samlv2Configuration?: record, scopes?: list, state?: "Active"|"Inactive"|"PendingDelete", tenantId?: string, themeId?: string, universalConfiguration?: record, unverified?: record, verificationEmailTemplateId?: string, verificationStrategy?: "ClickableLink"|"FormField", verifyRegistration?: bool, webAuthnConfiguration?: record}
# --role shape: {description?: string, id?: string, insertInstant?: int, isDefault?: bool, isSuperRole?: bool, lastUpdateInstant?: int, name?: string}
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "application-role patch" [
  applicationId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --application: record # shape: {accessControlConfiguration?: record, active?: bool, authenticationTokenConfiguration?: record, cleanSpeakConfiguration?: record, data?: record, emailConfiguration?: record, externalIdentifierConfiguration?: record, formConfiguration?: record, id?: string, insertInstant?: int, jwtConfiguration?: record, lambdaConfiguration?: record, lastUpdateInstant?: int, loginConfiguration?: record, multiFactorConfiguration?: record, name?: string, oauthConfiguration?: record, passwordlessConfiguration?: record, phoneConfiguration?: record, registrationConfiguration?: record, registrationDeletePolicy?: record, roles?: list, samlv2Configuration?: record, scopes?: list, state?: "Active"|"Inactive"|"PendingDelete", tenantId?: string, themeId?: string, universalConfiguration?: record, unverified?: record, verificationEmailTemplateId?: string, verificationStrategy?: "ClickableLink"|"FormField", verifyRegistration?: bool, webAuthnConfiguration?: record}
  --role: record # A role given to a user for a specific application. — shape: {description?: string, id?: string, insertInstant?: int, isDefault?: bool, isSuperRole?: bool, lastUpdateInstant?: int, name?: string}
  --sourceApplicationId: string # format: uuid
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<application: record<accessControlConfiguration: record<uiIPAccessControlListId: string>, active: bool, authenticationTokenConfiguration: record<enabled: bool>, cleanSpeakConfiguration: record<apiKey: string, applicationIds: list, url: string, usernameModeration: record, enabled: bool>, data: record, emailConfiguration: record<emailUpdateEmailTemplateId: string, emailVerificationEmailTemplateId: string, emailVerifiedEmailTemplateId: string, forgotPasswordEmailTemplateId: string, loginIdInUseOnCreateEmailTemplateId: string, loginIdInUseOnUpdateEmailTemplateId: string, loginNewDeviceEmailTemplateId: string, loginSuspiciousEmailTemplateId: string, passwordResetSuccessEmailTemplateId: string, passwordUpdateEmailTemplateId: string, passwordlessEmailTemplateId: string, setPasswordEmailTemplateId: string, twoFactorMethodAddEmailTemplateId: string, twoFactorMethodRemoveEmailTemplateId: string>, externalIdentifierConfiguration: record<twoFactorTrustIdTimeToLiveInSeconds: int>, formConfiguration: record<adminRegistrationFormId: string, selfServiceFormConfiguration: record, selfServiceFormId: string>, id: string, insertInstant: int, jwtConfiguration: record<accessTokenKeyId: string, idTokenKeyId: string, refreshTokenExpirationPolicy: string, refreshTokenOneTimeUseConfiguration: record, refreshTokenRevocationPolicy: record, refreshTokenSlidingWindowConfiguration: record, refreshTokenTimeToLiveInMinutes: int, refreshTokenUsagePolicy: string, timeToLiveInSeconds: int, enabled: bool>, lambdaConfiguration: record<accessTokenPopulateId: string, idTokenPopulateId: string, multiFactorRequirementId: string, samlv2PopulateId: string, selfServiceRegistrationValidationId: string, userinfoPopulateId: string>, lastUpdateInstant: int, loginConfiguration: record<allowTokenRefresh: bool, generateRefreshTokens: bool, requireAuthentication: bool>, multiFactorConfiguration: record<email: record, loginPolicy: string, sms: record, trustPolicy: string, voice: record>, name: string, oauthConfiguration: record<authorizedOriginURLs: list, authorizedRedirectURLs: list, authorizedResourceUris: list, authorizedURLValidationPolicy: string, clientAuthenticationPolicy: string, clientId: string, clientSecret: string, consentMode: string, debug: bool, deviceVerificationURL: string, enabledGrants: list, generateRefreshTokens: bool, logoutBehavior: string, logoutURL: string, proofKeyForCodeExchangePolicy: string, providedScopePolicy: record, relationship: string, requireClientAuthentication: bool, requireRegistration: bool, scopeHandlingPolicy: string, unknownScopePolicy: string>, passwordlessConfiguration: record<emailLoginStrategy: string, phoneLoginStrategy: string, enabled: bool>, phoneConfiguration: record<forgotPasswordTemplateId: string, identityUpdateTemplateId: string, loginIdInUseOnCreateTemplateId: string, loginIdInUseOnUpdateTemplateId: string, loginNewDeviceTemplateId: string, loginSuspiciousTemplateId: string, passwordResetSuccessTemplateId: string, passwordUpdateTemplateId: string, passwordlessTemplateId: string, setPasswordTemplateId: string, twoFactorMethodAddTemplateId: string, twoFactorMethodRemoveTemplateId: string, verificationCompleteTemplateId: string, verificationTemplateId: string>, registrationConfiguration: record<birthDate: record, completeRegistration: bool, confirmPassword: bool, firstName: record, formId: string, fullName: record, lastName: record, loginIdType: string, middleName: record, mobilePhone: record, preferredLanguages: record, type: string, enabled: bool>, registrationDeletePolicy: record<unverified: record>, roles: list<record>, samlv2Configuration: record<assertionEncryptionConfiguration: record, audience: string, authorizedRedirectURLs: list, debug: bool, defaultVerificationKeyId: string, initiatedLogin: record, issuer: string, keyId: string, loginHintConfiguration: record, logout: record, logoutURL: string, requireSignedRequests: bool, xmlSignatureC14nMethod: string, xmlSignatureLocation: string, callbackURL: string, enabled: bool>, scopes: list<record>, state: string, tenantId: string, themeId: string, universalConfiguration: record<universal: bool>, unverified: record<behavior: string>, verificationEmailTemplateId: string, verificationStrategy: string, verifyRegistration: bool, webAuthnConfiguration: record<bootstrapWorkflow: record, reauthenticationWorkflow: record, enabled: bool>>, applications: table<accessControlConfiguration: record, active: bool, authenticationTokenConfiguration: record, cleanSpeakConfiguration: record, data: record, emailConfiguration: record, externalIdentifierConfiguration: record, formConfiguration: record, id: string, insertInstant: int, jwtConfiguration: record, lambdaConfiguration: record, lastUpdateInstant: int, loginConfiguration: record, multiFactorConfiguration: record, name: string, oauthConfiguration: record, passwordlessConfiguration: record, phoneConfiguration: record, registrationConfiguration: record, registrationDeletePolicy: record, roles: list, samlv2Configuration: record, scopes: list, state: string, tenantId: string, themeId: string, universalConfiguration: record, unverified: record, verificationEmailTemplateId: string, verificationStrategy: string, verifyRegistration: bool, webAuthnConfiguration: record>, role: record<description: string, id: string, insertInstant: int, isDefault: bool, isSuperRole: bool, lastUpdateInstant: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/application/($applicationId)/role/($roleId)")
  let body = {application: $application, role: $role, sourceApplicationId: $sourceApplicationId, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates the application role with the given Id for the application.
#
# PUT /api/application/{applicationId}/role/{roleId}
# operationId: updateApplicationRoleWithId
# --application shape: {accessControlConfiguration?: record, active?: bool, authenticationTokenConfiguration?: record, cleanSpeakConfiguration?: record, data?: record, emailConfiguration?: record, externalIdentifierConfiguration?: record, formConfiguration?: record, id?: string, insertInstant?: int, jwtConfiguration?: record, lambdaConfiguration?: record, lastUpdateInstant?: int, loginConfiguration?: record, multiFactorConfiguration?: record, name?: string, oauthConfiguration?: record, passwordlessConfiguration?: record, phoneConfiguration?: record, registrationConfiguration?: record, registrationDeletePolicy?: record, roles?: list, samlv2Configuration?: record, scopes?: list, state?: "Active"|"Inactive"|"PendingDelete", tenantId?: string, themeId?: string, universalConfiguration?: record, unverified?: record, verificationEmailTemplateId?: string, verificationStrategy?: "ClickableLink"|"FormField", verifyRegistration?: bool, webAuthnConfiguration?: record}
# --role shape: {description?: string, id?: string, insertInstant?: int, isDefault?: bool, isSuperRole?: bool, lastUpdateInstant?: int, name?: string}
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "application-role updateApplicationRoleWithId" [
  applicationId: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --application: record # shape: {accessControlConfiguration?: record, active?: bool, authenticationTokenConfiguration?: record, cleanSpeakConfiguration?: record, data?: record, emailConfiguration?: record, externalIdentifierConfiguration?: record, formConfiguration?: record, id?: string, insertInstant?: int, jwtConfiguration?: record, lambdaConfiguration?: record, lastUpdateInstant?: int, loginConfiguration?: record, multiFactorConfiguration?: record, name?: string, oauthConfiguration?: record, passwordlessConfiguration?: record, phoneConfiguration?: record, registrationConfiguration?: record, registrationDeletePolicy?: record, roles?: list, samlv2Configuration?: record, scopes?: list, state?: "Active"|"Inactive"|"PendingDelete", tenantId?: string, themeId?: string, universalConfiguration?: record, unverified?: record, verificationEmailTemplateId?: string, verificationStrategy?: "ClickableLink"|"FormField", verifyRegistration?: bool, webAuthnConfiguration?: record}
  --role: record # A role given to a user for a specific application. — shape: {description?: string, id?: string, insertInstant?: int, isDefault?: bool, isSuperRole?: bool, lastUpdateInstant?: int, name?: string}
  --sourceApplicationId: string # format: uuid
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<application: record<accessControlConfiguration: record<uiIPAccessControlListId: string>, active: bool, authenticationTokenConfiguration: record<enabled: bool>, cleanSpeakConfiguration: record<apiKey: string, applicationIds: list, url: string, usernameModeration: record, enabled: bool>, data: record, emailConfiguration: record<emailUpdateEmailTemplateId: string, emailVerificationEmailTemplateId: string, emailVerifiedEmailTemplateId: string, forgotPasswordEmailTemplateId: string, loginIdInUseOnCreateEmailTemplateId: string, loginIdInUseOnUpdateEmailTemplateId: string, loginNewDeviceEmailTemplateId: string, loginSuspiciousEmailTemplateId: string, passwordResetSuccessEmailTemplateId: string, passwordUpdateEmailTemplateId: string, passwordlessEmailTemplateId: string, setPasswordEmailTemplateId: string, twoFactorMethodAddEmailTemplateId: string, twoFactorMethodRemoveEmailTemplateId: string>, externalIdentifierConfiguration: record<twoFactorTrustIdTimeToLiveInSeconds: int>, formConfiguration: record<adminRegistrationFormId: string, selfServiceFormConfiguration: record, selfServiceFormId: string>, id: string, insertInstant: int, jwtConfiguration: record<accessTokenKeyId: string, idTokenKeyId: string, refreshTokenExpirationPolicy: string, refreshTokenOneTimeUseConfiguration: record, refreshTokenRevocationPolicy: record, refreshTokenSlidingWindowConfiguration: record, refreshTokenTimeToLiveInMinutes: int, refreshTokenUsagePolicy: string, timeToLiveInSeconds: int, enabled: bool>, lambdaConfiguration: record<accessTokenPopulateId: string, idTokenPopulateId: string, multiFactorRequirementId: string, samlv2PopulateId: string, selfServiceRegistrationValidationId: string, userinfoPopulateId: string>, lastUpdateInstant: int, loginConfiguration: record<allowTokenRefresh: bool, generateRefreshTokens: bool, requireAuthentication: bool>, multiFactorConfiguration: record<email: record, loginPolicy: string, sms: record, trustPolicy: string, voice: record>, name: string, oauthConfiguration: record<authorizedOriginURLs: list, authorizedRedirectURLs: list, authorizedResourceUris: list, authorizedURLValidationPolicy: string, clientAuthenticationPolicy: string, clientId: string, clientSecret: string, consentMode: string, debug: bool, deviceVerificationURL: string, enabledGrants: list, generateRefreshTokens: bool, logoutBehavior: string, logoutURL: string, proofKeyForCodeExchangePolicy: string, providedScopePolicy: record, relationship: string, requireClientAuthentication: bool, requireRegistration: bool, scopeHandlingPolicy: string, unknownScopePolicy: string>, passwordlessConfiguration: record<emailLoginStrategy: string, phoneLoginStrategy: string, enabled: bool>, phoneConfiguration: record<forgotPasswordTemplateId: string, identityUpdateTemplateId: string, loginIdInUseOnCreateTemplateId: string, loginIdInUseOnUpdateTemplateId: string, loginNewDeviceTemplateId: string, loginSuspiciousTemplateId: string, passwordResetSuccessTemplateId: string, passwordUpdateTemplateId: string, passwordlessTemplateId: string, setPasswordTemplateId: string, twoFactorMethodAddTemplateId: string, twoFactorMethodRemoveTemplateId: string, verificationCompleteTemplateId: string, verificationTemplateId: string>, registrationConfiguration: record<birthDate: record, completeRegistration: bool, confirmPassword: bool, firstName: record, formId: string, fullName: record, lastName: record, loginIdType: string, middleName: record, mobilePhone: record, preferredLanguages: record, type: string, enabled: bool>, registrationDeletePolicy: record<unverified: record>, roles: list<record>, samlv2Configuration: record<assertionEncryptionConfiguration: record, audience: string, authorizedRedirectURLs: list, debug: bool, defaultVerificationKeyId: string, initiatedLogin: record, issuer: string, keyId: string, loginHintConfiguration: record, logout: record, logoutURL: string, requireSignedRequests: bool, xmlSignatureC14nMethod: string, xmlSignatureLocation: string, callbackURL: string, enabled: bool>, scopes: list<record>, state: string, tenantId: string, themeId: string, universalConfiguration: record<universal: bool>, unverified: record<behavior: string>, verificationEmailTemplateId: string, verificationStrategy: string, verifyRegistration: bool, webAuthnConfiguration: record<bootstrapWorkflow: record, reauthenticationWorkflow: record, enabled: bool>>, applications: table<accessControlConfiguration: record, active: bool, authenticationTokenConfiguration: record, cleanSpeakConfiguration: record, data: record, emailConfiguration: record, externalIdentifierConfiguration: record, formConfiguration: record, id: string, insertInstant: int, jwtConfiguration: record, lambdaConfiguration: record, lastUpdateInstant: int, loginConfiguration: record, multiFactorConfiguration: record, name: string, oauthConfiguration: record, passwordlessConfiguration: record, phoneConfiguration: record, registrationConfiguration: record, registrationDeletePolicy: record, roles: list, samlv2Configuration: record, scopes: list, state: string, tenantId: string, themeId: string, universalConfiguration: record, unverified: record, verificationEmailTemplateId: string, verificationStrategy: string, verifyRegistration: bool, webAuthnConfiguration: record>, role: record<description: string, id: string, insertInstant: int, isDefault: bool, isSuperRole: bool, lastUpdateInstant: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/application/($applicationId)/role/($roleId)")
  let body = {application: $application, role: $role, sourceApplicationId: $sourceApplicationId, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a new custom OAuth scope for an application. You must specify the Id of the application you are creating the scope for. You can optionally specify an Id for the OAuth scope on the URL, if not provided one will be generated.
#
# POST /api/application/{applicationId}/scope
# operationId: createOAuthScope
# --scope shape: {applicationId?: string, data?: record, defaultConsentDetail?: string, defaultConsentMessage?: string, description?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, required?: bool}
export def "application-scope createOAuthScope" [
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --scope: record # A custom OAuth scope for a specific application. — shape: {applicationId?: string, data?: record, defaultConsentDetail?: string, defaultConsentMessage?: string, description?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, required?: bool}
]: any -> record<scope: record<applicationId: string, data: record, defaultConsentDetail: string, defaultConsentMessage: string, description: string, id: string, insertInstant: int, lastUpdateInstant: int, name: string, required: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/application/($applicationId)/scope")
  let body = {scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a new custom OAuth scope for an application. You must specify the Id of the application you are creating the scope for. You can optionally specify an Id for the OAuth scope on the URL, if not provided one will be generated.
#
# POST /api/application/{applicationId}/scope/{scopeId}
# operationId: createOAuthScopeWithId
# --scope shape: {applicationId?: string, data?: record, defaultConsentDetail?: string, defaultConsentMessage?: string, description?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, required?: bool}
export def "application-scope createOAuthScopeWithId" [
  applicationId: string
  scopeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --scope: record # A custom OAuth scope for a specific application. — shape: {applicationId?: string, data?: record, defaultConsentDetail?: string, defaultConsentMessage?: string, description?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, required?: bool}
]: any -> record<scope: record<applicationId: string, data: record, defaultConsentDetail: string, defaultConsentMessage: string, description: string, id: string, insertInstant: int, lastUpdateInstant: int, name: string, required: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/application/($applicationId)/scope/($scopeId)")
  let body = {scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Hard deletes a custom OAuth scope. OAuth workflows that are still requesting the deleted OAuth scope may fail depending on the application's unknown scope policy.
#
# DELETE /api/application/{applicationId}/scope/{scopeId}
# operationId: deleteOAuthScopeWithId
export def "application-scope delete" [
  applicationId: string
  scopeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
]: nothing -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/application/($applicationId)/scope/($scopeId)")
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates, via PATCH, the custom OAuth scope with the given Id for the application.
#
# PATCH /api/application/{applicationId}/scope/{scopeId}
# operationId: patchOAuthScopeWithId
# --scope shape: {applicationId?: string, data?: record, defaultConsentDetail?: string, defaultConsentMessage?: string, description?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, required?: bool}
export def "application-scope patch" [
  applicationId: string
  scopeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --scope: record # A custom OAuth scope for a specific application. — shape: {applicationId?: string, data?: record, defaultConsentDetail?: string, defaultConsentMessage?: string, description?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, required?: bool}
]: any -> record<scope: record<applicationId: string, data: record, defaultConsentDetail: string, defaultConsentMessage: string, description: string, id: string, insertInstant: int, lastUpdateInstant: int, name: string, required: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/application/($applicationId)/scope/($scopeId)")
  let body = {scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves a custom OAuth scope.
#
# GET /api/application/{applicationId}/scope/{scopeId}
# operationId: retrieveOAuthScopeWithId
export def "application-scope retrieveOAuthScopeWithId" [
  applicationId: string
  scopeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
]: nothing -> record<scope: record<applicationId: string, data: record, defaultConsentDetail: string, defaultConsentMessage: string, description: string, id: string, insertInstant: int, lastUpdateInstant: int, name: string, required: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/application/($applicationId)/scope/($scopeId)")
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the OAuth scope with the given Id for the application.
#
# PUT /api/application/{applicationId}/scope/{scopeId}
# operationId: updateOAuthScopeWithId
# --scope shape: {applicationId?: string, data?: record, defaultConsentDetail?: string, defaultConsentMessage?: string, description?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, required?: bool}
export def "application-scope updateOAuthScopeWithId" [
  applicationId: string
  scopeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --scope: record # A custom OAuth scope for a specific application. — shape: {applicationId?: string, data?: record, defaultConsentDetail?: string, defaultConsentMessage?: string, description?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, required?: bool}
]: any -> record<scope: record<applicationId: string, data: record, defaultConsentDetail: string, defaultConsentMessage: string, description: string, id: string, insertInstant: int, lastUpdateInstant: int, name: string, required: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/application/($applicationId)/scope/($scopeId)")
  let body = {scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a connector.  You can optionally specify an Id for the connector, if not provided one will be generated.
#
# POST /api/connector
# operationId: createConnector
# --connector shape: {data?: record, debug?: bool, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, type?: "FusionAuth"|"Generic"|"LDAP"}
export def "connector createConnector" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --connector: record # Do not require a setter for 'type', it is defined by the concrete class and is not mutable — shape: {data?: record, debug?: bool, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, type?: "FusionAuth"|"Generic"|"LDAP"}
]: any -> record<connector: record<data: record, debug: bool, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>, connectors: table<data: record, debug: bool, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/connector")
  let body = {connector: $connector} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a connector.  You can optionally specify an Id for the connector, if not provided one will be generated.
#
# POST /api/connector/{connectorId}
# operationId: createConnectorWithId
# --connector shape: {data?: record, debug?: bool, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, type?: "FusionAuth"|"Generic"|"LDAP"}
export def "connector createConnectorWithId" [
  connectorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --connector: record # Do not require a setter for 'type', it is defined by the concrete class and is not mutable — shape: {data?: record, debug?: bool, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, type?: "FusionAuth"|"Generic"|"LDAP"}
]: any -> record<connector: record<data: record, debug: bool, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>, connectors: table<data: record, debug: bool, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/connector/($connectorId)")
  let body = {connector: $connector} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the connector for the given Id.
#
# DELETE /api/connector/{connectorId}
# operationId: deleteConnectorWithId
export def "connector delete" [
  connectorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/connector/($connectorId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates, via PATCH, the connector with the given Id.
#
# PATCH /api/connector/{connectorId}
# operationId: patchConnectorWithId
# --connector shape: {data?: record, debug?: bool, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, type?: "FusionAuth"|"Generic"|"LDAP"}
export def "connector patch" [
  connectorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --connector: record # Do not require a setter for 'type', it is defined by the concrete class and is not mutable — shape: {data?: record, debug?: bool, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, type?: "FusionAuth"|"Generic"|"LDAP"}
]: any -> record<connector: record<data: record, debug: bool, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>, connectors: table<data: record, debug: bool, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/connector/($connectorId)")
  let body = {connector: $connector} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the connector with the given Id.
#
# GET /api/connector/{connectorId}
# operationId: retrieveConnectorWithId
export def "connector retrieveConnectorWithId" [
  connectorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<connector: record<data: record, debug: bool, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>, connectors: table<data: record, debug: bool, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/connector/($connectorId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the connector with the given Id.
#
# PUT /api/connector/{connectorId}
# operationId: updateConnectorWithId
# --connector shape: {data?: record, debug?: bool, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, type?: "FusionAuth"|"Generic"|"LDAP"}
export def "connector updateConnectorWithId" [
  connectorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --connector: record # Do not require a setter for 'type', it is defined by the concrete class and is not mutable — shape: {data?: record, debug?: bool, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, type?: "FusionAuth"|"Generic"|"LDAP"}
]: any -> record<connector: record<data: record, debug: bool, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>, connectors: table<data: record, debug: bool, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/connector/($connectorId)")
  let body = {connector: $connector} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a user consent type. You can optionally specify an Id for the consent type, if not provided one will be generated.
#
# POST /api/consent
# operationId: createConsent
# --consent shape: {data?: record, consentEmailTemplateId?: string, countryMinimumAgeForSelfConsent?: record, defaultMinimumAgeForSelfConsent?: int, emailPlus?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, multipleValuesAllowed?: bool, name?: string, values?: list}
export def "consent createConsent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --consent: record # Models a consent. — shape: {data?: record, consentEmailTemplateId?: string, countryMinimumAgeForSelfConsent?: record, defaultMinimumAgeForSelfConsent?: int, emailPlus?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, multipleValuesAllowed?: bool, name?: string, values?: list}
]: any -> record<consent: record<data: record, consentEmailTemplateId: string, countryMinimumAgeForSelfConsent: record, defaultMinimumAgeForSelfConsent: int, emailPlus: record<emailTemplateId: string, maximumTimeToSendEmailInHours: int, minimumTimeToSendEmailInHours: int, enabled: bool>, id: string, insertInstant: int, lastUpdateInstant: int, multipleValuesAllowed: bool, name: string, values: list<string>>, consents: table<data: record, consentEmailTemplateId: string, countryMinimumAgeForSelfConsent: record, defaultMinimumAgeForSelfConsent: int, emailPlus: record, id: string, insertInstant: int, lastUpdateInstant: int, multipleValuesAllowed: bool, name: string, values: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/consent")
  let body = {consent: $consent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Searches consents with the specified criteria and pagination.
#
# POST /api/consent/search
# operationId: searchConsentsWithId
# --search shape: {name?: string, numberOfResults?: int, orderBy?: string, startRow?: int}
export def "consent-search searchConsentsWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: record # Search criteria for Consents — shape: {name?: string, numberOfResults?: int, orderBy?: string, startRow?: int}
]: any -> record<consents: table<data: record, consentEmailTemplateId: string, countryMinimumAgeForSelfConsent: record, defaultMinimumAgeForSelfConsent: int, emailPlus: record, id: string, insertInstant: int, lastUpdateInstant: int, multipleValuesAllowed: bool, name: string, values: list>, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/consent/search")
  let body = {search: $search} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a user consent type. You can optionally specify an Id for the consent type, if not provided one will be generated.
#
# POST /api/consent/{consentId}
# operationId: createConsentWithId
# --consent shape: {data?: record, consentEmailTemplateId?: string, countryMinimumAgeForSelfConsent?: record, defaultMinimumAgeForSelfConsent?: int, emailPlus?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, multipleValuesAllowed?: bool, name?: string, values?: list}
export def "consent createConsentWithId" [
  consentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --consent: record # Models a consent. — shape: {data?: record, consentEmailTemplateId?: string, countryMinimumAgeForSelfConsent?: record, defaultMinimumAgeForSelfConsent?: int, emailPlus?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, multipleValuesAllowed?: bool, name?: string, values?: list}
]: any -> record<consent: record<data: record, consentEmailTemplateId: string, countryMinimumAgeForSelfConsent: record, defaultMinimumAgeForSelfConsent: int, emailPlus: record<emailTemplateId: string, maximumTimeToSendEmailInHours: int, minimumTimeToSendEmailInHours: int, enabled: bool>, id: string, insertInstant: int, lastUpdateInstant: int, multipleValuesAllowed: bool, name: string, values: list<string>>, consents: table<data: record, consentEmailTemplateId: string, countryMinimumAgeForSelfConsent: record, defaultMinimumAgeForSelfConsent: int, emailPlus: record, id: string, insertInstant: int, lastUpdateInstant: int, multipleValuesAllowed: bool, name: string, values: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/consent/($consentId)")
  let body = {consent: $consent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the consent for the given Id.
#
# DELETE /api/consent/{consentId}
# operationId: deleteConsentWithId
export def "consent delete" [
  consentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
]: nothing -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/consent/($consentId)")
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates, via PATCH, the consent with the given Id.
#
# PATCH /api/consent/{consentId}
# operationId: patchConsentWithId
# --consent shape: {data?: record, consentEmailTemplateId?: string, countryMinimumAgeForSelfConsent?: record, defaultMinimumAgeForSelfConsent?: int, emailPlus?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, multipleValuesAllowed?: bool, name?: string, values?: list}
export def "consent patch" [
  consentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --consent: record # Models a consent. — shape: {data?: record, consentEmailTemplateId?: string, countryMinimumAgeForSelfConsent?: record, defaultMinimumAgeForSelfConsent?: int, emailPlus?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, multipleValuesAllowed?: bool, name?: string, values?: list}
]: any -> record<consent: record<data: record, consentEmailTemplateId: string, countryMinimumAgeForSelfConsent: record, defaultMinimumAgeForSelfConsent: int, emailPlus: record<emailTemplateId: string, maximumTimeToSendEmailInHours: int, minimumTimeToSendEmailInHours: int, enabled: bool>, id: string, insertInstant: int, lastUpdateInstant: int, multipleValuesAllowed: bool, name: string, values: list<string>>, consents: table<data: record, consentEmailTemplateId: string, countryMinimumAgeForSelfConsent: record, defaultMinimumAgeForSelfConsent: int, emailPlus: record, id: string, insertInstant: int, lastUpdateInstant: int, multipleValuesAllowed: bool, name: string, values: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/consent/($consentId)")
  let body = {consent: $consent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the Consent for the given Id.
#
# GET /api/consent/{consentId}
# operationId: retrieveConsentWithId
export def "consent retrieveConsentWithId" [
  consentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
]: nothing -> record<consent: record<data: record, consentEmailTemplateId: string, countryMinimumAgeForSelfConsent: record, defaultMinimumAgeForSelfConsent: int, emailPlus: record<emailTemplateId: string, maximumTimeToSendEmailInHours: int, minimumTimeToSendEmailInHours: int, enabled: bool>, id: string, insertInstant: int, lastUpdateInstant: int, multipleValuesAllowed: bool, name: string, values: list<string>>, consents: table<data: record, consentEmailTemplateId: string, countryMinimumAgeForSelfConsent: record, defaultMinimumAgeForSelfConsent: int, emailPlus: record, id: string, insertInstant: int, lastUpdateInstant: int, multipleValuesAllowed: bool, name: string, values: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/consent/($consentId)")
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the consent with the given Id.
#
# PUT /api/consent/{consentId}
# operationId: updateConsentWithId
# --consent shape: {data?: record, consentEmailTemplateId?: string, countryMinimumAgeForSelfConsent?: record, defaultMinimumAgeForSelfConsent?: int, emailPlus?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, multipleValuesAllowed?: bool, name?: string, values?: list}
export def "consent updateConsentWithId" [
  consentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --consent: record # Models a consent. — shape: {data?: record, consentEmailTemplateId?: string, countryMinimumAgeForSelfConsent?: record, defaultMinimumAgeForSelfConsent?: int, emailPlus?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, multipleValuesAllowed?: bool, name?: string, values?: list}
]: any -> record<consent: record<data: record, consentEmailTemplateId: string, countryMinimumAgeForSelfConsent: record, defaultMinimumAgeForSelfConsent: int, emailPlus: record<emailTemplateId: string, maximumTimeToSendEmailInHours: int, minimumTimeToSendEmailInHours: int, enabled: bool>, id: string, insertInstant: int, lastUpdateInstant: int, multipleValuesAllowed: bool, name: string, values: list<string>>, consents: table<data: record, consentEmailTemplateId: string, countryMinimumAgeForSelfConsent: record, defaultMinimumAgeForSelfConsent: int, emailPlus: record, id: string, insertInstant: int, lastUpdateInstant: int, multipleValuesAllowed: bool, name: string, values: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/consent/($consentId)")
  let body = {consent: $consent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send an email using an email template Id. You can optionally provide <code>requestData</code> to access key value pairs in the email template.
#
# POST /api/email/send/{emailTemplateId}
# operationId: sendEmailWithId
# --toAddresses item shape: {address?: string, display?: string}
export def "email-send sendEmailWithId" [
  emailTemplateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applicationId: string # format: uuid
  --bccAddresses: list
  --ccAddresses: list
  --preferredLanguages: list
  --requestData: record
  --toAddresses: list # item shape: {address?: string, display?: string}
  --userIds: list
]: any -> record<anonymousResults: record, results: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/email/send/($emailTemplateId)")
  let body = {applicationId: $applicationId, bccAddresses: $bccAddresses, ccAddresses: $ccAddresses, preferredLanguages: $preferredLanguages, requestData: $requestData, toAddresses: $toAddresses, userIds: $userIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates an email template. You can optionally specify an Id for the template, if not provided one will be generated.
#
# POST /api/email/template
# operationId: createEmailTemplate
# --emailTemplate shape: {defaultFromName?: string, defaultHtmlTemplate?: string, defaultSubject?: string, defaultTextTemplate?: string, fromEmail?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, localizedFromNames?: record, localizedHtmlTemplates?: record, localizedSubjects?: record, localizedTextTemplates?: record, name?: string}
export def "email-template createEmailTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --emailTemplate: record # Stores an email template used to send emails to users. — shape: {defaultFromName?: string, defaultHtmlTemplate?: string, defaultSubject?: string, defaultTextTemplate?: string, fromEmail?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, localizedFromNames?: record, localizedHtmlTemplates?: record, localizedSubjects?: record, localizedTextTemplates?: record, name?: string}
]: any -> record<emailTemplate: record<defaultFromName: string, defaultHtmlTemplate: string, defaultSubject: string, defaultTextTemplate: string, fromEmail: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedFromNames: record, localizedHtmlTemplates: record, localizedSubjects: record, localizedTextTemplates: record, name: string>, emailTemplates: table<defaultFromName: string, defaultHtmlTemplate: string, defaultSubject: string, defaultTextTemplate: string, fromEmail: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedFromNames: record, localizedHtmlTemplates: record, localizedSubjects: record, localizedTextTemplates: record, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/email/template")
  let body = {emailTemplate: $emailTemplate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the email template for the given Id. If you don't specify the Id, this will return all the email templates.
#
# GET /api/email/template
# operationId: retrieveEmailTemplate
export def "email-template retrieveEmailTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
]: nothing -> record<emailTemplate: record<defaultFromName: string, defaultHtmlTemplate: string, defaultSubject: string, defaultTextTemplate: string, fromEmail: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedFromNames: record, localizedHtmlTemplates: record, localizedSubjects: record, localizedTextTemplates: record, name: string>, emailTemplates: table<defaultFromName: string, defaultHtmlTemplate: string, defaultSubject: string, defaultTextTemplate: string, fromEmail: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedFromNames: record, localizedHtmlTemplates: record, localizedSubjects: record, localizedTextTemplates: record, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/email/template")
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a preview of the email template provided in the request. This allows you to preview an email template that hasn't been saved to the database yet. The entire email template does not need to be provided on the request. This will create the preview based on whatever is given.
#
# POST /api/email/template/preview
# operationId: retrieveEmailTemplatePreviewWithId
# --emailTemplate shape: {defaultFromName?: string, defaultHtmlTemplate?: string, defaultSubject?: string, defaultTextTemplate?: string, fromEmail?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, localizedFromNames?: record, localizedHtmlTemplates?: record, localizedSubjects?: record, localizedTextTemplates?: record, name?: string}
export def "email-template-preview retrieveEmailTemplatePreviewWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --emailTemplate: record # Stores an email template used to send emails to users. — shape: {defaultFromName?: string, defaultHtmlTemplate?: string, defaultSubject?: string, defaultTextTemplate?: string, fromEmail?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, localizedFromNames?: record, localizedHtmlTemplates?: record, localizedSubjects?: record, localizedTextTemplates?: record, name?: string}
  --locale: string # A Locale object represents a specific geographical, political, or cultural region. (e.g. en_US)
]: any -> record<email: record<attachments: list<record>, bcc: list<record>, cc: list<record>, from: record<address: string, display: string>, html: string, replyTo: record<address: string, display: string>, subject: string, text: string, to: list<record>>, errors: record<fieldErrors: list<record>, generalErrors: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/email/template/preview")
  let body = {emailTemplate: $emailTemplate, locale: $locale} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Searches email templates with the specified criteria and pagination.
#
# POST /api/email/template/search
# operationId: searchEmailTemplatesWithId
# --search shape: {name?: string, numberOfResults?: int, orderBy?: string, startRow?: int}
export def "email-template-search searchEmailTemplatesWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: record # Search criteria for Email templates — shape: {name?: string, numberOfResults?: int, orderBy?: string, startRow?: int}
]: any -> record<emailTemplates: table<defaultFromName: string, defaultHtmlTemplate: string, defaultSubject: string, defaultTextTemplate: string, fromEmail: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedFromNames: record, localizedHtmlTemplates: record, localizedSubjects: record, localizedTextTemplates: record, name: string>, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/email/template/search")
  let body = {search: $search} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates an email template. You can optionally specify an Id for the template, if not provided one will be generated.
#
# POST /api/email/template/{emailTemplateId}
# operationId: createEmailTemplateWithId
# --emailTemplate shape: {defaultFromName?: string, defaultHtmlTemplate?: string, defaultSubject?: string, defaultTextTemplate?: string, fromEmail?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, localizedFromNames?: record, localizedHtmlTemplates?: record, localizedSubjects?: record, localizedTextTemplates?: record, name?: string}
export def "email-template createEmailTemplateWithId" [
  emailTemplateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --emailTemplate: record # Stores an email template used to send emails to users. — shape: {defaultFromName?: string, defaultHtmlTemplate?: string, defaultSubject?: string, defaultTextTemplate?: string, fromEmail?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, localizedFromNames?: record, localizedHtmlTemplates?: record, localizedSubjects?: record, localizedTextTemplates?: record, name?: string}
]: any -> record<emailTemplate: record<defaultFromName: string, defaultHtmlTemplate: string, defaultSubject: string, defaultTextTemplate: string, fromEmail: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedFromNames: record, localizedHtmlTemplates: record, localizedSubjects: record, localizedTextTemplates: record, name: string>, emailTemplates: table<defaultFromName: string, defaultHtmlTemplate: string, defaultSubject: string, defaultTextTemplate: string, fromEmail: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedFromNames: record, localizedHtmlTemplates: record, localizedSubjects: record, localizedTextTemplates: record, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/email/template/($emailTemplateId)")
  let body = {emailTemplate: $emailTemplate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the email template for the given Id.
#
# DELETE /api/email/template/{emailTemplateId}
# operationId: deleteEmailTemplateWithId
export def "email-template delete" [
  emailTemplateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
]: nothing -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/email/template/($emailTemplateId)")
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates, via PATCH, the email template with the given Id.
#
# PATCH /api/email/template/{emailTemplateId}
# operationId: patchEmailTemplateWithId
# --emailTemplate shape: {defaultFromName?: string, defaultHtmlTemplate?: string, defaultSubject?: string, defaultTextTemplate?: string, fromEmail?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, localizedFromNames?: record, localizedHtmlTemplates?: record, localizedSubjects?: record, localizedTextTemplates?: record, name?: string}
export def "email-template patch" [
  emailTemplateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --emailTemplate: record # Stores an email template used to send emails to users. — shape: {defaultFromName?: string, defaultHtmlTemplate?: string, defaultSubject?: string, defaultTextTemplate?: string, fromEmail?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, localizedFromNames?: record, localizedHtmlTemplates?: record, localizedSubjects?: record, localizedTextTemplates?: record, name?: string}
]: any -> record<emailTemplate: record<defaultFromName: string, defaultHtmlTemplate: string, defaultSubject: string, defaultTextTemplate: string, fromEmail: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedFromNames: record, localizedHtmlTemplates: record, localizedSubjects: record, localizedTextTemplates: record, name: string>, emailTemplates: table<defaultFromName: string, defaultHtmlTemplate: string, defaultSubject: string, defaultTextTemplate: string, fromEmail: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedFromNames: record, localizedHtmlTemplates: record, localizedSubjects: record, localizedTextTemplates: record, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/email/template/($emailTemplateId)")
  let body = {emailTemplate: $emailTemplate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the email template for the given Id. If you don't specify the Id, this will return all the email templates.
#
# GET /api/email/template/{emailTemplateId}
# operationId: retrieveEmailTemplateWithId
export def "email-template retrieveEmailTemplateWithId" [
  emailTemplateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
]: nothing -> record<emailTemplate: record<defaultFromName: string, defaultHtmlTemplate: string, defaultSubject: string, defaultTextTemplate: string, fromEmail: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedFromNames: record, localizedHtmlTemplates: record, localizedSubjects: record, localizedTextTemplates: record, name: string>, emailTemplates: table<defaultFromName: string, defaultHtmlTemplate: string, defaultSubject: string, defaultTextTemplate: string, fromEmail: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedFromNames: record, localizedHtmlTemplates: record, localizedSubjects: record, localizedTextTemplates: record, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/email/template/($emailTemplateId)")
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the email template with the given Id.
#
# PUT /api/email/template/{emailTemplateId}
# operationId: updateEmailTemplateWithId
# --emailTemplate shape: {defaultFromName?: string, defaultHtmlTemplate?: string, defaultSubject?: string, defaultTextTemplate?: string, fromEmail?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, localizedFromNames?: record, localizedHtmlTemplates?: record, localizedSubjects?: record, localizedTextTemplates?: record, name?: string}
export def "email-template updateEmailTemplateWithId" [
  emailTemplateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --emailTemplate: record # Stores an email template used to send emails to users. — shape: {defaultFromName?: string, defaultHtmlTemplate?: string, defaultSubject?: string, defaultTextTemplate?: string, fromEmail?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, localizedFromNames?: record, localizedHtmlTemplates?: record, localizedSubjects?: record, localizedTextTemplates?: record, name?: string}
]: any -> record<emailTemplate: record<defaultFromName: string, defaultHtmlTemplate: string, defaultSubject: string, defaultTextTemplate: string, fromEmail: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedFromNames: record, localizedHtmlTemplates: record, localizedSubjects: record, localizedTextTemplates: record, name: string>, emailTemplates: table<defaultFromName: string, defaultHtmlTemplate: string, defaultSubject: string, defaultTextTemplate: string, fromEmail: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedFromNames: record, localizedHtmlTemplates: record, localizedSubjects: record, localizedTextTemplates: record, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/email/template/($emailTemplateId)")
  let body = {emailTemplate: $emailTemplate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates an Entity. You can optionally specify an Id for the Entity. If not provided one will be generated.
#
# POST /api/entity
# operationId: createEntity
# --entity shape: {data?: record, clientId?: string, clientSecret?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, parentId?: string, tenantId?: string, type?: record}
export def "entity createEntity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --entity: record # Models an entity that a user can be granted permissions to. Or an entity that can be granted permissions to another entity. — shape: {data?: record, clientId?: string, clientSecret?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, parentId?: string, tenantId?: string, type?: record}
]: any -> record<entity: record<data: record, clientId: string, clientSecret: string, id: string, insertInstant: int, lastUpdateInstant: int, name: string, parentId: string, tenantId: string, type: record<data: record, id: string, insertInstant: int, jwtConfiguration: record, lastUpdateInstant: int, name: string, permissions: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/entity")
  let body = {entity: $entity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Searches Entity Grants with the specified criteria and pagination.
#
# POST /api/entity/grant/search
# operationId: searchEntityGrantsWithId
# --search shape: {entityId?: string, name?: string, userId?: string, numberOfResults?: int, orderBy?: string, startRow?: int}
export def "entity-grant-search searchEntityGrantsWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: record # Search criteria for entity grants. — shape: {entityId?: string, name?: string, userId?: string, numberOfResults?: int, orderBy?: string, startRow?: int}
]: any -> record<grants: table<data: record, entity: record, id: string, insertInstant: int, lastUpdateInstant: int, permissions: list, recipientEntityId: string, userId: string>, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/entity/grant/search")
  let body = {search: $search} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Searches entities with the specified criteria and pagination.
#
# POST /api/entity/search
# operationId: searchEntitiesWithId
# --search shape: {accurateTotal?: bool, ids?: list, nextResults?: string, query?: string, queryString?: string, sortFields?: list}
export def "entity-search searchEntitiesWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: record # This class is the entity query. It provides a build pattern as well as public fields for use on forms and in actions. — shape: {accurateTotal?: bool, ids?: list, nextResults?: string, query?: string, queryString?: string, sortFields?: list}
]: any -> record<entities: table<data: record, clientId: string, clientSecret: string, id: string, insertInstant: int, lastUpdateInstant: int, name: string, parentId: string, tenantId: string, type: record>, nextResults: string, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/entity/search")
  let body = {search: $search} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the entities for the given Ids. If any Id is invalid, it is ignored.
#
# GET /api/entity/search
# operationId: searchEntitiesByIdsWithId
export def "entity-search searchEntitiesByIdsWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # The entity ids to search for.
]: nothing -> record<entities: table<data: record, clientId: string, clientSecret: string, id: string, insertInstant: int, lastUpdateInstant: int, name: string, parentId: string, tenantId: string, type: record>, nextResults: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/entity/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a Entity Type. You can optionally specify an Id for the Entity Type, if not provided one will be generated.
#
# POST /api/entity/type
# operationId: createEntityType
# --entityType shape: {data?: record, id?: string, insertInstant?: int, jwtConfiguration?: record, lastUpdateInstant?: int, name?: string, permissions?: list}
# --permission shape: {data?: record, description?: string, id?: string, insertInstant?: int, isDefault?: bool, lastUpdateInstant?: int, name?: string}
export def "entity-type createEntityType" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --entityType: record # Models an entity type that has a specific set of permissions. These are global objects and can be used across tenants. — shape: {data?: record, id?: string, insertInstant?: int, jwtConfiguration?: record, lastUpdateInstant?: int, name?: string, permissions?: list}
  --permission: record # Models a specific entity type permission. This permission can be granted to users or other entities. — shape: {data?: record, description?: string, id?: string, insertInstant?: int, isDefault?: bool, lastUpdateInstant?: int, name?: string}
]: any -> record<entityType: record<data: record, id: string, insertInstant: int, jwtConfiguration: record<accessTokenKeyId: string, timeToLiveInSeconds: int, enabled: bool>, lastUpdateInstant: int, name: string, permissions: list<record>>, entityTypes: table<data: record, id: string, insertInstant: int, jwtConfiguration: record, lastUpdateInstant: int, name: string, permissions: list>, permission: record<data: record, description: string, id: string, insertInstant: int, isDefault: bool, lastUpdateInstant: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/entity/type")
  let body = {entityType: $entityType, permission: $permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Searches the entity types with the specified criteria and pagination.
#
# POST /api/entity/type/search
# operationId: searchEntityTypesWithId
# --search shape: {name?: string, numberOfResults?: int, orderBy?: string, startRow?: int}
export def "entity-type-search searchEntityTypesWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: record # Search criteria for entity types. — shape: {name?: string, numberOfResults?: int, orderBy?: string, startRow?: int}
]: any -> record<entityTypes: table<data: record, id: string, insertInstant: int, jwtConfiguration: record, lastUpdateInstant: int, name: string, permissions: list>, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/entity/type/search")
  let body = {search: $search} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a Entity Type. You can optionally specify an Id for the Entity Type, if not provided one will be generated.
#
# POST /api/entity/type/{entityTypeId}
# operationId: createEntityTypeWithId
# --entityType shape: {data?: record, id?: string, insertInstant?: int, jwtConfiguration?: record, lastUpdateInstant?: int, name?: string, permissions?: list}
# --permission shape: {data?: record, description?: string, id?: string, insertInstant?: int, isDefault?: bool, lastUpdateInstant?: int, name?: string}
export def "entity-type createEntityTypeWithId" [
  entityTypeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --entityType: record # Models an entity type that has a specific set of permissions. These are global objects and can be used across tenants. — shape: {data?: record, id?: string, insertInstant?: int, jwtConfiguration?: record, lastUpdateInstant?: int, name?: string, permissions?: list}
  --permission: record # Models a specific entity type permission. This permission can be granted to users or other entities. — shape: {data?: record, description?: string, id?: string, insertInstant?: int, isDefault?: bool, lastUpdateInstant?: int, name?: string}
]: any -> record<entityType: record<data: record, id: string, insertInstant: int, jwtConfiguration: record<accessTokenKeyId: string, timeToLiveInSeconds: int, enabled: bool>, lastUpdateInstant: int, name: string, permissions: list<record>>, entityTypes: table<data: record, id: string, insertInstant: int, jwtConfiguration: record, lastUpdateInstant: int, name: string, permissions: list>, permission: record<data: record, description: string, id: string, insertInstant: int, isDefault: bool, lastUpdateInstant: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/entity/type/($entityTypeId)")
  let body = {entityType: $entityType, permission: $permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the Entity Type for the given Id.
#
# DELETE /api/entity/type/{entityTypeId}
# operationId: deleteEntityTypeWithId
export def "entity-type delete" [
  entityTypeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/entity/type/($entityTypeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates, via PATCH, the Entity Type with the given Id.
#
# PATCH /api/entity/type/{entityTypeId}
# operationId: patchEntityTypeWithId
# --entityType shape: {data?: record, id?: string, insertInstant?: int, jwtConfiguration?: record, lastUpdateInstant?: int, name?: string, permissions?: list}
# --permission shape: {data?: record, description?: string, id?: string, insertInstant?: int, isDefault?: bool, lastUpdateInstant?: int, name?: string}
export def "entity-type patch" [
  entityTypeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --entityType: record # Models an entity type that has a specific set of permissions. These are global objects and can be used across tenants. — shape: {data?: record, id?: string, insertInstant?: int, jwtConfiguration?: record, lastUpdateInstant?: int, name?: string, permissions?: list}
  --permission: record # Models a specific entity type permission. This permission can be granted to users or other entities. — shape: {data?: record, description?: string, id?: string, insertInstant?: int, isDefault?: bool, lastUpdateInstant?: int, name?: string}
]: any -> record<entityType: record<data: record, id: string, insertInstant: int, jwtConfiguration: record<accessTokenKeyId: string, timeToLiveInSeconds: int, enabled: bool>, lastUpdateInstant: int, name: string, permissions: list<record>>, entityTypes: table<data: record, id: string, insertInstant: int, jwtConfiguration: record, lastUpdateInstant: int, name: string, permissions: list>, permission: record<data: record, description: string, id: string, insertInstant: int, isDefault: bool, lastUpdateInstant: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/entity/type/($entityTypeId)")
  let body = {entityType: $entityType, permission: $permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the Entity Type for the given Id.
#
# GET /api/entity/type/{entityTypeId}
# operationId: retrieveEntityTypeWithId
export def "entity-type retrieveEntityTypeWithId" [
  entityTypeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<entityType: record<data: record, id: string, insertInstant: int, jwtConfiguration: record<accessTokenKeyId: string, timeToLiveInSeconds: int, enabled: bool>, lastUpdateInstant: int, name: string, permissions: list<record>>, entityTypes: table<data: record, id: string, insertInstant: int, jwtConfiguration: record, lastUpdateInstant: int, name: string, permissions: list>, permission: record<data: record, description: string, id: string, insertInstant: int, isDefault: bool, lastUpdateInstant: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/entity/type/($entityTypeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the Entity Type with the given Id.
#
# PUT /api/entity/type/{entityTypeId}
# operationId: updateEntityTypeWithId
# --entityType shape: {data?: record, id?: string, insertInstant?: int, jwtConfiguration?: record, lastUpdateInstant?: int, name?: string, permissions?: list}
# --permission shape: {data?: record, description?: string, id?: string, insertInstant?: int, isDefault?: bool, lastUpdateInstant?: int, name?: string}
export def "entity-type updateEntityTypeWithId" [
  entityTypeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --entityType: record # Models an entity type that has a specific set of permissions. These are global objects and can be used across tenants. — shape: {data?: record, id?: string, insertInstant?: int, jwtConfiguration?: record, lastUpdateInstant?: int, name?: string, permissions?: list}
  --permission: record # Models a specific entity type permission. This permission can be granted to users or other entities. — shape: {data?: record, description?: string, id?: string, insertInstant?: int, isDefault?: bool, lastUpdateInstant?: int, name?: string}
]: any -> record<entityType: record<data: record, id: string, insertInstant: int, jwtConfiguration: record<accessTokenKeyId: string, timeToLiveInSeconds: int, enabled: bool>, lastUpdateInstant: int, name: string, permissions: list<record>>, entityTypes: table<data: record, id: string, insertInstant: int, jwtConfiguration: record, lastUpdateInstant: int, name: string, permissions: list>, permission: record<data: record, description: string, id: string, insertInstant: int, isDefault: bool, lastUpdateInstant: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/entity/type/($entityTypeId)")
  let body = {entityType: $entityType, permission: $permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a new permission for an entity type. You must specify the Id of the entity type you are creating the permission for. You can optionally specify an Id for the permission inside the EntityTypePermission object itself, if not provided one will be generated.
#
# POST /api/entity/type/{entityTypeId}/permission
# operationId: createEntityTypePermission
# --entityType shape: {data?: record, id?: string, insertInstant?: int, jwtConfiguration?: record, lastUpdateInstant?: int, name?: string, permissions?: list}
# --permission shape: {data?: record, description?: string, id?: string, insertInstant?: int, isDefault?: bool, lastUpdateInstant?: int, name?: string}
export def "entity-type-permission createEntityTypePermission" [
  entityTypeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --entityType: record # Models an entity type that has a specific set of permissions. These are global objects and can be used across tenants. — shape: {data?: record, id?: string, insertInstant?: int, jwtConfiguration?: record, lastUpdateInstant?: int, name?: string, permissions?: list}
  --permission: record # Models a specific entity type permission. This permission can be granted to users or other entities. — shape: {data?: record, description?: string, id?: string, insertInstant?: int, isDefault?: bool, lastUpdateInstant?: int, name?: string}
]: any -> record<entityType: record<data: record, id: string, insertInstant: int, jwtConfiguration: record<accessTokenKeyId: string, timeToLiveInSeconds: int, enabled: bool>, lastUpdateInstant: int, name: string, permissions: list<record>>, entityTypes: table<data: record, id: string, insertInstant: int, jwtConfiguration: record, lastUpdateInstant: int, name: string, permissions: list>, permission: record<data: record, description: string, id: string, insertInstant: int, isDefault: bool, lastUpdateInstant: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/entity/type/($entityTypeId)/permission")
  let body = {entityType: $entityType, permission: $permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a new permission for an entity type. You must specify the Id of the entity type you are creating the permission for. You can optionally specify an Id for the permission inside the EntityTypePermission object itself, if not provided one will be generated.
#
# POST /api/entity/type/{entityTypeId}/permission/{permissionId}
# operationId: createEntityTypePermissionWithId
# --entityType shape: {data?: record, id?: string, insertInstant?: int, jwtConfiguration?: record, lastUpdateInstant?: int, name?: string, permissions?: list}
# --permission shape: {data?: record, description?: string, id?: string, insertInstant?: int, isDefault?: bool, lastUpdateInstant?: int, name?: string}
export def "entity-type-permission createEntityTypePermissionWithId" [
  entityTypeId: string
  permissionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --entityType: record # Models an entity type that has a specific set of permissions. These are global objects and can be used across tenants. — shape: {data?: record, id?: string, insertInstant?: int, jwtConfiguration?: record, lastUpdateInstant?: int, name?: string, permissions?: list}
  --permission: record # Models a specific entity type permission. This permission can be granted to users or other entities. — shape: {data?: record, description?: string, id?: string, insertInstant?: int, isDefault?: bool, lastUpdateInstant?: int, name?: string}
]: any -> record<entityType: record<data: record, id: string, insertInstant: int, jwtConfiguration: record<accessTokenKeyId: string, timeToLiveInSeconds: int, enabled: bool>, lastUpdateInstant: int, name: string, permissions: list<record>>, entityTypes: table<data: record, id: string, insertInstant: int, jwtConfiguration: record, lastUpdateInstant: int, name: string, permissions: list>, permission: record<data: record, description: string, id: string, insertInstant: int, isDefault: bool, lastUpdateInstant: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/entity/type/($entityTypeId)/permission/($permissionId)")
  let body = {entityType: $entityType, permission: $permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Hard deletes a permission. This is a dangerous operation and should not be used in most circumstances. This permanently removes the given permission from all grants that had it.
#
# DELETE /api/entity/type/{entityTypeId}/permission/{permissionId}
# operationId: deleteEntityTypePermissionWithId
export def "entity-type-permission delete" [
  entityTypeId: string
  permissionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/entity/type/($entityTypeId)/permission/($permissionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patches the permission with the given Id for the entity type.
#
# PATCH /api/entity/type/{entityTypeId}/permission/{permissionId}
# operationId: patchEntityTypePermissionWithId
# --entityType shape: {data?: record, id?: string, insertInstant?: int, jwtConfiguration?: record, lastUpdateInstant?: int, name?: string, permissions?: list}
# --permission shape: {data?: record, description?: string, id?: string, insertInstant?: int, isDefault?: bool, lastUpdateInstant?: int, name?: string}
export def "entity-type-permission patch" [
  entityTypeId: string
  permissionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --entityType: record # Models an entity type that has a specific set of permissions. These are global objects and can be used across tenants. — shape: {data?: record, id?: string, insertInstant?: int, jwtConfiguration?: record, lastUpdateInstant?: int, name?: string, permissions?: list}
  --permission: record # Models a specific entity type permission. This permission can be granted to users or other entities. — shape: {data?: record, description?: string, id?: string, insertInstant?: int, isDefault?: bool, lastUpdateInstant?: int, name?: string}
]: any -> record<entityType: record<data: record, id: string, insertInstant: int, jwtConfiguration: record<accessTokenKeyId: string, timeToLiveInSeconds: int, enabled: bool>, lastUpdateInstant: int, name: string, permissions: list<record>>, entityTypes: table<data: record, id: string, insertInstant: int, jwtConfiguration: record, lastUpdateInstant: int, name: string, permissions: list>, permission: record<data: record, description: string, id: string, insertInstant: int, isDefault: bool, lastUpdateInstant: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/entity/type/($entityTypeId)/permission/($permissionId)")
  let body = {entityType: $entityType, permission: $permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates the permission with the given Id for the entity type.
#
# PUT /api/entity/type/{entityTypeId}/permission/{permissionId}
# operationId: updateEntityTypePermissionWithId
# --entityType shape: {data?: record, id?: string, insertInstant?: int, jwtConfiguration?: record, lastUpdateInstant?: int, name?: string, permissions?: list}
# --permission shape: {data?: record, description?: string, id?: string, insertInstant?: int, isDefault?: bool, lastUpdateInstant?: int, name?: string}
export def "entity-type-permission updateEntityTypePermissionWithId" [
  entityTypeId: string
  permissionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --entityType: record # Models an entity type that has a specific set of permissions. These are global objects and can be used across tenants. — shape: {data?: record, id?: string, insertInstant?: int, jwtConfiguration?: record, lastUpdateInstant?: int, name?: string, permissions?: list}
  --permission: record # Models a specific entity type permission. This permission can be granted to users or other entities. — shape: {data?: record, description?: string, id?: string, insertInstant?: int, isDefault?: bool, lastUpdateInstant?: int, name?: string}
]: any -> record<entityType: record<data: record, id: string, insertInstant: int, jwtConfiguration: record<accessTokenKeyId: string, timeToLiveInSeconds: int, enabled: bool>, lastUpdateInstant: int, name: string, permissions: list<record>>, entityTypes: table<data: record, id: string, insertInstant: int, jwtConfiguration: record, lastUpdateInstant: int, name: string, permissions: list>, permission: record<data: record, description: string, id: string, insertInstant: int, isDefault: bool, lastUpdateInstant: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/entity/type/($entityTypeId)/permission/($permissionId)")
  let body = {entityType: $entityType, permission: $permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates an Entity. You can optionally specify an Id for the Entity. If not provided one will be generated.
#
# POST /api/entity/{entityId}
# operationId: createEntityWithId
# --entity shape: {data?: record, clientId?: string, clientSecret?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, parentId?: string, tenantId?: string, type?: record}
export def "entity createEntityWithId" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --entity: record # Models an entity that a user can be granted permissions to. Or an entity that can be granted permissions to another entity. — shape: {data?: record, clientId?: string, clientSecret?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, parentId?: string, tenantId?: string, type?: record}
]: any -> record<entity: record<data: record, clientId: string, clientSecret: string, id: string, insertInstant: int, lastUpdateInstant: int, name: string, parentId: string, tenantId: string, type: record<data: record, id: string, insertInstant: int, jwtConfiguration: record, lastUpdateInstant: int, name: string, permissions: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/entity/($entityId)")
  let body = {entity: $entity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the Entity for the given Id.
#
# DELETE /api/entity/{entityId}
# operationId: deleteEntityWithId
export def "entity delete" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
]: nothing -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/entity/($entityId)")
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates, via PATCH, the Entity with the given Id.
#
# PATCH /api/entity/{entityId}
# operationId: patchEntityWithId
# --entity shape: {data?: record, clientId?: string, clientSecret?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, parentId?: string, tenantId?: string, type?: record}
export def "entity patch" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --entity: record # Models an entity that a user can be granted permissions to. Or an entity that can be granted permissions to another entity. — shape: {data?: record, clientId?: string, clientSecret?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, parentId?: string, tenantId?: string, type?: record}
]: any -> record<entity: record<data: record, clientId: string, clientSecret: string, id: string, insertInstant: int, lastUpdateInstant: int, name: string, parentId: string, tenantId: string, type: record<data: record, id: string, insertInstant: int, jwtConfiguration: record, lastUpdateInstant: int, name: string, permissions: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/entity/($entityId)")
  let body = {entity: $entity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the Entity for the given Id.
#
# GET /api/entity/{entityId}
# operationId: retrieveEntityWithId
export def "entity retrieveEntityWithId" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
]: nothing -> record<entity: record<data: record, clientId: string, clientSecret: string, id: string, insertInstant: int, lastUpdateInstant: int, name: string, parentId: string, tenantId: string, type: record<data: record, id: string, insertInstant: int, jwtConfiguration: record, lastUpdateInstant: int, name: string, permissions: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/entity/($entityId)")
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the Entity with the given Id.
#
# PUT /api/entity/{entityId}
# operationId: updateEntityWithId
# --entity shape: {data?: record, clientId?: string, clientSecret?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, parentId?: string, tenantId?: string, type?: record}
export def "entity updateEntityWithId" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --entity: record # Models an entity that a user can be granted permissions to. Or an entity that can be granted permissions to another entity. — shape: {data?: record, clientId?: string, clientSecret?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, parentId?: string, tenantId?: string, type?: record}
]: any -> record<entity: record<data: record, clientId: string, clientSecret: string, id: string, insertInstant: int, lastUpdateInstant: int, name: string, parentId: string, tenantId: string, type: record<data: record, id: string, insertInstant: int, jwtConfiguration: record, lastUpdateInstant: int, name: string, permissions: list>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/entity/($entityId)")
  let body = {entity: $entity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes an Entity Grant for the given User or Entity.
#
# DELETE /api/entity/{entityId}/grant
# operationId: deleteEntityGrantWithId
export def "entity-grant delete" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recipientEntityId: string # The Id of the Entity that the Entity Grant is for.
  --userId: string # The Id of the User that the Entity Grant is for.
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
]: nothing -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recipientEntityId" $recipientEntityId "scalar") (serialize-qp "userId" $userId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/entity/($entityId)/grant" $qp)
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves an Entity Grant for the given Entity and User/Entity.
#
# GET /api/entity/{entityId}/grant
# operationId: retrieveEntityGrantWithId
export def "entity-grant retrieveEntityGrantWithId" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recipientEntityId: string # The Id of the Entity that the Entity Grant is for.
  --userId: string # The Id of the User that the Entity Grant is for.
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
]: nothing -> record<grants: table<data: record, entity: record, id: string, insertInstant: int, lastUpdateInstant: int, permissions: list, recipientEntityId: string, userId: string>, grant: record<data: record, entity: record<data: record, clientId: string, clientSecret: string, id: string, insertInstant: int, lastUpdateInstant: int, name: string, parentId: string, tenantId: string, type: record>, id: string, insertInstant: int, lastUpdateInstant: int, permissions: list<any>, recipientEntityId: string, userId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recipientEntityId" $recipientEntityId "scalar") (serialize-qp "userId" $userId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/entity/($entityId)/grant" $qp)
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates or updates an Entity Grant. This is when a User/Entity is granted permissions to an Entity.
#
# POST /api/entity/{entityId}/grant
# operationId: upsertEntityGrantWithId
# --grant shape: {data?: record, entity?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, permissions?: list, recipientEntityId?: string, userId?: string}
export def "entity-grant upsertEntityGrantWithId" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --grant: record # A grant for an entity to a user or another entity. — shape: {data?: record, entity?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, permissions?: list, recipientEntityId?: string, userId?: string}
]: any -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/entity/($entityId)/grant")
  let body = {grant: $grant} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a form.  You can optionally specify an Id for the form, if not provided one will be generated.
#
# POST /api/form
# operationId: createForm
# --form shape: {data?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, steps?: list, type?: "registration"|"adminRegistration"|"adminUser"|"selfServiceUser"}
export def "form createForm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --form: record # shape: {data?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, steps?: list, type?: "registration"|"adminRegistration"|"adminUser"|"selfServiceUser"}
]: any -> record<form: record<data: record, id: string, insertInstant: int, lastUpdateInstant: int, name: string, steps: list<record>, type: string>, forms: table<data: record, id: string, insertInstant: int, lastUpdateInstant: int, name: string, steps: list, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/form")
  let body = {form: $form} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a form field.  You can optionally specify an Id for the form, if not provided one will be generated.
#
# POST /api/form/field
# operationId: createFormField
# --field shape: {confirm?: bool, consentId?: string, control?: "checkbox"|"number"|"password"|"radio"|"select"|"textarea"|"text", data?: record, description?: string, id?: string, insertInstant?: int, key?: string, lastUpdateInstant?: int, name?: string, options?: list, required?: bool, type?: "bool"|"consent"|"date"|"email"|"number"|"phoneNumber"|"string", validator?: record}
# --fields item shape: {confirm?: bool, consentId?: string, control?: "checkbox"|"number"|"password"|"radio"|"select"|"textarea"|"text", data?: record, description?: string, id?: string, insertInstant?: int, key?: string, lastUpdateInstant?: int, name?: string, options?: list, required?: bool, type?: "bool"|"consent"|"date"|"email"|"number"|"phoneNumber"|"string", validator?: record}
export def "form-field createFormField" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --field: record # shape: {confirm?: bool, consentId?: string, control?: "checkbox"|"number"|"password"|"radio"|"select"|"textarea"|"text", data?: record, description?: string, id?: string, insertInstant?: int, key?: string, lastUpdateInstant?: int, name?: string, options?: list, required?: bool, type?: "bool"|"consent"|"date"|"email"|"number"|"phoneNumber"|"string", validator?: record}
  --body-fields: list # item shape: {confirm?: bool, consentId?: string, control?: "checkbox"|"number"|"password"|"radio"|"select"|"textarea"|"text", data?: record, description?: string, id?: string, insertInstant?: int, key?: string, lastUpdateInstant?: int, name?: string, options?: list, required?: bool, type?: "bool"|"consent"|"date"|"email"|"number"|"phoneNumber"|"string", validator?: record}
]: any -> record<field: record<confirm: bool, consentId: string, control: string, data: record, description: string, id: string, insertInstant: int, key: string, lastUpdateInstant: int, name: string, options: list<string>, required: bool, type: string, validator: record<expression: string, enabled: bool>>, fields: table<confirm: bool, consentId: string, control: string, data: record, description: string, id: string, insertInstant: int, key: string, lastUpdateInstant: int, name: string, options: list, required: bool, type: string, validator: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/form/field")
  let body = {field: $field, fields: $body_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a form field.  You can optionally specify an Id for the form, if not provided one will be generated.
#
# POST /api/form/field/{fieldId}
# operationId: createFormFieldWithId
# --field shape: {confirm?: bool, consentId?: string, control?: "checkbox"|"number"|"password"|"radio"|"select"|"textarea"|"text", data?: record, description?: string, id?: string, insertInstant?: int, key?: string, lastUpdateInstant?: int, name?: string, options?: list, required?: bool, type?: "bool"|"consent"|"date"|"email"|"number"|"phoneNumber"|"string", validator?: record}
# --fields item shape: {confirm?: bool, consentId?: string, control?: "checkbox"|"number"|"password"|"radio"|"select"|"textarea"|"text", data?: record, description?: string, id?: string, insertInstant?: int, key?: string, lastUpdateInstant?: int, name?: string, options?: list, required?: bool, type?: "bool"|"consent"|"date"|"email"|"number"|"phoneNumber"|"string", validator?: record}
export def "form-field createFormFieldWithId" [
  fieldId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --field: record # shape: {confirm?: bool, consentId?: string, control?: "checkbox"|"number"|"password"|"radio"|"select"|"textarea"|"text", data?: record, description?: string, id?: string, insertInstant?: int, key?: string, lastUpdateInstant?: int, name?: string, options?: list, required?: bool, type?: "bool"|"consent"|"date"|"email"|"number"|"phoneNumber"|"string", validator?: record}
  --body-fields: list # item shape: {confirm?: bool, consentId?: string, control?: "checkbox"|"number"|"password"|"radio"|"select"|"textarea"|"text", data?: record, description?: string, id?: string, insertInstant?: int, key?: string, lastUpdateInstant?: int, name?: string, options?: list, required?: bool, type?: "bool"|"consent"|"date"|"email"|"number"|"phoneNumber"|"string", validator?: record}
]: any -> record<field: record<confirm: bool, consentId: string, control: string, data: record, description: string, id: string, insertInstant: int, key: string, lastUpdateInstant: int, name: string, options: list<string>, required: bool, type: string, validator: record<expression: string, enabled: bool>>, fields: table<confirm: bool, consentId: string, control: string, data: record, description: string, id: string, insertInstant: int, key: string, lastUpdateInstant: int, name: string, options: list, required: bool, type: string, validator: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/form/field/($fieldId)")
  let body = {field: $field, fields: $body_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the form field for the given Id.
#
# DELETE /api/form/field/{fieldId}
# operationId: deleteFormFieldWithId
export def "form-field delete" [
  fieldId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/form/field/($fieldId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patches the form field with the given Id.
#
# PATCH /api/form/field/{fieldId}
# operationId: patchFormFieldWithId
# --field shape: {confirm?: bool, consentId?: string, control?: "checkbox"|"number"|"password"|"radio"|"select"|"textarea"|"text", data?: record, description?: string, id?: string, insertInstant?: int, key?: string, lastUpdateInstant?: int, name?: string, options?: list, required?: bool, type?: "bool"|"consent"|"date"|"email"|"number"|"phoneNumber"|"string", validator?: record}
# --fields item shape: {confirm?: bool, consentId?: string, control?: "checkbox"|"number"|"password"|"radio"|"select"|"textarea"|"text", data?: record, description?: string, id?: string, insertInstant?: int, key?: string, lastUpdateInstant?: int, name?: string, options?: list, required?: bool, type?: "bool"|"consent"|"date"|"email"|"number"|"phoneNumber"|"string", validator?: record}
export def "form-field patch" [
  fieldId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --field: record # shape: {confirm?: bool, consentId?: string, control?: "checkbox"|"number"|"password"|"radio"|"select"|"textarea"|"text", data?: record, description?: string, id?: string, insertInstant?: int, key?: string, lastUpdateInstant?: int, name?: string, options?: list, required?: bool, type?: "bool"|"consent"|"date"|"email"|"number"|"phoneNumber"|"string", validator?: record}
  --body-fields: list # item shape: {confirm?: bool, consentId?: string, control?: "checkbox"|"number"|"password"|"radio"|"select"|"textarea"|"text", data?: record, description?: string, id?: string, insertInstant?: int, key?: string, lastUpdateInstant?: int, name?: string, options?: list, required?: bool, type?: "bool"|"consent"|"date"|"email"|"number"|"phoneNumber"|"string", validator?: record}
]: any -> record<field: record<confirm: bool, consentId: string, control: string, data: record, description: string, id: string, insertInstant: int, key: string, lastUpdateInstant: int, name: string, options: list<string>, required: bool, type: string, validator: record<expression: string, enabled: bool>>, fields: table<confirm: bool, consentId: string, control: string, data: record, description: string, id: string, insertInstant: int, key: string, lastUpdateInstant: int, name: string, options: list, required: bool, type: string, validator: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/form/field/($fieldId)")
  let body = {field: $field, fields: $body_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the form field with the given Id.
#
# GET /api/form/field/{fieldId}
# operationId: retrieveFormFieldWithId
export def "form-field retrieveFormFieldWithId" [
  fieldId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<field: record<confirm: bool, consentId: string, control: string, data: record, description: string, id: string, insertInstant: int, key: string, lastUpdateInstant: int, name: string, options: list<string>, required: bool, type: string, validator: record<expression: string, enabled: bool>>, fields: table<confirm: bool, consentId: string, control: string, data: record, description: string, id: string, insertInstant: int, key: string, lastUpdateInstant: int, name: string, options: list, required: bool, type: string, validator: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/form/field/($fieldId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the form field with the given Id.
#
# PUT /api/form/field/{fieldId}
# operationId: updateFormFieldWithId
# --field shape: {confirm?: bool, consentId?: string, control?: "checkbox"|"number"|"password"|"radio"|"select"|"textarea"|"text", data?: record, description?: string, id?: string, insertInstant?: int, key?: string, lastUpdateInstant?: int, name?: string, options?: list, required?: bool, type?: "bool"|"consent"|"date"|"email"|"number"|"phoneNumber"|"string", validator?: record}
# --fields item shape: {confirm?: bool, consentId?: string, control?: "checkbox"|"number"|"password"|"radio"|"select"|"textarea"|"text", data?: record, description?: string, id?: string, insertInstant?: int, key?: string, lastUpdateInstant?: int, name?: string, options?: list, required?: bool, type?: "bool"|"consent"|"date"|"email"|"number"|"phoneNumber"|"string", validator?: record}
export def "form-field updateFormFieldWithId" [
  fieldId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --field: record # shape: {confirm?: bool, consentId?: string, control?: "checkbox"|"number"|"password"|"radio"|"select"|"textarea"|"text", data?: record, description?: string, id?: string, insertInstant?: int, key?: string, lastUpdateInstant?: int, name?: string, options?: list, required?: bool, type?: "bool"|"consent"|"date"|"email"|"number"|"phoneNumber"|"string", validator?: record}
  --body-fields: list # item shape: {confirm?: bool, consentId?: string, control?: "checkbox"|"number"|"password"|"radio"|"select"|"textarea"|"text", data?: record, description?: string, id?: string, insertInstant?: int, key?: string, lastUpdateInstant?: int, name?: string, options?: list, required?: bool, type?: "bool"|"consent"|"date"|"email"|"number"|"phoneNumber"|"string", validator?: record}
]: any -> record<field: record<confirm: bool, consentId: string, control: string, data: record, description: string, id: string, insertInstant: int, key: string, lastUpdateInstant: int, name: string, options: list<string>, required: bool, type: string, validator: record<expression: string, enabled: bool>>, fields: table<confirm: bool, consentId: string, control: string, data: record, description: string, id: string, insertInstant: int, key: string, lastUpdateInstant: int, name: string, options: list, required: bool, type: string, validator: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/form/field/($fieldId)")
  let body = {field: $field, fields: $body_fields} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a form.  You can optionally specify an Id for the form, if not provided one will be generated.
#
# POST /api/form/{formId}
# operationId: createFormWithId
# --form shape: {data?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, steps?: list, type?: "registration"|"adminRegistration"|"adminUser"|"selfServiceUser"}
export def "form createFormWithId" [
  formId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --form: record # shape: {data?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, steps?: list, type?: "registration"|"adminRegistration"|"adminUser"|"selfServiceUser"}
]: any -> record<form: record<data: record, id: string, insertInstant: int, lastUpdateInstant: int, name: string, steps: list<record>, type: string>, forms: table<data: record, id: string, insertInstant: int, lastUpdateInstant: int, name: string, steps: list, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/form/($formId)")
  let body = {form: $form} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the form for the given Id.
#
# DELETE /api/form/{formId}
# operationId: deleteFormWithId
export def "form delete" [
  formId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/form/($formId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patches the form with the given Id.
#
# PATCH /api/form/{formId}
# operationId: patchFormWithId
# --form shape: {data?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, steps?: list, type?: "registration"|"adminRegistration"|"adminUser"|"selfServiceUser"}
export def "form patch" [
  formId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --form: record # shape: {data?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, steps?: list, type?: "registration"|"adminRegistration"|"adminUser"|"selfServiceUser"}
]: any -> record<form: record<data: record, id: string, insertInstant: int, lastUpdateInstant: int, name: string, steps: list<record>, type: string>, forms: table<data: record, id: string, insertInstant: int, lastUpdateInstant: int, name: string, steps: list, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/form/($formId)")
  let body = {form: $form} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the form with the given Id.
#
# GET /api/form/{formId}
# operationId: retrieveFormWithId
export def "form retrieveFormWithId" [
  formId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<form: record<data: record, id: string, insertInstant: int, lastUpdateInstant: int, name: string, steps: list<record>, type: string>, forms: table<data: record, id: string, insertInstant: int, lastUpdateInstant: int, name: string, steps: list, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/form/($formId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the form with the given Id.
#
# PUT /api/form/{formId}
# operationId: updateFormWithId
# --form shape: {data?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, steps?: list, type?: "registration"|"adminRegistration"|"adminUser"|"selfServiceUser"}
export def "form updateFormWithId" [
  formId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --form: record # shape: {data?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, steps?: list, type?: "registration"|"adminRegistration"|"adminUser"|"selfServiceUser"}
]: any -> record<form: record<data: record, id: string, insertInstant: int, lastUpdateInstant: int, name: string, steps: list<record>, type: string>, forms: table<data: record, id: string, insertInstant: int, lastUpdateInstant: int, name: string, steps: list, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/form/($formId)")
  let body = {form: $form} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a group. You can optionally specify an Id for the group, if not provided one will be generated.
#
# POST /api/group
# operationId: createGroup
# --group shape: {data?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, roles?: list, tenantId?: string}
export def "group createGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --group: record # shape: {data?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, roles?: list, tenantId?: string}
  --roleIds: list
]: any -> record<group: record<data: record, id: string, insertInstant: int, lastUpdateInstant: int, name: string, roles: list<record>, tenantId: string>, groups: table<data: record, id: string, insertInstant: int, lastUpdateInstant: int, name: string, roles: list, tenantId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/group")
  let body = {group: $group, roleIds: $roleIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a member in a group.
#
# POST /api/group/member
# operationId: createGroupMembersWithId
# --members item shape: {data?: record, groupId?: string, id?: string, insertInstant?: int, userId?: string}
export def "group-member createGroupMembersWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --members: list # item shape: {data?: record, groupId?: string, id?: string, insertInstant?: int, userId?: string}
]: any -> record<members: table<data: record, groupId: string, id: string, insertInstant: int, userId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/group/member")
  let body = {members: $members} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Removes users as members of a group.
#
# DELETE /api/group/member
# operationId: deleteGroupMembersWithId
export def "group-member delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --memberIds: list
  --members: list
]: any -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/group/member")
  let body = {memberIds: $memberIds, members: $members} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a member in a group.
#
# PUT /api/group/member
# operationId: updateGroupMembersWithId
# --members item shape: {data?: record, groupId?: string, id?: string, insertInstant?: int, userId?: string}
export def "group-member updateGroupMembersWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --members: list # item shape: {data?: record, groupId?: string, id?: string, insertInstant?: int, userId?: string}
]: any -> record<members: table<data: record, groupId: string, id: string, insertInstant: int, userId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/group/member")
  let body = {members: $members} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Searches group members with the specified criteria and pagination.
#
# POST /api/group/member/search
# operationId: searchGroupMembersWithId
# --search shape: {groupId?: string, tenantId?: string, userId?: string, numberOfResults?: int, orderBy?: string, startRow?: int}
export def "group-member-search searchGroupMembersWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: record # Search criteria for Group Members — shape: {groupId?: string, tenantId?: string, userId?: string, numberOfResults?: int, orderBy?: string, startRow?: int}
]: any -> record<members: table<data: record, groupId: string, id: string, insertInstant: int, userId: string>, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/group/member/search")
  let body = {search: $search} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Searches groups with the specified criteria and pagination.
#
# POST /api/group/search
# operationId: searchGroupsWithId
# --search shape: {name?: string, tenantId?: string, numberOfResults?: int, orderBy?: string, startRow?: int}
export def "group-search searchGroupsWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: record # Search criteria for Groups — shape: {name?: string, tenantId?: string, numberOfResults?: int, orderBy?: string, startRow?: int}
]: any -> record<groups: table<data: record, id: string, insertInstant: int, lastUpdateInstant: int, name: string, roles: list, tenantId: string>, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/group/search")
  let body = {search: $search} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a group. You can optionally specify an Id for the group, if not provided one will be generated.
#
# POST /api/group/{groupId}
# operationId: createGroupWithId
# --group shape: {data?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, roles?: list, tenantId?: string}
export def "group createGroupWithId" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --group: record # shape: {data?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, roles?: list, tenantId?: string}
  --roleIds: list
]: any -> record<group: record<data: record, id: string, insertInstant: int, lastUpdateInstant: int, name: string, roles: list<record>, tenantId: string>, groups: table<data: record, id: string, insertInstant: int, lastUpdateInstant: int, name: string, roles: list, tenantId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/group/($groupId)")
  let body = {group: $group, roleIds: $roleIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the group for the given Id.
#
# DELETE /api/group/{groupId}
# operationId: deleteGroupWithId
export def "group delete" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
]: nothing -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/group/($groupId)")
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates, via PATCH, the group with the given Id.
#
# PATCH /api/group/{groupId}
# operationId: patchGroupWithId
# --group shape: {data?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, roles?: list, tenantId?: string}
export def "group patch" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --group: record # shape: {data?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, roles?: list, tenantId?: string}
  --roleIds: list
]: any -> record<group: record<data: record, id: string, insertInstant: int, lastUpdateInstant: int, name: string, roles: list<record>, tenantId: string>, groups: table<data: record, id: string, insertInstant: int, lastUpdateInstant: int, name: string, roles: list, tenantId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/group/($groupId)")
  let body = {group: $group, roleIds: $roleIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the group for the given Id.
#
# GET /api/group/{groupId}
# operationId: retrieveGroupWithId
export def "group retrieveGroupWithId" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
]: nothing -> record<group: record<data: record, id: string, insertInstant: int, lastUpdateInstant: int, name: string, roles: list<record>, tenantId: string>, groups: table<data: record, id: string, insertInstant: int, lastUpdateInstant: int, name: string, roles: list, tenantId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/group/($groupId)")
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the group with the given Id.
#
# PUT /api/group/{groupId}
# operationId: updateGroupWithId
# --group shape: {data?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, roles?: list, tenantId?: string}
export def "group updateGroupWithId" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --group: record # shape: {data?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, roles?: list, tenantId?: string}
  --roleIds: list
]: any -> record<group: record<data: record, id: string, insertInstant: int, lastUpdateInstant: int, name: string, roles: list<record>, tenantId: string>, groups: table<data: record, id: string, insertInstant: int, lastUpdateInstant: int, name: string, roles: list, tenantId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/group/($groupId)")
  let body = {group: $group, roleIds: $roleIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the FusionAuth system health. This API will return 200 if the system is healthy, and 500 if the system is un-healthy.
#
# GET /api/health
# operationId: retrieveSystemHealthWithId
export def "health retrieveSystemHealthWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates an identity provider. You can optionally specify an Id for the identity provider, if not provided one will be generated.
#
# POST /api/identity-provider
# operationId: createIdentityProvider
export def "identity-provider createIdentityProvider" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identityProvider: any
]: any -> record<identityProvider: any, identityProviders: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/identity-provider")
  let body = {identityProvider: $identityProvider} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves one or more identity provider for the given type. For types such as Google, Facebook, Twitter and LinkedIn, only a single  identity provider can exist. For types such as OpenID Connect and SAMLv2 more than one identity provider can be configured so this request  may return multiple identity providers.
#
# GET /api/identity-provider
# operationId: retrieveIdentityProviderByTypeWithId
export def "identity-provider retrieveIdentityProviderByTypeWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string # The type of the identity provider.
]: nothing -> record<identityProvider: any, identityProviders: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/identity-provider" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Link an external user from a 3rd party identity provider to a FusionAuth user.
#
# POST /api/identity-provider/link
# operationId: createUserLinkWithId
# --identityProviderLink shape: {data?: record, displayName?: string, identityProviderId?: string, identityProviderName?: string, identityProviderType?: "Apple"|"EpicGames"|"ExternalJWT"|"Facebook"|"Google"|"HYPR"|"LinkedIn"|"Nintendo"|"OpenIDConnect"|"SAMLv2"|"SAMLv2IdPInitiated"|"SonyPSN"|"Steam"|"Twitch"|"Twitter"|"Xbox", identityProviderUserId?: string, insertInstant?: int, lastLoginInstant?: int, tenantId?: string, token?: string, userId?: string}
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "identity-provider-link createUserLinkWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identityProviderLink: record # shape: {data?: record, displayName?: string, identityProviderId?: string, identityProviderName?: string, identityProviderType?: "Apple"|"EpicGames"|"ExternalJWT"|"Facebook"|"Google"|"HYPR"|"LinkedIn"|"Nintendo"|"OpenIDConnect"|"SAMLv2"|"SAMLv2IdPInitiated"|"SonyPSN"|"Steam"|"Twitch"|"Twitter"|"Xbox", identityProviderUserId?: string, insertInstant?: int, lastLoginInstant?: int, tenantId?: string, token?: string, userId?: string}
  --pendingIdPLinkId: string
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<identityProviderLink: record<data: record, displayName: string, identityProviderId: string, identityProviderName: string, identityProviderType: string, identityProviderUserId: string, insertInstant: int, lastLoginInstant: int, tenantId: string, token: string, userId: string>, identityProviderLinks: table<data: record, displayName: string, identityProviderId: string, identityProviderName: string, identityProviderType: string, identityProviderUserId: string, insertInstant: int, lastLoginInstant: int, tenantId: string, token: string, userId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/identity-provider/link")
  let body = {identityProviderLink: $identityProviderLink, pendingIdPLinkId: $pendingIdPLinkId, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove an existing link that has been made from a 3rd party identity provider to a FusionAuth user.
#
# DELETE /api/identity-provider/link
# operationId: deleteUserLinkWithId
export def "identity-provider-link delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identityProviderId: string # The unique Id of the identity provider.
  --identityProviderUserId: string # The unique Id of the user in the 3rd party identity provider to unlink.
  --userId: string # The unique Id of the FusionAuth user to unlink.
]: nothing -> record<identityProviderLink: record<data: record, displayName: string, identityProviderId: string, identityProviderName: string, identityProviderType: string, identityProviderUserId: string, insertInstant: int, lastLoginInstant: int, tenantId: string, token: string, userId: string>, identityProviderLinks: table<data: record, displayName: string, identityProviderId: string, identityProviderName: string, identityProviderType: string, identityProviderUserId: string, insertInstant: int, lastLoginInstant: int, tenantId: string, token: string, userId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identityProviderId" $identityProviderId "scalar") (serialize-qp "identityProviderUserId" $identityProviderUserId "scalar") (serialize-qp "userId" $userId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/identity-provider/link" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all Identity Provider users (links) for the user. Specify the optional identityProviderId to retrieve links for a particular IdP. OR Retrieve a single Identity Provider user (link).
#
# GET /api/identity-provider/link
# operationId: retrieveIdentityProviderLink
export def "identity-provider-link retrieveIdentityProviderLink" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identityProviderId: string # The unique Id of the identity provider. Specify this value to reduce the links returned to those for a particular IdP.
  --userId: string # The unique Id of the user.
  --identityProviderUserId: string # The unique Id of the user in the 3rd party identity provider.
]: nothing -> record<identityProviderLink: record<data: record, displayName: string, identityProviderId: string, identityProviderName: string, identityProviderType: string, identityProviderUserId: string, insertInstant: int, lastLoginInstant: int, tenantId: string, token: string, userId: string>, identityProviderLinks: table<data: record, displayName: string, identityProviderId: string, identityProviderName: string, identityProviderType: string, identityProviderUserId: string, insertInstant: int, lastLoginInstant: int, tenantId: string, token: string, userId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identityProviderId" $identityProviderId "scalar") (serialize-qp "userId" $userId "scalar") (serialize-qp "identityProviderUserId" $identityProviderUserId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/identity-provider/link" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a pending identity provider link. This is useful to validate a pending link and retrieve meta-data about the identity provider link.
#
# GET /api/identity-provider/link/pending/{pendingLinkId}
# operationId: retrievePendingLinkWithId
export def "identity-provider-link-pending retrievePendingLinkWithId" [
  pendingLinkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userId: string # The optional userId. When provided additional meta-data will be provided to identify how many links if any the user already has.
]: nothing -> record<identityProviderTenantConfiguration: record<data: record, limitUserLinkCount: record<maximumLinks: int, enabled: bool>>, linkCount: int, pendingIdPLink: record<displayName: string, email: string, identityProviderId: string, identityProviderLinks: list<record>, identityProviderName: string, identityProviderTenantConfiguration: record<data: record, limitUserLinkCount: record>, identityProviderType: string, identityProviderUserId: string, user: record<preferredLanguages: list, active: bool, birthDate: string, cleanSpeakId: string, data: record, email: string, expiry: int, firstName: string, fullName: string, imageUrl: string, insertInstant: int, lastName: string, legacyIdentifier: string, lastUpdateInstant: int, middleName: string, mobilePhone: string, parentEmail: string, phoneNumber: string, tenantId: string, timezone: string, twoFactor: record, memberships: list, registrations: list, identities: list, breachedPasswordLastCheckedInstant: int, breachedPasswordStatus: string, connectorId: string, encryptionScheme: string, factor: int, id: string, lastLoginInstant: int, password: string, passwordChangeReason: string, passwordChangeRequired: bool, passwordLastUpdateInstant: int, salt: string, uniqueUsername: string, username: string, usernameStatus: string, verified: bool, verifiedInstant: int>, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $userId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/identity-provider/link/pending/($pendingLinkId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Handles login via third-parties including Social login, external OAuth and OpenID Connect, and other login systems.
#
# POST /api/identity-provider/login
# operationId: identityProviderLoginWithId
# --metaData shape: {data?: record, device?: record, resources?: list, scopes?: list}
export def "identity-provider-login identityProviderLoginWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --connectionTestId: string
  --data: record
  --identityProviderId: string # format: uuid
  --noLink: string@bool-completer
  --encodedJWT: string
  --applicationId: string # format: uuid
  --ipAddress: string
  --metaData: record # shape: {data?: record, device?: record, resources?: list, scopes?: list}
  --newDevice: string@bool-completer
  --noJWT: string@bool-completer
]: any -> record<actions: table<actionId: string, actionerUserId: string, expiry: int, localizedName: string, localizedOption: string, localizedReason: string, name: string, option: string, reason: string, reasonCode: string>, changePasswordId: string, changePasswordReason: string, configurableMethods: list<string>, emailVerificationId: string, identityVerificationId: string, methods: table<authenticator: record, email: string, id: string, lastUsed: bool, method: string, mobilePhone: string, secret: string>, pendingIdPLinkId: string, refreshToken: string, refreshTokenId: string, registrationVerificationId: string, state: record, threatsDetected: list<any>, token: string, tokenExpirationInstant: int, trustToken: string, twoFactorId: string, twoFactorTrustId: string, user: record<preferredLanguages: list<string>, active: bool, birthDate: string, cleanSpeakId: string, data: record, email: string, expiry: int, firstName: string, fullName: string, imageUrl: string, insertInstant: int, lastName: string, legacyIdentifier: string, lastUpdateInstant: int, middleName: string, mobilePhone: string, parentEmail: string, phoneNumber: string, tenantId: string, timezone: string, twoFactor: record<methods: list, recoveryCodes: list>, memberships: list<record>, registrations: list<record>, identities: list<record>, breachedPasswordLastCheckedInstant: int, breachedPasswordStatus: string, connectorId: string, encryptionScheme: string, factor: int, id: string, lastLoginInstant: int, password: string, passwordChangeReason: string, passwordChangeRequired: bool, passwordLastUpdateInstant: int, salt: string, uniqueUsername: string, username: string, usernameStatus: string, verified: bool, verifiedInstant: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/identity-provider/login")
  let body = {connectionTestId: $connectionTestId, data: $data, identityProviderId: $identityProviderId, noLink: $noLink, encodedJWT: $encodedJWT, applicationId: $applicationId, ipAddress: $ipAddress, metaData: $metaData, newDevice: $newDevice, noJWT: $noJWT} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the identity provider for the given domain and tenantId. A 200 response code indicates the domain is managed by a registered identity provider. A 404 indicates the domain is not managed. OR Retrieves any global identity providers for the given domain. A 200 response code indicates the domain is managed by a registered identity provider. A 404 indicates the domain is not managed.
#
# GET /api/identity-provider/lookup
# operationId: retrieveIdentityProviderLookup
export def "identity-provider-lookup retrieveIdentityProviderLookup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --domain: string # The domain or email address to lookup.
  --tenantId: string # If provided, the API searches for an identity provider scoped to the corresponding tenant that manages the requested domain. If no result is found, the API then searches for global identity providers.
]: nothing -> record<identityProvider: record<applicationIds: list<string>, id: string, idpEndpoint: string, name: string, oauth2: record<authorization_endpoint: string, clientAuthenticationMethod: string, client_id: string, client_secret: string, emailClaim: string, emailVerifiedClaim: string, issuer: string, scope: string, token_endpoint: string, uniqueIdClaim: string, userinfo_endpoint: string, usernameClaim: string>, tenantId: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "domain" $domain "scalar") (serialize-qp "tenantId" $tenantId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/identity-provider/lookup" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searches identity providers with the specified criteria and pagination.
#
# POST /api/identity-provider/search
# operationId: searchIdentityProvidersWithId
# --search shape: {applicationId?: string, name?: string, source?: string, tenantId?: string, type?: "Apple"|"EpicGames"|"ExternalJWT"|"Facebook"|"Google"|"HYPR"|"LinkedIn"|"Nintendo"|"OpenIDConnect"|"SAMLv2"|"SAMLv2IdPInitiated"|"SonyPSN"|"Steam"|"Twitch"|"Twitter"|"Xbox", numberOfResults?: int, orderBy?: string, startRow?: int}
export def "identity-provider-search searchIdentityProvidersWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: record # Search criteria for Identity Providers. — shape: {applicationId?: string, name?: string, source?: string, tenantId?: string, type?: "Apple"|"EpicGames"|"ExternalJWT"|"Facebook"|"Google"|"HYPR"|"LinkedIn"|"Nintendo"|"OpenIDConnect"|"SAMLv2"|"SAMLv2IdPInitiated"|"SonyPSN"|"Steam"|"Twitch"|"Twitter"|"Xbox", numberOfResults?: int, orderBy?: string, startRow?: int}
]: any -> record<identityProviders: list<any>, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/identity-provider/search")
  let body = {search: $search} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Begins a login request for a 3rd party login that requires user interaction such as HYPR.
#
# POST /api/identity-provider/start
# operationId: startIdentityProviderLoginWithId
# --metaData shape: {data?: record, device?: record, resources?: list, scopes?: list}
export def "identity-provider-start startIdentityProviderLoginWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --connectionTestId: string
  --data: record
  --identityProviderId: string # format: uuid
  --loginId: string
  --loginIdTypes: list
  --state: record
  --applicationId: string # format: uuid
  --ipAddress: string
  --metaData: record # shape: {data?: record, device?: record, resources?: list, scopes?: list}
  --newDevice: string@bool-completer
  --noJWT: string@bool-completer
]: any -> record<code: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/identity-provider/start")
  let body = {connectionTestId: $connectionTestId, data: $data, identityProviderId: $identityProviderId, loginId: $loginId, loginIdTypes: $loginIdTypes, state: $state, applicationId: $applicationId, ipAddress: $ipAddress, metaData: $metaData, newDevice: $newDevice, noJWT: $noJWT} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the results for an identity provider connection test.
#
# GET /api/identity-provider/test
# operationId: retrieveIdentityProviderConnectionTestResultsWithId
export def "identity-provider-test retrieveIdentityProviderConnectionTestResultsWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --connectionTestId: string # The connection test id to retrieve results for.
]: nothing -> record<connectionTestId: string, result: record<email: string, identityProviderId: string, identityProviderUserId: string, startInstant: int, steps: list<record>, success: bool, username: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "connectionTestId" $connectionTestId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/identity-provider/test" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Begins an identity provider connection test.
#
# POST /api/identity-provider/test
# operationId: startIdentityProviderConnectionTestWithId
export def "identity-provider-test startIdentityProviderConnectionTestWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identityProviderId: string # format: uuid
  --tenantId: string # format: uuid
]: any -> record<connectionTestId: string, result: record<email: string, identityProviderId: string, identityProviderUserId: string, startInstant: int, steps: list<record>, success: bool, username: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/identity-provider/test")
  let body = {identityProviderId: $identityProviderId, tenantId: $tenantId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates an identity provider. You can optionally specify an Id for the identity provider, if not provided one will be generated.
#
# POST /api/identity-provider/{identityProviderId}
# operationId: createIdentityProviderWithId
export def "identity-provider createIdentityProviderWithId" [
  identityProviderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identityProvider: any
]: any -> record<identityProvider: any, identityProviders: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/identity-provider/($identityProviderId)")
  let body = {identityProvider: $identityProvider} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the identity provider for the given Id.
#
# DELETE /api/identity-provider/{identityProviderId}
# operationId: deleteIdentityProviderWithId
export def "identity-provider delete" [
  identityProviderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/identity-provider/($identityProviderId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates, via PATCH, the identity provider with the given Id.
#
# PATCH /api/identity-provider/{identityProviderId}
# operationId: patchIdentityProviderWithId
export def "identity-provider patch" [
  identityProviderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identityProvider: any
]: any -> record<identityProvider: any, identityProviders: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/identity-provider/($identityProviderId)")
  let body = {identityProvider: $identityProvider} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the identity provider for the given Id or all the identity providers if the Id is null.
#
# GET /api/identity-provider/{identityProviderId}
# operationId: retrieveIdentityProviderWithId
export def "identity-provider retrieveIdentityProviderWithId" [
  identityProviderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<identityProvider: any, identityProviders: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/identity-provider/($identityProviderId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the identity provider with the given Id.
#
# PUT /api/identity-provider/{identityProviderId}
# operationId: updateIdentityProviderWithId
export def "identity-provider updateIdentityProviderWithId" [
  identityProviderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identityProvider: any
]: any -> record<identityProvider: any, identityProviders: list<any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/identity-provider/($identityProviderId)")
  let body = {identityProvider: $identityProvider} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Administratively verify a user identity.
#
# POST /api/identity/verify
# operationId: verifyIdentityWithId
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "identity-verify verifyIdentityWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --loginId: string
  --loginIdType: string
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/identity/verify")
  let body = {loginId: $loginId, loginIdType: $loginIdType, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Completes verification of an identity using verification codes from the Verify Start API.
#
# POST /api/identity/verify/complete
# operationId: completeVerifyIdentityWithId
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "identity-verify-complete completeVerifyIdentityWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --oneTimeCode: string
  --verificationId: string
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<state: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/identity/verify/complete")
  let body = {oneTimeCode: $oneTimeCode, verificationId: $verificationId, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send a verification code using the appropriate transport for the identity type being verified.
#
# POST /api/identity/verify/send
# operationId: sendVerifyIdentityWithId
export def "identity-verify-send sendVerifyIdentityWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --verificationId: string
]: any -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/identity/verify/send")
  let body = {verificationId: $verificationId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Start a verification of an identity by generating a code. This code can be sent to the User using the Verify Send API Verification Code API or using a mechanism outside of FusionAuth. The verification is completed by using the Verify Complete API with this code.
#
# POST /api/identity/verify/start
# operationId: startVerifyIdentityWithId
export def "identity-verify-start startVerifyIdentityWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applicationId: string # format: uuid
  --existingUserStrategy: string@existingUserStrategy-completer # Represent the various statesexpectations of a user in the context of starting verification
  --loginId: string
  --loginIdType: string
  --state: record
  --verificationStrategy: string@verificationStrategy-completer
]: any -> record<oneTimeCode: string, verificationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/identity/verify/start")
  let body = {applicationId: $applicationId, existingUserStrategy: $existingUserStrategy, loginId: $loginId, loginIdType: $loginIdType, state: $state, verificationStrategy: $verificationStrategy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates, via PATCH, the available integrations.
#
# PATCH /api/integration
# operationId: patchIntegrationsWithId
# --integrations shape: {cleanspeak?: record, kafka?: record}
export def "integration patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --integrations: record # Available Integrations — shape: {cleanspeak?: record, kafka?: record}
]: any -> record<integrations: record<cleanspeak: record<apiKey: string, applicationIds: list, url: string, usernameModeration: record, enabled: bool>, kafka: record<defaultTopic: string, producer: record, enabled: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/integration")
  let body = {integrations: $integrations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates the available integrations.
#
# PUT /api/integration
# operationId: updateIntegrationsWithId
# --integrations shape: {cleanspeak?: record, kafka?: record}
export def "integration updateIntegrationsWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --integrations: record # Available Integrations — shape: {cleanspeak?: record, kafka?: record}
]: any -> record<integrations: record<cleanspeak: record<apiKey: string, applicationIds: list, url: string, usernameModeration: record, enabled: bool>, kafka: record<defaultTopic: string, producer: record, enabled: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/integration")
  let body = {integrations: $integrations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates an IP Access Control List. You can optionally specify an Id on this create request, if one is not provided one will be generated.
#
# POST /api/ip-acl
# operationId: createIPAccessControlList
# --ipAccessControlList shape: {data?: record, entries?: list, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string}
export def "ip-acl createIPAccessControlList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ipAccessControlList: record # shape: {data?: record, entries?: list, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string}
]: any -> record<ipAccessControlList: record<data: record, entries: list<record>, id: string, insertInstant: int, lastUpdateInstant: int, name: string>, ipAccessControlLists: table<data: record, entries: list, id: string, insertInstant: int, lastUpdateInstant: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/ip-acl")
  let body = {ipAccessControlList: $ipAccessControlList} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Searches the IP Access Control Lists with the specified criteria and pagination.
#
# POST /api/ip-acl/search
# operationId: searchIPAccessControlListsWithId
# --search shape: {name?: string, numberOfResults?: int, orderBy?: string, startRow?: int}
export def "ip-acl-search searchIPAccessControlListsWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: record # shape: {name?: string, numberOfResults?: int, orderBy?: string, startRow?: int}
]: any -> record<ipAccessControlLists: table<data: record, entries: list, id: string, insertInstant: int, lastUpdateInstant: int, name: string>, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/ip-acl/search")
  let body = {search: $search} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates an IP Access Control List. You can optionally specify an Id on this create request, if one is not provided one will be generated.
#
# POST /api/ip-acl/{accessControlListId}
# operationId: createIPAccessControlListWithId
# --ipAccessControlList shape: {data?: record, entries?: list, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string}
export def "ip-acl createIPAccessControlListWithId" [
  accessControlListId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ipAccessControlList: record # shape: {data?: record, entries?: list, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string}
]: any -> record<ipAccessControlList: record<data: record, entries: list<record>, id: string, insertInstant: int, lastUpdateInstant: int, name: string>, ipAccessControlLists: table<data: record, entries: list, id: string, insertInstant: int, lastUpdateInstant: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/ip-acl/($accessControlListId)")
  let body = {ipAccessControlList: $ipAccessControlList} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update the IP Access Control List with the given Id.
#
# PATCH /api/ip-acl/{accessControlListId}
# operationId: patchIPAccessControlListWithId
# --ipAccessControlList shape: {data?: record, entries?: list, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string}
export def "ip-acl patch" [
  accessControlListId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ipAccessControlList: record # shape: {data?: record, entries?: list, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string}
]: any -> record<ipAccessControlList: record<data: record, entries: list<record>, id: string, insertInstant: int, lastUpdateInstant: int, name: string>, ipAccessControlLists: table<data: record, entries: list, id: string, insertInstant: int, lastUpdateInstant: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/ip-acl/($accessControlListId)")
  let body = {ipAccessControlList: $ipAccessControlList} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates the IP Access Control List with the given Id.
#
# PUT /api/ip-acl/{accessControlListId}
# operationId: updateIPAccessControlListWithId
# --ipAccessControlList shape: {data?: record, entries?: list, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string}
export def "ip-acl updateIPAccessControlListWithId" [
  accessControlListId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ipAccessControlList: record # shape: {data?: record, entries?: list, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string}
]: any -> record<ipAccessControlList: record<data: record, entries: list<record>, id: string, insertInstant: int, lastUpdateInstant: int, name: string>, ipAccessControlLists: table<data: record, entries: list, id: string, insertInstant: int, lastUpdateInstant: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/ip-acl/($accessControlListId)")
  let body = {ipAccessControlList: $ipAccessControlList} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the IP Access Control List for the given Id.
#
# DELETE /api/ip-acl/{ipAccessControlListId}
# operationId: deleteIPAccessControlListWithId
export def "ip-acl delete" [
  ipAccessControlListId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/ip-acl/($ipAccessControlListId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the IP Access Control List with the given Id.
#
# GET /api/ip-acl/{ipAccessControlListId}
# operationId: retrieveIPAccessControlListWithId
export def "ip-acl retrieveIPAccessControlListWithId" [
  ipAccessControlListId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<ipAccessControlList: record<data: record, entries: list<record>, id: string, insertInstant: int, lastUpdateInstant: int, name: string>, ipAccessControlLists: table<data: record, entries: list, id: string, insertInstant: int, lastUpdateInstant: int, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/ip-acl/($ipAccessControlListId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Issue a new access token (JWT) for the requested Application after ensuring the provided JWT is valid. A valid access token is properly signed and not expired. <p> This API may be used in an SSO configuration to issue new tokens for another application after the user has obtained a valid token from authentication.
#
# GET /api/jwt/issue
# operationId: issueJWTWithId
export def "jwt-issue issueJWTWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applicationId: string # The Application Id for which you are requesting a new access token be issued.
  --refreshToken: string # An existing refresh token used to request a refresh token in addition to a JWT in the response. <p>The target application represented by the applicationId request parameter must have refresh tokens enabled in order to receive a refresh token in the response.</p>
]: nothing -> record<refreshToken: string, token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "applicationId" $applicationId "scalar") (serialize-qp "refreshToken" $refreshToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/jwt/issue" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the Public Key configured for verifying the JSON Web Tokens (JWT) issued by the Login API by the Application Id. OR Retrieves the Public Key configured for verifying JSON Web Tokens (JWT) by the key Id (kid).
#
# GET /api/jwt/public-key
# operationId: retrieveJwtPublicKey
export def "jwt-public-key retrieveJwtPublicKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applicationId: string # The Id of the Application for which this key is used.
  --keyId: string # The Id of the public key (kid).
]: nothing -> record<publicKey: string, publicKeys: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "applicationId" $applicationId "scalar") (serialize-qp "keyId" $keyId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/jwt/public-key" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reconcile a User to FusionAuth using JWT issued from another Identity Provider.
#
# POST /api/jwt/reconcile
# operationId: reconcileJWTWithId
# --metaData shape: {data?: record, device?: record, resources?: list, scopes?: list}
export def "jwt-reconcile reconcileJWTWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --connectionTestId: string
  --data: record
  --identityProviderId: string # format: uuid
  --noLink: string@bool-completer
  --encodedJWT: string
  --applicationId: string # format: uuid
  --ipAddress: string
  --metaData: record # shape: {data?: record, device?: record, resources?: list, scopes?: list}
  --newDevice: string@bool-completer
  --noJWT: string@bool-completer
]: any -> record<actions: table<actionId: string, actionerUserId: string, expiry: int, localizedName: string, localizedOption: string, localizedReason: string, name: string, option: string, reason: string, reasonCode: string>, changePasswordId: string, changePasswordReason: string, configurableMethods: list<string>, emailVerificationId: string, identityVerificationId: string, methods: table<authenticator: record, email: string, id: string, lastUsed: bool, method: string, mobilePhone: string, secret: string>, pendingIdPLinkId: string, refreshToken: string, refreshTokenId: string, registrationVerificationId: string, state: record, threatsDetected: list<any>, token: string, tokenExpirationInstant: int, trustToken: string, twoFactorId: string, twoFactorTrustId: string, user: record<preferredLanguages: list<string>, active: bool, birthDate: string, cleanSpeakId: string, data: record, email: string, expiry: int, firstName: string, fullName: string, imageUrl: string, insertInstant: int, lastName: string, legacyIdentifier: string, lastUpdateInstant: int, middleName: string, mobilePhone: string, parentEmail: string, phoneNumber: string, tenantId: string, timezone: string, twoFactor: record<methods: list, recoveryCodes: list>, memberships: list<record>, registrations: list<record>, identities: list<record>, breachedPasswordLastCheckedInstant: int, breachedPasswordStatus: string, connectorId: string, encryptionScheme: string, factor: int, id: string, lastLoginInstant: int, password: string, passwordChangeReason: string, passwordChangeRequired: bool, passwordLastUpdateInstant: int, salt: string, uniqueUsername: string, username: string, usernameStatus: string, verified: bool, verifiedInstant: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/jwt/reconcile")
  let body = {connectionTestId: $connectionTestId, data: $data, identityProviderId: $identityProviderId, noLink: $noLink, encodedJWT: $encodedJWT, applicationId: $applicationId, ipAddress: $ipAddress, metaData: $metaData, newDevice: $newDevice, noJWT: $noJWT} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Exchange a refresh token for a new JWT.
#
# POST /api/jwt/refresh
# operationId: exchangeRefreshTokenForJWTWithId
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "jwt-refresh exchangeRefreshTokenForJWTWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --refreshToken: string
  --timeToLiveInSeconds: int
  --body-token: string
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<refreshToken: string, refreshTokenId: string, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/jwt/refresh")
  let body = {refreshToken: $refreshToken, timeToLiveInSeconds: $timeToLiveInSeconds, token: $body_token, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the refresh tokens that belong to the user with the given Id.
#
# GET /api/jwt/refresh
# operationId: retrieveRefreshTokensWithId
export def "jwt-refresh retrieveRefreshTokensWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userId: string # The Id of the user.
]: nothing -> record<refreshToken: record<applicationId: string, data: record, id: string, insertInstant: int, metaData: record<data: record, device: record, resources: list, scopes: list>, startInstant: int, tenantId: string, token: string, userId: string>, refreshTokens: table<applicationId: string, data: record, id: string, insertInstant: int, metaData: record, startInstant: int, tenantId: string, token: string, userId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $userId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/jwt/refresh" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revokes refresh tokens using the information in the JSON body. The handling for this method is the same as the revokeRefreshToken method and is based on the information you provide in the RefreshDeleteRequest object. See that method for additional information. OR Revoke all refresh tokens that belong to a user by user Id for a specific application by applicationId. OR Revoke all refresh tokens that belong to a user by user Id. OR Revoke all refresh tokens that belong to an application by applicationId. OR Revokes a single refresh token by using the actual refresh token value. This refresh token value is sensitive, so  be careful with this API request. OR Revokes refresh tokens.  Usage examples:   - Delete a single refresh token, pass in only the token.       revokeRefreshToken(token)    - Delete all refresh tokens for a user, pass in only the userId.       revokeRefreshToken(null, userId)    - Delete all refresh tokens for a user for a specific application, pass in both the userId and the applicationId.       revokeRefreshToken(null, userId, applicationId)    - Delete all refresh tokens for an application       revokeRefreshToken(null, null, applicationId)  Note: <code>null</code> may be handled differently depending upon the programming language.  See also: (method names may vary by language... but you'll figure it out)   - revokeRefreshTokenById  - revokeRefreshTokenByToken  - revokeRefreshTokensByUserId  - revokeRefreshTokensByApplicationId  - revokeRefreshTokensByUserIdForApplication
#
# DELETE /api/jwt/refresh
# operationId: deleteJwtRefresh
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "jwt-refresh delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userId: string # The unique Id of the user that you want to delete all refresh tokens for.
  --applicationId: string # The unique Id of the application that you want to delete refresh tokens for.
  --qp-token: string # The refresh token to delete.
  --applicationId: string # format: uuid
  --body-token: string
  --userId: string # format: uuid
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $userId "scalar") (serialize-qp "applicationId" $applicationId "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/jwt/refresh" $qp)
  let body = {applicationId: $applicationId, token: $body_token, userId: $userId, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves a single refresh token by unique Id. This is not the same thing as the string value of the refresh token. If you have that, you already have what you need.
#
# GET /api/jwt/refresh/{tokenId}
# operationId: retrieveRefreshTokenByIdWithId
export def "jwt-refresh retrieveRefreshTokenByIdWithId" [
  tokenId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<refreshToken: record<applicationId: string, data: record, id: string, insertInstant: int, metaData: record<data: record, device: record, resources: list, scopes: list>, startInstant: int, tenantId: string, token: string, userId: string>, refreshTokens: table<applicationId: string, data: record, id: string, insertInstant: int, metaData: record, startInstant: int, tenantId: string, token: string, userId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/jwt/refresh/($tokenId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revokes a single refresh token by the unique Id. The unique Id is not sensitive as it cannot be used to obtain another JWT.
#
# DELETE /api/jwt/refresh/{tokenId}
# operationId: revokeRefreshTokenByIdWithId
export def "jwt-refresh revokeRefreshTokenByIdWithId" [
  tokenId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/jwt/refresh/($tokenId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Validates the provided JWT (encoded JWT string) to ensure the token is valid. A valid access token is properly signed and not expired. <p> This API may be used to verify the JWT as well as decode the encoded JWT into human readable identity claims.
#
# GET /api/jwt/validate
# operationId: validateJWTWithId
export def "jwt-validate validateJWTWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<jwt: record<aud: record, exp: int, iat: int, iss: string, nbf: int, otherClaims: record, sub: string, jti: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/jwt/validate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# It's a JWT vending machine!  Issue a new access token (JWT) with the provided claims in the request. This JWT is not scoped to a tenant or user, it is a free form  token that will contain what claims you provide. <p> The iat, exp and jti claims will be added by FusionAuth, all other claims must be provided by the caller.  If a TTL is not provided in the request, the TTL will be retrieved from the default Tenant or the Tenant specified on the request either  by way of the X-FusionAuth-TenantId request header, or a tenant scoped API key.
#
# POST /api/jwt/vend
# operationId: vendJWTWithId
export def "jwt-vend vendJWTWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --claims: record
  --keyId: string # format: uuid
  --timeToLiveInSeconds: int
]: any -> record<token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/jwt/vend")
  let body = {claims: $claims, keyId: $keyId, timeToLiveInSeconds: $timeToLiveInSeconds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves all the keys.
#
# GET /api/key
# operationId: retrieveKeysWithId
export def "key retrieveKeysWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: record<algorithm: string, certificate: string, certificateInformation: record<issuer: string, md5Fingerprint: string, serialNumber: string, sha1Fingerprint: string, sha1Thumbprint: string, sha256Fingerprint: string, sha256Thumbprint: string, subject: string, validFrom: int, validTo: int>, expirationInstant: int, hasPrivateKey: bool, id: string, insertInstant: int, issuer: string, kid: string, lastUpdateInstant: int, length: int, name: string, privateKey: string, publicKey: string, secret: string, type: string>, keys: table<algorithm: string, certificate: string, certificateInformation: record, expirationInstant: int, hasPrivateKey: bool, id: string, insertInstant: int, issuer: string, kid: string, lastUpdateInstant: int, length: int, name: string, privateKey: string, publicKey: string, secret: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/key")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate a new RSA or EC key pair or an HMAC secret.
#
# POST /api/key/generate
# operationId: generateKey
# --key shape: {algorithm?: "ES256"|"ES384"|"ES512"|"HS256"|"HS384"|"HS512"|"RS256"|"RS384"|"RS512"|"Ed25519"|"None", certificate?: string, certificateInformation?: record, expirationInstant?: int, hasPrivateKey?: bool, id?: string, insertInstant?: int, issuer?: string, kid?: string, lastUpdateInstant?: int, length?: int, name?: string, privateKey?: string, publicKey?: string, secret?: string, type?: "EC"|"RSA"|"HMAC"|"OKP"|"Secret"}
export def "key-generate generateKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key: record # Domain for a public key, key pair or an HMAC secret. This is used by KeyMaster to manage keys for JWTs, SAML, etc. — shape: {algorithm?: "ES256"|"ES384"|"ES512"|"HS256"|"HS384"|"HS512"|"RS256"|"RS384"|"RS512"|"Ed25519"|"None", certificate?: string, certificateInformation?: record, expirationInstant?: int, hasPrivateKey?: bool, id?: string, insertInstant?: int, issuer?: string, kid?: string, lastUpdateInstant?: int, length?: int, name?: string, privateKey?: string, publicKey?: string, secret?: string, type?: "EC"|"RSA"|"HMAC"|"OKP"|"Secret"}
]: any -> record<key: record<algorithm: string, certificate: string, certificateInformation: record<issuer: string, md5Fingerprint: string, serialNumber: string, sha1Fingerprint: string, sha1Thumbprint: string, sha256Fingerprint: string, sha256Thumbprint: string, subject: string, validFrom: int, validTo: int>, expirationInstant: int, hasPrivateKey: bool, id: string, insertInstant: int, issuer: string, kid: string, lastUpdateInstant: int, length: int, name: string, privateKey: string, publicKey: string, secret: string, type: string>, keys: table<algorithm: string, certificate: string, certificateInformation: record, expirationInstant: int, hasPrivateKey: bool, id: string, insertInstant: int, issuer: string, kid: string, lastUpdateInstant: int, length: int, name: string, privateKey: string, publicKey: string, secret: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/key/generate")
  let body = {key: $key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate a new RSA or EC key pair or an HMAC secret.
#
# POST /api/key/generate/{keyId}
# operationId: generateKeyWithId
# --key shape: {algorithm?: "ES256"|"ES384"|"ES512"|"HS256"|"HS384"|"HS512"|"RS256"|"RS384"|"RS512"|"Ed25519"|"None", certificate?: string, certificateInformation?: record, expirationInstant?: int, hasPrivateKey?: bool, id?: string, insertInstant?: int, issuer?: string, kid?: string, lastUpdateInstant?: int, length?: int, name?: string, privateKey?: string, publicKey?: string, secret?: string, type?: "EC"|"RSA"|"HMAC"|"OKP"|"Secret"}
export def "key-generate generateKeyWithId" [
  keyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key: record # Domain for a public key, key pair or an HMAC secret. This is used by KeyMaster to manage keys for JWTs, SAML, etc. — shape: {algorithm?: "ES256"|"ES384"|"ES512"|"HS256"|"HS384"|"HS512"|"RS256"|"RS384"|"RS512"|"Ed25519"|"None", certificate?: string, certificateInformation?: record, expirationInstant?: int, hasPrivateKey?: bool, id?: string, insertInstant?: int, issuer?: string, kid?: string, lastUpdateInstant?: int, length?: int, name?: string, privateKey?: string, publicKey?: string, secret?: string, type?: "EC"|"RSA"|"HMAC"|"OKP"|"Secret"}
]: any -> record<key: record<algorithm: string, certificate: string, certificateInformation: record<issuer: string, md5Fingerprint: string, serialNumber: string, sha1Fingerprint: string, sha1Thumbprint: string, sha256Fingerprint: string, sha256Thumbprint: string, subject: string, validFrom: int, validTo: int>, expirationInstant: int, hasPrivateKey: bool, id: string, insertInstant: int, issuer: string, kid: string, lastUpdateInstant: int, length: int, name: string, privateKey: string, publicKey: string, secret: string, type: string>, keys: table<algorithm: string, certificate: string, certificateInformation: record, expirationInstant: int, hasPrivateKey: bool, id: string, insertInstant: int, issuer: string, kid: string, lastUpdateInstant: int, length: int, name: string, privateKey: string, publicKey: string, secret: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/key/generate/($keyId)")
  let body = {key: $key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Import an existing RSA or EC key pair or an HMAC secret.
#
# POST /api/key/import
# operationId: importKey
# --key shape: {algorithm?: "ES256"|"ES384"|"ES512"|"HS256"|"HS384"|"HS512"|"RS256"|"RS384"|"RS512"|"Ed25519"|"None", certificate?: string, certificateInformation?: record, expirationInstant?: int, hasPrivateKey?: bool, id?: string, insertInstant?: int, issuer?: string, kid?: string, lastUpdateInstant?: int, length?: int, name?: string, privateKey?: string, publicKey?: string, secret?: string, type?: "EC"|"RSA"|"HMAC"|"OKP"|"Secret"}
export def "key-import importKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key: record # Domain for a public key, key pair or an HMAC secret. This is used by KeyMaster to manage keys for JWTs, SAML, etc. — shape: {algorithm?: "ES256"|"ES384"|"ES512"|"HS256"|"HS384"|"HS512"|"RS256"|"RS384"|"RS512"|"Ed25519"|"None", certificate?: string, certificateInformation?: record, expirationInstant?: int, hasPrivateKey?: bool, id?: string, insertInstant?: int, issuer?: string, kid?: string, lastUpdateInstant?: int, length?: int, name?: string, privateKey?: string, publicKey?: string, secret?: string, type?: "EC"|"RSA"|"HMAC"|"OKP"|"Secret"}
]: any -> record<key: record<algorithm: string, certificate: string, certificateInformation: record<issuer: string, md5Fingerprint: string, serialNumber: string, sha1Fingerprint: string, sha1Thumbprint: string, sha256Fingerprint: string, sha256Thumbprint: string, subject: string, validFrom: int, validTo: int>, expirationInstant: int, hasPrivateKey: bool, id: string, insertInstant: int, issuer: string, kid: string, lastUpdateInstant: int, length: int, name: string, privateKey: string, publicKey: string, secret: string, type: string>, keys: table<algorithm: string, certificate: string, certificateInformation: record, expirationInstant: int, hasPrivateKey: bool, id: string, insertInstant: int, issuer: string, kid: string, lastUpdateInstant: int, length: int, name: string, privateKey: string, publicKey: string, secret: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/key/import")
  let body = {key: $key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Import an existing RSA or EC key pair or an HMAC secret.
#
# POST /api/key/import/{keyId}
# operationId: importKeyWithId
# --key shape: {algorithm?: "ES256"|"ES384"|"ES512"|"HS256"|"HS384"|"HS512"|"RS256"|"RS384"|"RS512"|"Ed25519"|"None", certificate?: string, certificateInformation?: record, expirationInstant?: int, hasPrivateKey?: bool, id?: string, insertInstant?: int, issuer?: string, kid?: string, lastUpdateInstant?: int, length?: int, name?: string, privateKey?: string, publicKey?: string, secret?: string, type?: "EC"|"RSA"|"HMAC"|"OKP"|"Secret"}
export def "key-import importKeyWithId" [
  keyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key: record # Domain for a public key, key pair or an HMAC secret. This is used by KeyMaster to manage keys for JWTs, SAML, etc. — shape: {algorithm?: "ES256"|"ES384"|"ES512"|"HS256"|"HS384"|"HS512"|"RS256"|"RS384"|"RS512"|"Ed25519"|"None", certificate?: string, certificateInformation?: record, expirationInstant?: int, hasPrivateKey?: bool, id?: string, insertInstant?: int, issuer?: string, kid?: string, lastUpdateInstant?: int, length?: int, name?: string, privateKey?: string, publicKey?: string, secret?: string, type?: "EC"|"RSA"|"HMAC"|"OKP"|"Secret"}
]: any -> record<key: record<algorithm: string, certificate: string, certificateInformation: record<issuer: string, md5Fingerprint: string, serialNumber: string, sha1Fingerprint: string, sha1Thumbprint: string, sha256Fingerprint: string, sha256Thumbprint: string, subject: string, validFrom: int, validTo: int>, expirationInstant: int, hasPrivateKey: bool, id: string, insertInstant: int, issuer: string, kid: string, lastUpdateInstant: int, length: int, name: string, privateKey: string, publicKey: string, secret: string, type: string>, keys: table<algorithm: string, certificate: string, certificateInformation: record, expirationInstant: int, hasPrivateKey: bool, id: string, insertInstant: int, issuer: string, kid: string, lastUpdateInstant: int, length: int, name: string, privateKey: string, publicKey: string, secret: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/key/import/($keyId)")
  let body = {key: $key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Searches keys with the specified criteria and pagination.
#
# POST /api/key/search
# operationId: searchKeysWithId
# --search shape: {algorithm?: "ES256"|"ES384"|"ES512"|"HS256"|"HS384"|"HS512"|"RS256"|"RS384"|"RS512"|"Ed25519"|"None", name?: string, type?: "EC"|"RSA"|"HMAC"|"OKP"|"Secret", numberOfResults?: int, orderBy?: string, startRow?: int}
export def "key-search searchKeysWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: record # Search criteria for Keys — shape: {algorithm?: "ES256"|"ES384"|"ES512"|"HS256"|"HS384"|"HS512"|"RS256"|"RS384"|"RS512"|"Ed25519"|"None", name?: string, type?: "EC"|"RSA"|"HMAC"|"OKP"|"Secret", numberOfResults?: int, orderBy?: string, startRow?: int}
]: any -> record<keys: table<algorithm: string, certificate: string, certificateInformation: record, expirationInstant: int, hasPrivateKey: bool, id: string, insertInstant: int, issuer: string, kid: string, lastUpdateInstant: int, length: int, name: string, privateKey: string, publicKey: string, secret: string, type: string>, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/key/search")
  let body = {search: $search} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the key for the given Id.
#
# DELETE /api/key/{keyId}
# operationId: deleteKeyWithId
export def "key delete" [
  keyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/key/($keyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the key for the given Id.
#
# GET /api/key/{keyId}
# operationId: retrieveKeyWithId
export def "key retrieveKeyWithId" [
  keyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<key: record<algorithm: string, certificate: string, certificateInformation: record<issuer: string, md5Fingerprint: string, serialNumber: string, sha1Fingerprint: string, sha1Thumbprint: string, sha256Fingerprint: string, sha256Thumbprint: string, subject: string, validFrom: int, validTo: int>, expirationInstant: int, hasPrivateKey: bool, id: string, insertInstant: int, issuer: string, kid: string, lastUpdateInstant: int, length: int, name: string, privateKey: string, publicKey: string, secret: string, type: string>, keys: table<algorithm: string, certificate: string, certificateInformation: record, expirationInstant: int, hasPrivateKey: bool, id: string, insertInstant: int, issuer: string, kid: string, lastUpdateInstant: int, length: int, name: string, privateKey: string, publicKey: string, secret: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/key/($keyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the key with the given Id.
#
# PUT /api/key/{keyId}
# operationId: updateKeyWithId
# --key shape: {algorithm?: "ES256"|"ES384"|"ES512"|"HS256"|"HS384"|"HS512"|"RS256"|"RS384"|"RS512"|"Ed25519"|"None", certificate?: string, certificateInformation?: record, expirationInstant?: int, hasPrivateKey?: bool, id?: string, insertInstant?: int, issuer?: string, kid?: string, lastUpdateInstant?: int, length?: int, name?: string, privateKey?: string, publicKey?: string, secret?: string, type?: "EC"|"RSA"|"HMAC"|"OKP"|"Secret"}
export def "key updateKeyWithId" [
  keyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key: record # Domain for a public key, key pair or an HMAC secret. This is used by KeyMaster to manage keys for JWTs, SAML, etc. — shape: {algorithm?: "ES256"|"ES384"|"ES512"|"HS256"|"HS384"|"HS512"|"RS256"|"RS384"|"RS512"|"Ed25519"|"None", certificate?: string, certificateInformation?: record, expirationInstant?: int, hasPrivateKey?: bool, id?: string, insertInstant?: int, issuer?: string, kid?: string, lastUpdateInstant?: int, length?: int, name?: string, privateKey?: string, publicKey?: string, secret?: string, type?: "EC"|"RSA"|"HMAC"|"OKP"|"Secret"}
]: any -> record<key: record<algorithm: string, certificate: string, certificateInformation: record<issuer: string, md5Fingerprint: string, serialNumber: string, sha1Fingerprint: string, sha1Thumbprint: string, sha256Fingerprint: string, sha256Thumbprint: string, subject: string, validFrom: int, validTo: int>, expirationInstant: int, hasPrivateKey: bool, id: string, insertInstant: int, issuer: string, kid: string, lastUpdateInstant: int, length: int, name: string, privateKey: string, publicKey: string, secret: string, type: string>, keys: table<algorithm: string, certificate: string, certificateInformation: record, expirationInstant: int, hasPrivateKey: bool, id: string, insertInstant: int, issuer: string, kid: string, lastUpdateInstant: int, length: int, name: string, privateKey: string, publicKey: string, secret: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/key/($keyId)")
  let body = {key: $key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a Lambda. You can optionally specify an Id for the lambda, if not provided one will be generated.
#
# POST /api/lambda
# operationId: createLambda
# --lambda shape: {body?: string, debug?: bool, engineType?: "GraalJS"|"Nashorn", id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, type?: "JWTPopulate"|"OpenIDReconcile"|"SAMLv2Reconcile"|"SAMLv2Populate"|"AppleReconcile"|"ExternalJWTReconcile"|"FacebookReconcile"|"GoogleReconcile"|"HYPRReconcile"|"TwitterReconcile"|"LDAPConnectorReconcile"|"LinkedInReconcile"|"EpicGamesReconcile"|"NintendoReconcile"|"SonyPSNReconcile"|"SteamReconcile"|"TwitchReconcile"|"XboxReconcile"|"ClientCredentialsJWTPopulate"|"SCIMServerGroupRequestConverter"|"SCIMServerGroupResponseConverter"|"SCIMServerUserRequestConverter"|"SCIMServerUserResponseConverter"|"SelfServiceRegistrationValidation"|"UserInfoPopulate"|"LoginValidation"|"MFARequirement"}
export def "lambda createLambda" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --lambda: record # A JavaScript lambda function that is executed during certain events inside FusionAuth. — shape: {body?: string, debug?: bool, engineType?: "GraalJS"|"Nashorn", id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, type?: "JWTPopulate"|"OpenIDReconcile"|"SAMLv2Reconcile"|"SAMLv2Populate"|"AppleReconcile"|"ExternalJWTReconcile"|"FacebookReconcile"|"GoogleReconcile"|"HYPRReconcile"|"TwitterReconcile"|"LDAPConnectorReconcile"|"LinkedInReconcile"|"EpicGamesReconcile"|"NintendoReconcile"|"SonyPSNReconcile"|"SteamReconcile"|"TwitchReconcile"|"XboxReconcile"|"ClientCredentialsJWTPopulate"|"SCIMServerGroupRequestConverter"|"SCIMServerGroupResponseConverter"|"SCIMServerUserRequestConverter"|"SCIMServerUserResponseConverter"|"SelfServiceRegistrationValidation"|"UserInfoPopulate"|"LoginValidation"|"MFARequirement"}
]: any -> record<lambda: record<body: string, debug: bool, engineType: string, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>, lambdas: table<body: string, debug: bool, engineType: string, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/lambda")
  let body = {lambda: $lambda} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves all the lambdas for the provided type.
#
# GET /api/lambda
# operationId: retrieveLambdasByTypeWithId
export def "lambda retrieveLambdasByTypeWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string # The type of the lambda to return.
]: nothing -> record<lambda: record<body: string, debug: bool, engineType: string, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>, lambdas: table<body: string, debug: bool, engineType: string, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/lambda" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searches lambdas with the specified criteria and pagination.
#
# POST /api/lambda/search
# operationId: searchLambdasWithId
# --search shape: {body?: string, name?: string, type?: "JWTPopulate"|"OpenIDReconcile"|"SAMLv2Reconcile"|"SAMLv2Populate"|"AppleReconcile"|"ExternalJWTReconcile"|"FacebookReconcile"|"GoogleReconcile"|"HYPRReconcile"|"TwitterReconcile"|"LDAPConnectorReconcile"|"LinkedInReconcile"|"EpicGamesReconcile"|"NintendoReconcile"|"SonyPSNReconcile"|"SteamReconcile"|"TwitchReconcile"|"XboxReconcile"|"ClientCredentialsJWTPopulate"|"SCIMServerGroupRequestConverter"|"SCIMServerGroupResponseConverter"|"SCIMServerUserRequestConverter"|"SCIMServerUserResponseConverter"|"SelfServiceRegistrationValidation"|"UserInfoPopulate"|"LoginValidation"|"MFARequirement", numberOfResults?: int, orderBy?: string, startRow?: int}
export def "lambda-search searchLambdasWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: record # Search criteria for Lambdas — shape: {body?: string, name?: string, type?: "JWTPopulate"|"OpenIDReconcile"|"SAMLv2Reconcile"|"SAMLv2Populate"|"AppleReconcile"|"ExternalJWTReconcile"|"FacebookReconcile"|"GoogleReconcile"|"HYPRReconcile"|"TwitterReconcile"|"LDAPConnectorReconcile"|"LinkedInReconcile"|"EpicGamesReconcile"|"NintendoReconcile"|"SonyPSNReconcile"|"SteamReconcile"|"TwitchReconcile"|"XboxReconcile"|"ClientCredentialsJWTPopulate"|"SCIMServerGroupRequestConverter"|"SCIMServerGroupResponseConverter"|"SCIMServerUserRequestConverter"|"SCIMServerUserResponseConverter"|"SelfServiceRegistrationValidation"|"UserInfoPopulate"|"LoginValidation"|"MFARequirement", numberOfResults?: int, orderBy?: string, startRow?: int}
]: any -> record<lambdas: table<body: string, debug: bool, engineType: string, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/lambda/search")
  let body = {search: $search} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a Lambda. You can optionally specify an Id for the lambda, if not provided one will be generated.
#
# POST /api/lambda/{lambdaId}
# operationId: createLambdaWithId
# --lambda shape: {body?: string, debug?: bool, engineType?: "GraalJS"|"Nashorn", id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, type?: "JWTPopulate"|"OpenIDReconcile"|"SAMLv2Reconcile"|"SAMLv2Populate"|"AppleReconcile"|"ExternalJWTReconcile"|"FacebookReconcile"|"GoogleReconcile"|"HYPRReconcile"|"TwitterReconcile"|"LDAPConnectorReconcile"|"LinkedInReconcile"|"EpicGamesReconcile"|"NintendoReconcile"|"SonyPSNReconcile"|"SteamReconcile"|"TwitchReconcile"|"XboxReconcile"|"ClientCredentialsJWTPopulate"|"SCIMServerGroupRequestConverter"|"SCIMServerGroupResponseConverter"|"SCIMServerUserRequestConverter"|"SCIMServerUserResponseConverter"|"SelfServiceRegistrationValidation"|"UserInfoPopulate"|"LoginValidation"|"MFARequirement"}
export def "lambda createLambdaWithId" [
  lambdaId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --lambda: record # A JavaScript lambda function that is executed during certain events inside FusionAuth. — shape: {body?: string, debug?: bool, engineType?: "GraalJS"|"Nashorn", id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, type?: "JWTPopulate"|"OpenIDReconcile"|"SAMLv2Reconcile"|"SAMLv2Populate"|"AppleReconcile"|"ExternalJWTReconcile"|"FacebookReconcile"|"GoogleReconcile"|"HYPRReconcile"|"TwitterReconcile"|"LDAPConnectorReconcile"|"LinkedInReconcile"|"EpicGamesReconcile"|"NintendoReconcile"|"SonyPSNReconcile"|"SteamReconcile"|"TwitchReconcile"|"XboxReconcile"|"ClientCredentialsJWTPopulate"|"SCIMServerGroupRequestConverter"|"SCIMServerGroupResponseConverter"|"SCIMServerUserRequestConverter"|"SCIMServerUserResponseConverter"|"SelfServiceRegistrationValidation"|"UserInfoPopulate"|"LoginValidation"|"MFARequirement"}
]: any -> record<lambda: record<body: string, debug: bool, engineType: string, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>, lambdas: table<body: string, debug: bool, engineType: string, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/lambda/($lambdaId)")
  let body = {lambda: $lambda} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the lambda for the given Id.
#
# DELETE /api/lambda/{lambdaId}
# operationId: deleteLambdaWithId
export def "lambda delete" [
  lambdaId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/lambda/($lambdaId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates, via PATCH, the lambda with the given Id.
#
# PATCH /api/lambda/{lambdaId}
# operationId: patchLambdaWithId
# --lambda shape: {body?: string, debug?: bool, engineType?: "GraalJS"|"Nashorn", id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, type?: "JWTPopulate"|"OpenIDReconcile"|"SAMLv2Reconcile"|"SAMLv2Populate"|"AppleReconcile"|"ExternalJWTReconcile"|"FacebookReconcile"|"GoogleReconcile"|"HYPRReconcile"|"TwitterReconcile"|"LDAPConnectorReconcile"|"LinkedInReconcile"|"EpicGamesReconcile"|"NintendoReconcile"|"SonyPSNReconcile"|"SteamReconcile"|"TwitchReconcile"|"XboxReconcile"|"ClientCredentialsJWTPopulate"|"SCIMServerGroupRequestConverter"|"SCIMServerGroupResponseConverter"|"SCIMServerUserRequestConverter"|"SCIMServerUserResponseConverter"|"SelfServiceRegistrationValidation"|"UserInfoPopulate"|"LoginValidation"|"MFARequirement"}
export def "lambda patch" [
  lambdaId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --lambda: record # A JavaScript lambda function that is executed during certain events inside FusionAuth. — shape: {body?: string, debug?: bool, engineType?: "GraalJS"|"Nashorn", id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, type?: "JWTPopulate"|"OpenIDReconcile"|"SAMLv2Reconcile"|"SAMLv2Populate"|"AppleReconcile"|"ExternalJWTReconcile"|"FacebookReconcile"|"GoogleReconcile"|"HYPRReconcile"|"TwitterReconcile"|"LDAPConnectorReconcile"|"LinkedInReconcile"|"EpicGamesReconcile"|"NintendoReconcile"|"SonyPSNReconcile"|"SteamReconcile"|"TwitchReconcile"|"XboxReconcile"|"ClientCredentialsJWTPopulate"|"SCIMServerGroupRequestConverter"|"SCIMServerGroupResponseConverter"|"SCIMServerUserRequestConverter"|"SCIMServerUserResponseConverter"|"SelfServiceRegistrationValidation"|"UserInfoPopulate"|"LoginValidation"|"MFARequirement"}
]: any -> record<lambda: record<body: string, debug: bool, engineType: string, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>, lambdas: table<body: string, debug: bool, engineType: string, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/lambda/($lambdaId)")
  let body = {lambda: $lambda} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the lambda for the given Id.
#
# GET /api/lambda/{lambdaId}
# operationId: retrieveLambdaWithId
export def "lambda retrieveLambdaWithId" [
  lambdaId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<lambda: record<body: string, debug: bool, engineType: string, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>, lambdas: table<body: string, debug: bool, engineType: string, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/lambda/($lambdaId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the lambda with the given Id.
#
# PUT /api/lambda/{lambdaId}
# operationId: updateLambdaWithId
# --lambda shape: {body?: string, debug?: bool, engineType?: "GraalJS"|"Nashorn", id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, type?: "JWTPopulate"|"OpenIDReconcile"|"SAMLv2Reconcile"|"SAMLv2Populate"|"AppleReconcile"|"ExternalJWTReconcile"|"FacebookReconcile"|"GoogleReconcile"|"HYPRReconcile"|"TwitterReconcile"|"LDAPConnectorReconcile"|"LinkedInReconcile"|"EpicGamesReconcile"|"NintendoReconcile"|"SonyPSNReconcile"|"SteamReconcile"|"TwitchReconcile"|"XboxReconcile"|"ClientCredentialsJWTPopulate"|"SCIMServerGroupRequestConverter"|"SCIMServerGroupResponseConverter"|"SCIMServerUserRequestConverter"|"SCIMServerUserResponseConverter"|"SelfServiceRegistrationValidation"|"UserInfoPopulate"|"LoginValidation"|"MFARequirement"}
export def "lambda updateLambdaWithId" [
  lambdaId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --lambda: record # A JavaScript lambda function that is executed during certain events inside FusionAuth. — shape: {body?: string, debug?: bool, engineType?: "GraalJS"|"Nashorn", id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, type?: "JWTPopulate"|"OpenIDReconcile"|"SAMLv2Reconcile"|"SAMLv2Populate"|"AppleReconcile"|"ExternalJWTReconcile"|"FacebookReconcile"|"GoogleReconcile"|"HYPRReconcile"|"TwitterReconcile"|"LDAPConnectorReconcile"|"LinkedInReconcile"|"EpicGamesReconcile"|"NintendoReconcile"|"SonyPSNReconcile"|"SteamReconcile"|"TwitchReconcile"|"XboxReconcile"|"ClientCredentialsJWTPopulate"|"SCIMServerGroupRequestConverter"|"SCIMServerGroupResponseConverter"|"SCIMServerUserRequestConverter"|"SCIMServerUserResponseConverter"|"SelfServiceRegistrationValidation"|"UserInfoPopulate"|"LoginValidation"|"MFARequirement"}
]: any -> record<lambda: record<body: string, debug: bool, engineType: string, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>, lambdas: table<body: string, debug: bool, engineType: string, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/lambda/($lambdaId)")
  let body = {lambda: $lambda} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authenticates a user to FusionAuth.   This API optionally requires an API key. See <code>Application.loginConfiguration.requireAuthentication</code>.
#
# POST /api/login
# operationId: loginWithId
# --metaData shape: {data?: record, device?: record, resources?: list, scopes?: list}
export def "login loginWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --loginId: string
  --loginIdTypes: list
  --oneTimePassword: string
  --password: string
  --twoFactorTrustId: string
  --applicationId: string # format: uuid
  --ipAddress: string
  --metaData: record # shape: {data?: record, device?: record, resources?: list, scopes?: list}
  --newDevice: string@bool-completer
  --noJWT: string@bool-completer
]: any -> record<actions: table<actionId: string, actionerUserId: string, expiry: int, localizedName: string, localizedOption: string, localizedReason: string, name: string, option: string, reason: string, reasonCode: string>, changePasswordId: string, changePasswordReason: string, configurableMethods: list<string>, emailVerificationId: string, identityVerificationId: string, methods: table<authenticator: record, email: string, id: string, lastUsed: bool, method: string, mobilePhone: string, secret: string>, pendingIdPLinkId: string, refreshToken: string, refreshTokenId: string, registrationVerificationId: string, state: record, threatsDetected: list<any>, token: string, tokenExpirationInstant: int, trustToken: string, twoFactorId: string, twoFactorTrustId: string, user: record<preferredLanguages: list<string>, active: bool, birthDate: string, cleanSpeakId: string, data: record, email: string, expiry: int, firstName: string, fullName: string, imageUrl: string, insertInstant: int, lastName: string, legacyIdentifier: string, lastUpdateInstant: int, middleName: string, mobilePhone: string, parentEmail: string, phoneNumber: string, tenantId: string, timezone: string, twoFactor: record<methods: list, recoveryCodes: list>, memberships: list<record>, registrations: list<record>, identities: list<record>, breachedPasswordLastCheckedInstant: int, breachedPasswordStatus: string, connectorId: string, encryptionScheme: string, factor: int, id: string, lastLoginInstant: int, password: string, passwordChangeReason: string, passwordChangeRequired: bool, passwordLastUpdateInstant: int, salt: string, uniqueUsername: string, username: string, usernameStatus: string, verified: bool, verifiedInstant: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/login")
  let body = {loginId: $loginId, loginIdTypes: $loginIdTypes, oneTimePassword: $oneTimePassword, password: $password, twoFactorTrustId: $twoFactorTrustId, applicationId: $applicationId, ipAddress: $ipAddress, metaData: $metaData, newDevice: $newDevice, noJWT: $noJWT} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Sends a ping to FusionAuth indicating that the user was automatically logged into an application. When using FusionAuth's SSO or your own, you should call this if the user is already logged in centrally, but accesses an application where they no longer have a session. This helps correctly track login counts, times and helps with reporting.
#
# PUT /api/login
# operationId: loginPingWithRequestWithId
# --metaData shape: {data?: record, device?: record, resources?: list, scopes?: list}
export def "login loginPingWithRequestWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --userId: string # format: uuid
  --applicationId: string # format: uuid
  --ipAddress: string
  --metaData: record # shape: {data?: record, device?: record, resources?: list, scopes?: list}
  --newDevice: string@bool-completer
  --noJWT: string@bool-completer
]: any -> record<actions: table<actionId: string, actionerUserId: string, expiry: int, localizedName: string, localizedOption: string, localizedReason: string, name: string, option: string, reason: string, reasonCode: string>, changePasswordId: string, changePasswordReason: string, configurableMethods: list<string>, emailVerificationId: string, identityVerificationId: string, methods: table<authenticator: record, email: string, id: string, lastUsed: bool, method: string, mobilePhone: string, secret: string>, pendingIdPLinkId: string, refreshToken: string, refreshTokenId: string, registrationVerificationId: string, state: record, threatsDetected: list<any>, token: string, tokenExpirationInstant: int, trustToken: string, twoFactorId: string, twoFactorTrustId: string, user: record<preferredLanguages: list<string>, active: bool, birthDate: string, cleanSpeakId: string, data: record, email: string, expiry: int, firstName: string, fullName: string, imageUrl: string, insertInstant: int, lastName: string, legacyIdentifier: string, lastUpdateInstant: int, middleName: string, mobilePhone: string, parentEmail: string, phoneNumber: string, tenantId: string, timezone: string, twoFactor: record<methods: list, recoveryCodes: list>, memberships: list<record>, registrations: list<record>, identities: list<record>, breachedPasswordLastCheckedInstant: int, breachedPasswordStatus: string, connectorId: string, encryptionScheme: string, factor: int, id: string, lastLoginInstant: int, password: string, passwordChangeReason: string, passwordChangeRequired: bool, passwordLastUpdateInstant: int, salt: string, uniqueUsername: string, username: string, usernameStatus: string, verified: bool, verifiedInstant: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/login")
  let body = {userId: $userId, applicationId: $applicationId, ipAddress: $ipAddress, metaData: $metaData, newDevice: $newDevice, noJWT: $noJWT} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Sends a ping to FusionAuth indicating that the user was automatically logged into an application. When using FusionAuth's SSO or your own, you should call this if the user is already logged in centrally, but accesses an application where they no longer have a session. This helps correctly track login counts, times and helps with reporting.
#
# PUT /api/login/{userId}/{applicationId}
# operationId: loginPingWithId
export def "login loginPingWithId" [
  userId: string
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --callerIPAddress: string # The IP address of the end-user that is logging in. If a null value is provided the IP address will be that of the client or last proxy that sent the request.
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
]: nothing -> record<actions: table<actionId: string, actionerUserId: string, expiry: int, localizedName: string, localizedOption: string, localizedReason: string, name: string, option: string, reason: string, reasonCode: string>, changePasswordId: string, changePasswordReason: string, configurableMethods: list<string>, emailVerificationId: string, identityVerificationId: string, methods: table<authenticator: record, email: string, id: string, lastUsed: bool, method: string, mobilePhone: string, secret: string>, pendingIdPLinkId: string, refreshToken: string, refreshTokenId: string, registrationVerificationId: string, state: record, threatsDetected: list<any>, token: string, tokenExpirationInstant: int, trustToken: string, twoFactorId: string, twoFactorTrustId: string, user: record<preferredLanguages: list<string>, active: bool, birthDate: string, cleanSpeakId: string, data: record, email: string, expiry: int, firstName: string, fullName: string, imageUrl: string, insertInstant: int, lastName: string, legacyIdentifier: string, lastUpdateInstant: int, middleName: string, mobilePhone: string, parentEmail: string, phoneNumber: string, tenantId: string, timezone: string, twoFactor: record<methods: list, recoveryCodes: list>, memberships: list<record>, registrations: list<record>, identities: list<record>, breachedPasswordLastCheckedInstant: int, breachedPasswordStatus: string, connectorId: string, encryptionScheme: string, factor: int, id: string, lastLoginInstant: int, password: string, passwordChangeReason: string, passwordChangeRequired: bool, passwordLastUpdateInstant: int, salt: string, uniqueUsername: string, username: string, usernameStatus: string, verified: bool, verifiedInstant: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "callerIPAddress" $callerIPAddress "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/login/($userId)/($applicationId)" $qp)
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# The Logout API is intended to be used to remove the refresh token and access token cookies if they exist on the client and revoke the refresh token stored. This API takes the refresh token in the JSON body. OR The Logout API is intended to be used to remove the refresh token and access token cookies if they exist on the client and revoke the refresh token stored. This API does nothing if the request does not contain an access token or refresh token cookies.
#
# POST /api/logout
# operationId: createLogout
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "logout createLogout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --global: string # When this value is set to true all the refresh tokens issued to the owner of the provided token will be revoked.
  --refreshToken: string # The refresh_token as a request parameter instead of coming in via a cookie. If provided this takes precedence over the cookie.
  --global: string@bool-completer
  --refreshToken: string
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "global" $global "scalar") (serialize-qp "refreshToken" $refreshToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/logout" $qp)
  let body = {global: $global, refreshToken: $refreshToken, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates an message template. You can optionally specify an Id for the template, if not provided one will be generated.
#
# POST /api/message/template
# operationId: createMessageTemplate
# --messageTemplate shape: {data?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, type?: "SMS"|"Voice"}
export def "message-template createMessageTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --messageTemplate: record # Stores an message template used to distribute messages; — shape: {data?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, type?: "SMS"|"Voice"}
]: any -> record<messageTemplate: record<data: record, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>, messageTemplates: table<data: record, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/message/template")
  let body = {messageTemplate: $messageTemplate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the message template for the given Id. If you don't specify the Id, this will return all the message templates.
#
# GET /api/message/template
# operationId: retrieveMessageTemplate
export def "message-template retrieveMessageTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<messageTemplate: record<data: record, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>, messageTemplates: table<data: record, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/message/template")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a preview of the message template provided in the request, normalized to a given locale.
#
# POST /api/message/template/preview
# operationId: retrieveMessageTemplatePreviewWithId
# --messageTemplate shape: {data?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, type?: "SMS"|"Voice"}
export def "message-template-preview retrieveMessageTemplatePreviewWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locale: string # A Locale object represents a specific geographical, political, or cultural region. (e.g. en_US)
  --messageTemplate: record # Stores an message template used to distribute messages; — shape: {data?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, type?: "SMS"|"Voice"}
]: any -> record<errors: record<fieldErrors: list<record>, generalErrors: list<record>>, message: record<code: string, phoneNumber: string, textMessage: string, userId: string>, previewMessage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/message/template/preview")
  let body = {locale: $locale, messageTemplate: $messageTemplate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates an message template. You can optionally specify an Id for the template, if not provided one will be generated.
#
# POST /api/message/template/{messageTemplateId}
# operationId: createMessageTemplateWithId
# --messageTemplate shape: {data?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, type?: "SMS"|"Voice"}
export def "message-template createMessageTemplateWithId" [
  messageTemplateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --messageTemplate: record # Stores an message template used to distribute messages; — shape: {data?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, type?: "SMS"|"Voice"}
]: any -> record<messageTemplate: record<data: record, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>, messageTemplates: table<data: record, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/message/template/($messageTemplateId)")
  let body = {messageTemplate: $messageTemplate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the message template for the given Id.
#
# DELETE /api/message/template/{messageTemplateId}
# operationId: deleteMessageTemplateWithId
export def "message-template delete" [
  messageTemplateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/message/template/($messageTemplateId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates, via PATCH, the message template with the given Id.
#
# PATCH /api/message/template/{messageTemplateId}
# operationId: patchMessageTemplateWithId
# --messageTemplate shape: {data?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, type?: "SMS"|"Voice"}
export def "message-template patch" [
  messageTemplateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --messageTemplate: record # Stores an message template used to distribute messages; — shape: {data?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, type?: "SMS"|"Voice"}
]: any -> record<messageTemplate: record<data: record, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>, messageTemplates: table<data: record, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/message/template/($messageTemplateId)")
  let body = {messageTemplate: $messageTemplate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the message template for the given Id. If you don't specify the Id, this will return all the message templates.
#
# GET /api/message/template/{messageTemplateId}
# operationId: retrieveMessageTemplateWithId
export def "message-template retrieveMessageTemplateWithId" [
  messageTemplateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<messageTemplate: record<data: record, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>, messageTemplates: table<data: record, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/message/template/($messageTemplateId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the message template with the given Id.
#
# PUT /api/message/template/{messageTemplateId}
# operationId: updateMessageTemplateWithId
# --messageTemplate shape: {data?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, type?: "SMS"|"Voice"}
export def "message-template updateMessageTemplateWithId" [
  messageTemplateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --messageTemplate: record # Stores an message template used to distribute messages; — shape: {data?: record, id?: string, insertInstant?: int, lastUpdateInstant?: int, name?: string, type?: "SMS"|"Voice"}
]: any -> record<messageTemplate: record<data: record, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>, messageTemplates: table<data: record, id: string, insertInstant: int, lastUpdateInstant: int, name: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/message/template/($messageTemplateId)")
  let body = {messageTemplate: $messageTemplate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a messenger.  You can optionally specify an Id for the messenger, if not provided one will be generated.
#
# POST /api/messenger
# operationId: createMessenger
# --messenger shape: {data?: record, debug?: bool, id?: string, insertInstant?: int, lastUpdateInstant?: int, messageTypes?: list, name?: string, transport?: string, type?: "Generic"|"Kafka"|"Twilio"}
export def "messenger createMessenger" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --messenger: record # Do not require a setter for 'type', it is defined by the concrete class and is not mutable — shape: {data?: record, debug?: bool, id?: string, insertInstant?: int, lastUpdateInstant?: int, messageTypes?: list, name?: string, transport?: string, type?: "Generic"|"Kafka"|"Twilio"}
]: any -> record<messenger: record<data: record, debug: bool, id: string, insertInstant: int, lastUpdateInstant: int, messageTypes: list<any>, name: string, transport: string, type: string>, messengers: table<data: record, debug: bool, id: string, insertInstant: int, lastUpdateInstant: int, messageTypes: list, name: string, transport: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/messenger")
  let body = {messenger: $messenger} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a messenger.  You can optionally specify an Id for the messenger, if not provided one will be generated.
#
# POST /api/messenger/{messengerId}
# operationId: createMessengerWithId
# --messenger shape: {data?: record, debug?: bool, id?: string, insertInstant?: int, lastUpdateInstant?: int, messageTypes?: list, name?: string, transport?: string, type?: "Generic"|"Kafka"|"Twilio"}
export def "messenger createMessengerWithId" [
  messengerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --messenger: record # Do not require a setter for 'type', it is defined by the concrete class and is not mutable — shape: {data?: record, debug?: bool, id?: string, insertInstant?: int, lastUpdateInstant?: int, messageTypes?: list, name?: string, transport?: string, type?: "Generic"|"Kafka"|"Twilio"}
]: any -> record<messenger: record<data: record, debug: bool, id: string, insertInstant: int, lastUpdateInstant: int, messageTypes: list<any>, name: string, transport: string, type: string>, messengers: table<data: record, debug: bool, id: string, insertInstant: int, lastUpdateInstant: int, messageTypes: list, name: string, transport: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/messenger/($messengerId)")
  let body = {messenger: $messenger} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the messenger for the given Id.
#
# DELETE /api/messenger/{messengerId}
# operationId: deleteMessengerWithId
export def "messenger delete" [
  messengerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/messenger/($messengerId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates, via PATCH, the messenger with the given Id.
#
# PATCH /api/messenger/{messengerId}
# operationId: patchMessengerWithId
# --messenger shape: {data?: record, debug?: bool, id?: string, insertInstant?: int, lastUpdateInstant?: int, messageTypes?: list, name?: string, transport?: string, type?: "Generic"|"Kafka"|"Twilio"}
export def "messenger patch" [
  messengerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --messenger: record # Do not require a setter for 'type', it is defined by the concrete class and is not mutable — shape: {data?: record, debug?: bool, id?: string, insertInstant?: int, lastUpdateInstant?: int, messageTypes?: list, name?: string, transport?: string, type?: "Generic"|"Kafka"|"Twilio"}
]: any -> record<messenger: record<data: record, debug: bool, id: string, insertInstant: int, lastUpdateInstant: int, messageTypes: list<any>, name: string, transport: string, type: string>, messengers: table<data: record, debug: bool, id: string, insertInstant: int, lastUpdateInstant: int, messageTypes: list, name: string, transport: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/messenger/($messengerId)")
  let body = {messenger: $messenger} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the messenger with the given Id.
#
# GET /api/messenger/{messengerId}
# operationId: retrieveMessengerWithId
export def "messenger retrieveMessengerWithId" [
  messengerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<messenger: record<data: record, debug: bool, id: string, insertInstant: int, lastUpdateInstant: int, messageTypes: list<any>, name: string, transport: string, type: string>, messengers: table<data: record, debug: bool, id: string, insertInstant: int, lastUpdateInstant: int, messageTypes: list, name: string, transport: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/messenger/($messengerId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the messenger with the given Id.
#
# PUT /api/messenger/{messengerId}
# operationId: updateMessengerWithId
# --messenger shape: {data?: record, debug?: bool, id?: string, insertInstant?: int, lastUpdateInstant?: int, messageTypes?: list, name?: string, transport?: string, type?: "Generic"|"Kafka"|"Twilio"}
export def "messenger updateMessengerWithId" [
  messengerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --messenger: record # Do not require a setter for 'type', it is defined by the concrete class and is not mutable — shape: {data?: record, debug?: bool, id?: string, insertInstant?: int, lastUpdateInstant?: int, messageTypes?: list, name?: string, transport?: string, type?: "Generic"|"Kafka"|"Twilio"}
]: any -> record<messenger: record<data: record, debug: bool, id: string, insertInstant: int, lastUpdateInstant: int, messageTypes: list<any>, name: string, transport: string, type: string>, messengers: table<data: record, debug: bool, id: string, insertInstant: int, lastUpdateInstant: int, messageTypes: list, name: string, transport: string, type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/messenger/($messengerId)")
  let body = {messenger: $messenger} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Complete a login request using a passwordless code
#
# POST /api/passwordless/login
# operationId: passwordlessLoginWithId
# --metaData shape: {data?: record, device?: record, resources?: list, scopes?: list}
export def "passwordless-login passwordlessLoginWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --code: string
  --oneTimeCode: string
  --twoFactorTrustId: string
  --applicationId: string # format: uuid
  --ipAddress: string
  --metaData: record # shape: {data?: record, device?: record, resources?: list, scopes?: list}
  --newDevice: string@bool-completer
  --noJWT: string@bool-completer
]: any -> record<actions: table<actionId: string, actionerUserId: string, expiry: int, localizedName: string, localizedOption: string, localizedReason: string, name: string, option: string, reason: string, reasonCode: string>, changePasswordId: string, changePasswordReason: string, configurableMethods: list<string>, emailVerificationId: string, identityVerificationId: string, methods: table<authenticator: record, email: string, id: string, lastUsed: bool, method: string, mobilePhone: string, secret: string>, pendingIdPLinkId: string, refreshToken: string, refreshTokenId: string, registrationVerificationId: string, state: record, threatsDetected: list<any>, token: string, tokenExpirationInstant: int, trustToken: string, twoFactorId: string, twoFactorTrustId: string, user: record<preferredLanguages: list<string>, active: bool, birthDate: string, cleanSpeakId: string, data: record, email: string, expiry: int, firstName: string, fullName: string, imageUrl: string, insertInstant: int, lastName: string, legacyIdentifier: string, lastUpdateInstant: int, middleName: string, mobilePhone: string, parentEmail: string, phoneNumber: string, tenantId: string, timezone: string, twoFactor: record<methods: list, recoveryCodes: list>, memberships: list<record>, registrations: list<record>, identities: list<record>, breachedPasswordLastCheckedInstant: int, breachedPasswordStatus: string, connectorId: string, encryptionScheme: string, factor: int, id: string, lastLoginInstant: int, password: string, passwordChangeReason: string, passwordChangeRequired: bool, passwordLastUpdateInstant: int, salt: string, uniqueUsername: string, username: string, usernameStatus: string, verified: bool, verifiedInstant: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/passwordless/login")
  let body = {code: $code, oneTimeCode: $oneTimeCode, twoFactorTrustId: $twoFactorTrustId, applicationId: $applicationId, ipAddress: $ipAddress, metaData: $metaData, newDevice: $newDevice, noJWT: $noJWT} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send a passwordless authentication code in an email to complete login.
#
# POST /api/passwordless/send
# operationId: sendPasswordlessCodeWithId
export def "passwordless-send sendPasswordlessCodeWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applicationId: string # format: uuid
  --code: string
  --loginId: string
  --state: record
]: any -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/passwordless/send")
  let body = {applicationId: $applicationId, code: $code, loginId: $loginId, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Start a passwordless login request by generating a passwordless code. This code can be sent to the User using the Send Passwordless Code API or using a mechanism outside of FusionAuth. The passwordless login is completed by using the Passwordless Login API with this code.
#
# POST /api/passwordless/start
# operationId: startPasswordlessLoginWithId
export def "passwordless-start startPasswordlessLoginWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applicationId: string # format: uuid
  --loginId: string
  --loginIdTypes: list
  --loginStrategy: string@loginStrategy-completer
  --state: record
]: any -> record<code: string, oneTimeCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/passwordless/start")
  let body = {applicationId: $applicationId, loginId: $loginId, loginIdTypes: $loginIdTypes, loginStrategy: $loginStrategy, state: $state} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Activates the FusionAuth Reactor using a license Id and optionally a license text (for air-gapped deployments)
#
# POST /api/reactor
# operationId: activateReactorWithId
export def "reactor activateReactorWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --license: string
  --licenseId: string
]: any -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/reactor")
  let body = {license: $license, licenseId: $licenseId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the FusionAuth Reactor metrics.
#
# GET /api/reactor/metrics
# operationId: retrieveReactorMetricsWithId
export def "reactor-metrics retrieveReactorMetricsWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<metrics: record<breachedPasswordMetrics: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/reactor/metrics")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the daily active user report between the two instants. If you specify an application Id, it will only return the daily active counts for that application.
#
# GET /api/report/daily-active-user
# operationId: retrieveDailyActiveReportWithId
export def "report-daily-active-user retrieveDailyActiveReportWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applicationId: string # The application Id.
  --start: string # The start instant as UTC milliseconds since Epoch.
  --end: string # The end instant as UTC milliseconds since Epoch.
]: nothing -> record<dailyActiveUsers: table<count: int, interval: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "applicationId" $applicationId "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/report/daily-active-user" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the login report between the two instants for a particular user by login Id, using specific loginIdTypes. If you specify an application id, it will only return the login counts for that application. OR Retrieves the login report between the two instants for a particular user by login Id. If you specify an application Id, it will only return the login counts for that application. OR Retrieves the login report between the two instants for a particular user by Id. If you specify an application Id, it will only return the login counts for that application. OR Retrieves the login report between the two instants. If you specify an application Id, it will only return the login counts for that application.
#
# GET /api/report/login
# operationId: retrieveReportLogin
export def "report-login retrieveReportLogin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applicationId: string # The application id.
  --loginId: string # The userId id.
  --start: string # The start instant as UTC milliseconds since Epoch.
  --end: string # The end instant as UTC milliseconds since Epoch.
  --loginIdTypes: list # The identity types that FusionAuth will compare the loginId to.
  --userId: string # The userId Id.
]: nothing -> record<hourlyCounts: table<count: int, interval: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "applicationId" $applicationId "scalar") (serialize-qp "loginId" $loginId "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "loginIdTypes" $loginIdTypes "multi") (serialize-qp "userId" $userId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/report/login" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the monthly active user report between the two instants. If you specify an application Id, it will only return the monthly active counts for that application.
#
# GET /api/report/monthly-active-user
# operationId: retrieveMonthlyActiveReportWithId
export def "report-monthly-active-user retrieveMonthlyActiveReportWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applicationId: string # The application Id.
  --start: string # The start instant as UTC milliseconds since Epoch.
  --end: string # The end instant as UTC milliseconds since Epoch.
]: nothing -> record<monthlyActiveUsers: table<count: int, interval: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "applicationId" $applicationId "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/report/monthly-active-user" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the registration report between the two instants. If you specify an application Id, it will only return the registration counts for that application.
#
# GET /api/report/registration
# operationId: retrieveRegistrationReportWithId
export def "report-registration retrieveRegistrationReportWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applicationId: string # The application Id.
  --start: string # The start instant as UTC milliseconds since Epoch.
  --end: string # The end instant as UTC milliseconds since Epoch.
]: nothing -> record<hourlyCounts: table<count: int, interval: int>, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "applicationId" $applicationId "scalar") (serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/report/registration" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the totals report. This allows excluding applicationTotals from the report. An empty list will include the applicationTotals.
#
# GET /api/report/totals
# operationId: retrieveTotalReportWithExcludesWithId
export def "report-totals retrieveTotalReportWithExcludesWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --excludes: list # List of fields to exclude in the response. Currently only allows applicationTotals.
]: nothing -> record<applicationTotals: record, globalRegistrations: int, totalGlobalRegistrations: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "excludes" $excludes "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/report/totals" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the FusionAuth system status using an API key. Using an API key will cause the response to include the product version, health checks and various runtime metrics. OR Retrieves the FusionAuth system status. This request is anonymous and does not require an API key. When an API key is not provided the response will contain a single value in the JSON response indicating the current health check.
#
# GET /api/status
# operationId: retrieveStatus
export def "status retrieveStatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates, via PATCH, the system configuration.
#
# PATCH /api/system-configuration
# operationId: patchSystemConfigurationWithId
# --systemConfiguration shape: {auditLogConfiguration?: record, corsConfiguration?: record, data?: record, eventLogConfiguration?: record, insertInstant?: int, lastUpdateInstant?: int, loginRecordConfiguration?: record, reportTimezone?: string, trustedProxyConfiguration?: record, uiConfiguration?: record, usageDataConfiguration?: record, webhookEventLogConfiguration?: record}
export def "system-configuration patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --systemConfiguration: record # shape: {auditLogConfiguration?: record, corsConfiguration?: record, data?: record, eventLogConfiguration?: record, insertInstant?: int, lastUpdateInstant?: int, loginRecordConfiguration?: record, reportTimezone?: string, trustedProxyConfiguration?: record, uiConfiguration?: record, usageDataConfiguration?: record, webhookEventLogConfiguration?: record}
]: any -> record<systemConfiguration: record<auditLogConfiguration: record<delete: record>, corsConfiguration: record<allowCredentials: bool, allowedHeaders: list, allowedMethods: list, allowedOrigins: list, debug: bool, exposedHeaders: list, preflightMaxAgeInSeconds: int, enabled: bool>, data: record, eventLogConfiguration: record<numberToRetain: int>, insertInstant: int, lastUpdateInstant: int, loginRecordConfiguration: record<delete: record>, reportTimezone: string, trustedProxyConfiguration: record<trustPolicy: string, trusted: list>, uiConfiguration: record<headerColor: string, logoURL: string, menuFontColor: string>, usageDataConfiguration: record<numberOfDaysToRetain: int, enabled: bool>, webhookEventLogConfiguration: record<delete: record, enabled: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/system-configuration")
  let body = {systemConfiguration: $systemConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates the system configuration.
#
# PUT /api/system-configuration
# operationId: updateSystemConfigurationWithId
# --systemConfiguration shape: {auditLogConfiguration?: record, corsConfiguration?: record, data?: record, eventLogConfiguration?: record, insertInstant?: int, lastUpdateInstant?: int, loginRecordConfiguration?: record, reportTimezone?: string, trustedProxyConfiguration?: record, uiConfiguration?: record, usageDataConfiguration?: record, webhookEventLogConfiguration?: record}
export def "system-configuration updateSystemConfigurationWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --systemConfiguration: record # shape: {auditLogConfiguration?: record, corsConfiguration?: record, data?: record, eventLogConfiguration?: record, insertInstant?: int, lastUpdateInstant?: int, loginRecordConfiguration?: record, reportTimezone?: string, trustedProxyConfiguration?: record, uiConfiguration?: record, usageDataConfiguration?: record, webhookEventLogConfiguration?: record}
]: any -> record<systemConfiguration: record<auditLogConfiguration: record<delete: record>, corsConfiguration: record<allowCredentials: bool, allowedHeaders: list, allowedMethods: list, allowedOrigins: list, debug: bool, exposedHeaders: list, preflightMaxAgeInSeconds: int, enabled: bool>, data: record, eventLogConfiguration: record<numberToRetain: int>, insertInstant: int, lastUpdateInstant: int, loginRecordConfiguration: record<delete: record>, reportTimezone: string, trustedProxyConfiguration: record<trustPolicy: string, trusted: list>, uiConfiguration: record<headerColor: string, logoURL: string, menuFontColor: string>, usageDataConfiguration: record<numberOfDaysToRetain: int, enabled: bool>, webhookEventLogConfiguration: record<delete: record, enabled: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/system-configuration")
  let body = {systemConfiguration: $systemConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates an audit log with the message and user name (usually an email). Audit logs should be written anytime you make changes to the FusionAuth database. When using the FusionAuth App web interface, any changes are automatically written to the audit log. However, if you are accessing the API, you must write the audit logs yourself.
#
# POST /api/system/audit-log
# operationId: createAuditLogWithId
# --auditLog shape: {data?: record, id?: int, insertInstant?: int, insertUser?: string, message?: string, newValue?: record, oldValue?: record, reason?: string, tenantId?: string}
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "system-audit-log createAuditLogWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --auditLog: record # An audit log. — shape: {data?: record, id?: int, insertInstant?: int, insertUser?: string, message?: string, newValue?: record, oldValue?: record, reason?: string, tenantId?: string}
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<auditLog: record<data: record, id: int, insertInstant: int, insertUser: string, message: string, newValue: record, oldValue: record, reason: string, tenantId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/system/audit-log")
  let body = {auditLog: $auditLog, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Searches the audit logs with the specified criteria and pagination.
#
# POST /api/system/audit-log/search
# operationId: searchAuditLogsWithId
# --search shape: {end?: int, message?: string, newValue?: string, oldValue?: string, reason?: string, start?: int, tenantId?: string, user?: string, numberOfResults?: int, orderBy?: string, startRow?: int}
export def "system-audit-log-search searchAuditLogsWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: record # shape: {end?: int, message?: string, newValue?: string, oldValue?: string, reason?: string, start?: int, tenantId?: string, user?: string, numberOfResults?: int, orderBy?: string, startRow?: int}
]: any -> record<auditLogs: table<data: record, id: int, insertInstant: int, insertUser: string, message: string, newValue: record, oldValue: record, reason: string, tenantId: string>, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/system/audit-log/search")
  let body = {search: $search} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves a single audit log for the given Id.
#
# GET /api/system/audit-log/{auditLogId}
# operationId: retrieveAuditLogWithId
export def "system-audit-log retrieveAuditLogWithId" [
  auditLogId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<auditLog: record<data: record, id: int, insertInstant: int, insertUser: string, message: string, newValue: record, oldValue: record, reason: string, tenantId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/system/audit-log/($auditLogId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searches the event logs with the specified criteria and pagination.
#
# POST /api/system/event-log/search
# operationId: searchEventLogsWithId
# --search shape: {end?: int, message?: string, start?: int, type?: "Information"|"Debug"|"Error", numberOfResults?: int, orderBy?: string, startRow?: int}
export def "system-event-log-search searchEventLogsWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: record # Search criteria for the event log. — shape: {end?: int, message?: string, start?: int, type?: "Information"|"Debug"|"Error", numberOfResults?: int, orderBy?: string, startRow?: int}
]: any -> record<eventLogs: table<id: int, insertInstant: int, message: string, type: string>, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/system/event-log/search")
  let body = {search: $search} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves a single event log for the given Id.
#
# GET /api/system/event-log/{eventLogId}
# operationId: retrieveEventLogWithId
export def "system-event-log retrieveEventLogWithId" [
  eventLogId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<eventLog: record<id: int, insertInstant: int, message: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/system/event-log/($eventLogId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searches the login records with the specified criteria and pagination.
#
# POST /api/system/login-record/search
# operationId: searchLoginRecordsWithId
# --search shape: {applicationId?: string, end?: int, start?: int, userId?: string, numberOfResults?: int, orderBy?: string, startRow?: int}
export def "system-login-record-search searchLoginRecordsWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --retrieveTotal: string@bool-completer
  --search: record # shape: {applicationId?: string, end?: int, start?: int, userId?: string, numberOfResults?: int, orderBy?: string, startRow?: int}
]: any -> record<logins: table<applicationName: string, location: record, loginId: string, loginIdType: record, applicationId: string, instant: int, ipAddress: string, userId: string>, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/system/login-record/search")
  let body = {retrieveTotal: $retrieveTotal, search: $search} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Requests Elasticsearch to delete and rebuild the index for FusionAuth users or entities. Be very careful when running this request as it will  increase the CPU and I/O load on your database until the operation completes. Generally speaking you do not ever need to run this operation unless  instructed by FusionAuth support, or if you are migrating a database another system and you are not brining along the Elasticsearch index.   You have been warned.
#
# POST /api/system/reindex
# operationId: reindexWithId
export def "system-reindex reindexWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --index: string
]: any -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/system/reindex")
  let body = {index: $index} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the FusionAuth version string.
#
# GET /api/system/version
# operationId: retrieveVersionWithId
export def "system-version retrieveVersionWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/system/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves a single webhook attempt log for the given Id.
#
# GET /api/system/webhook-attempt-log/{webhookAttemptLogId}
# operationId: retrieveWebhookAttemptLogWithId
export def "system-webhook-attempt-log retrieveWebhookAttemptLogWithId" [
  webhookAttemptLogId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<webhookAttemptLog: record<data: record, endInstant: int, id: string, startInstant: int, webhookCallResponse: record<exception: string, statusCode: int, url: string>, webhookEventLogId: string, webhookId: string, attemptResult: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/system/webhook-attempt-log/($webhookAttemptLogId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searches the webhook event logs with the specified criteria and pagination.
#
# POST /api/system/webhook-event-log/search
# operationId: searchWebhookEventLogsWithId
# --search shape: {end?: int, event?: string, eventResult?: "Failed"|"Running"|"Succeeded", eventType?: "JWTPublicKeyUpdate"|"JWTRefreshTokenRevoke"|"JWTRefresh"|"AuditLogCreate"|"EventLogCreate"|"KickstartSuccess"|"GroupCreate"|"GroupCreateComplete"|"GroupDelete"|"GroupDeleteComplete"|"GroupMemberAdd"|"GroupMemberAddComplete"|"GroupMemberRemove"|"GroupMemberRemoveComplete"|"GroupMemberUpdate"|"GroupMemberUpdateComplete"|"GroupUpdate"|"GroupUpdateComplete"|"UserAction"|"UserBulkCreate"|"UserCreate"|"UserCreateComplete"|"UserDeactivate"|"UserDelete"|"UserDeleteComplete"|"UserEmailUpdate"|"UserEmailVerified"|"UserIdentityProviderLink"|"UserIdentityProviderUnlink"|"UserLoginIdDuplicateOnCreate"|"UserLoginIdDuplicateOnUpdate"|"UserLoginFailed"|"UserLoginNewDevice"|"UserLoginSuccess"|"UserLoginSuspicious"|"UserPasswordBreach"|"UserPasswordResetSend"|"UserPasswordResetStart"|"UserPasswordResetSuccess"|"UserPasswordUpdate"|"UserReactivate"|"UserRegistrationCreate"|"UserRegistrationCreateComplete"|"UserRegistrationDelete"|"UserRegistrationDeleteComplete"|"UserRegistrationUpdate"|"UserRegistrationUpdateComplete"|"UserRegistrationVerified"|"UserTwoFactorMethodAdd"|"UserTwoFactorMethodRemove"|"UserUpdate"|"UserUpdateComplete"|"Test"|"UserIdentityVerified"|"UserIdentityUpdate", start?: int, numberOfResults?: int, orderBy?: string, startRow?: int}
export def "system-webhook-event-log-search searchWebhookEventLogsWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: record # Search criteria for the webhook event log. — shape: {end?: int, event?: string, eventResult?: "Failed"|"Running"|"Succeeded", eventType?: "JWTPublicKeyUpdate"|"JWTRefreshTokenRevoke"|"JWTRefresh"|"AuditLogCreate"|"EventLogCreate"|"KickstartSuccess"|"GroupCreate"|"GroupCreateComplete"|"GroupDelete"|"GroupDeleteComplete"|"GroupMemberAdd"|"GroupMemberAddComplete"|"GroupMemberRemove"|"GroupMemberRemoveComplete"|"GroupMemberUpdate"|"GroupMemberUpdateComplete"|"GroupUpdate"|"GroupUpdateComplete"|"UserAction"|"UserBulkCreate"|"UserCreate"|"UserCreateComplete"|"UserDeactivate"|"UserDelete"|"UserDeleteComplete"|"UserEmailUpdate"|"UserEmailVerified"|"UserIdentityProviderLink"|"UserIdentityProviderUnlink"|"UserLoginIdDuplicateOnCreate"|"UserLoginIdDuplicateOnUpdate"|"UserLoginFailed"|"UserLoginNewDevice"|"UserLoginSuccess"|"UserLoginSuspicious"|"UserPasswordBreach"|"UserPasswordResetSend"|"UserPasswordResetStart"|"UserPasswordResetSuccess"|"UserPasswordUpdate"|"UserReactivate"|"UserRegistrationCreate"|"UserRegistrationCreateComplete"|"UserRegistrationDelete"|"UserRegistrationDeleteComplete"|"UserRegistrationUpdate"|"UserRegistrationUpdateComplete"|"UserRegistrationVerified"|"UserTwoFactorMethodAdd"|"UserTwoFactorMethodRemove"|"UserUpdate"|"UserUpdateComplete"|"Test"|"UserIdentityVerified"|"UserIdentityUpdate", start?: int, numberOfResults?: int, orderBy?: string, startRow?: int}
]: any -> record<total: int, webhookEventLogs: table<attempts: list, data: record, event: record, eventResult: string, eventType: string, id: string, insertInstant: int, lastAttemptInstant: int, lastUpdateInstant: int, linkedObjectId: string, sequence: int, failedAttempts: int, successfulAttempts: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/system/webhook-event-log/search")
  let body = {search: $search} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves a single webhook event log for the given Id.
#
# GET /api/system/webhook-event-log/{webhookEventLogId}
# operationId: retrieveWebhookEventLogWithId
export def "system-webhook-event-log retrieveWebhookEventLogWithId" [
  webhookEventLogId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<webhookEventLog: record<attempts: list<record>, data: record, event: record<event: record>, eventResult: string, eventType: string, id: string, insertInstant: int, lastAttemptInstant: int, lastUpdateInstant: int, linkedObjectId: string, sequence: int, failedAttempts: int, successfulAttempts: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/system/webhook-event-log/($webhookEventLogId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a tenant. You can optionally specify an Id for the tenant, if not provided one will be generated.
#
# POST /api/tenant
# operationId: createTenant
# --tenant shape: {data?: record, accessControlConfiguration?: record, captchaConfiguration?: record, configured?: bool, connectorPolicies?: list, emailConfiguration?: record, eventConfiguration?: record, externalIdentifierConfiguration?: record, failedAuthenticationConfiguration?: record, familyConfiguration?: record, formConfiguration?: record, httpSessionMaxInactiveInterval?: int, id?: string, insertInstant?: int, issuer?: string, jwtConfiguration?: record, lambdaConfiguration?: record, lastUpdateInstant?: int, loginConfiguration?: record, logoutURL?: string, maximumPasswordAge?: record, minimumPasswordAge?: record, multiFactorConfiguration?: record, name?: string, oauthConfiguration?: record, passwordEncryptionConfiguration?: record, passwordValidationRules?: record, phoneConfiguration?: record, rateLimitConfiguration?: record, registrationConfiguration?: record, scimServerConfiguration?: record, ssoConfiguration?: record, state?: "Active"|"Inactive"|"PendingDelete", themeId?: string, userDeletePolicy?: record, usernameConfiguration?: record, webAuthnConfiguration?: record}
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "tenant createTenant" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --sourceTenantId: string # format: uuid
  --tenant: record # shape: {data?: record, accessControlConfiguration?: record, captchaConfiguration?: record, configured?: bool, connectorPolicies?: list, emailConfiguration?: record, eventConfiguration?: record, externalIdentifierConfiguration?: record, failedAuthenticationConfiguration?: record, familyConfiguration?: record, formConfiguration?: record, httpSessionMaxInactiveInterval?: int, id?: string, insertInstant?: int, issuer?: string, jwtConfiguration?: record, lambdaConfiguration?: record, lastUpdateInstant?: int, loginConfiguration?: record, logoutURL?: string, maximumPasswordAge?: record, minimumPasswordAge?: record, multiFactorConfiguration?: record, name?: string, oauthConfiguration?: record, passwordEncryptionConfiguration?: record, passwordValidationRules?: record, phoneConfiguration?: record, rateLimitConfiguration?: record, registrationConfiguration?: record, scimServerConfiguration?: record, ssoConfiguration?: record, state?: "Active"|"Inactive"|"PendingDelete", themeId?: string, userDeletePolicy?: record, usernameConfiguration?: record, webAuthnConfiguration?: record}
  --webhookIds: list
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<tenant: record<data: record, accessControlConfiguration: record<uiIPAccessControlListId: string>, captchaConfiguration: record<captchaMethod: string, secretKey: string, siteKey: string, threshold: float, enabled: bool>, configured: bool, connectorPolicies: list<record>, emailConfiguration: record<additionalHeaders: list, debug: bool, defaultFromEmail: string, defaultFromName: string, emailUpdateEmailTemplateId: string, emailVerifiedEmailTemplateId: string, forgotPasswordEmailTemplateId: string, host: string, implicitEmailVerificationAllowed: bool, loginIdInUseOnCreateEmailTemplateId: string, loginIdInUseOnUpdateEmailTemplateId: string, loginNewDeviceEmailTemplateId: string, loginSuspiciousEmailTemplateId: string, password: string, passwordResetSuccessEmailTemplateId: string, passwordUpdateEmailTemplateId: string, passwordlessEmailTemplateId: string, port: int, properties: string, security: string, setPasswordEmailTemplateId: string, twoFactorMethodAddEmailTemplateId: string, twoFactorMethodRemoveEmailTemplateId: string, unverified: record, username: string, verificationEmailTemplateId: string, verificationStrategy: string, verifyEmail: bool, verifyEmailWhenChanged: bool>, eventConfiguration: record<events: record>, externalIdentifierConfiguration: record<authorizationGrantIdTimeToLiveInSeconds: int, changePasswordIdGenerator: record, changePasswordIdTimeToLiveInSeconds: int, deviceCodeTimeToLiveInSeconds: int, deviceUserCodeIdGenerator: record, emailVerificationIdGenerator: record, emailVerificationIdTimeToLiveInSeconds: int, emailVerificationOneTimeCodeGenerator: record, externalAuthenticationIdTimeToLiveInSeconds: int, identityProviderConnectionTestTimeToLiveInSeconds: int, loginIntentTimeToLiveInSeconds: int, oneTimePasswordTimeToLiveInSeconds: int, passwordlessLoginGenerator: record, passwordlessLoginOneTimeCodeGenerator: record, passwordlessLoginTimeToLiveInSeconds: int, pendingAccountLinkTimeToLiveInSeconds: int, phoneVerificationIdGenerator: record, phoneVerificationIdTimeToLiveInSeconds: int, phoneVerificationOneTimeCodeGenerator: record, registrationVerificationIdGenerator: record, registrationVerificationIdTimeToLiveInSeconds: int, registrationVerificationOneTimeCodeGenerator: record, rememberOAuthScopeConsentChoiceTimeToLiveInSeconds: int, samlv2AuthNRequestIdTimeToLiveInSeconds: int, setupPasswordIdGenerator: record, setupPasswordIdTimeToLiveInSeconds: int, trustTokenTimeToLiveInSeconds: int, twoFactorIdTimeToLiveInSeconds: int, twoFactorOneTimeCodeIdGenerator: record, twoFactorOneTimeCodeIdTimeToLiveInSeconds: int, twoFactorTrustIdTimeToLiveInSeconds: int, webAuthnAuthenticationChallengeTimeToLiveInSeconds: int, webAuthnRegistrationChallengeTimeToLiveInSeconds: int>, failedAuthenticationConfiguration: record<actionCancelPolicy: record, actionDuration: int, actionDurationUnit: string, emailUser: bool, resetCountInSeconds: int, tooManyAttempts: int, userActionId: string>, familyConfiguration: record<allowChildRegistrations: bool, confirmChildEmailTemplateId: string, deleteOrphanedAccounts: bool, deleteOrphanedAccountsDays: int, familyRequestEmailTemplateId: string, maximumChildAge: int, minimumOwnerAge: int, parentEmailRequired: bool, parentRegistrationEmailTemplateId: string, enabled: bool>, formConfiguration: record<adminUserFormId: string>, httpSessionMaxInactiveInterval: int, id: string, insertInstant: int, issuer: string, jwtConfiguration: record<accessTokenKeyId: string, idTokenKeyId: string, refreshTokenExpirationPolicy: string, refreshTokenOneTimeUseConfiguration: record, refreshTokenRevocationPolicy: record, refreshTokenSlidingWindowConfiguration: record, refreshTokenTimeToLiveInMinutes: int, refreshTokenUsagePolicy: string, timeToLiveInSeconds: int, enabled: bool>, lambdaConfiguration: record<loginValidationId: string, multiFactorRequirementId: string, scimEnterpriseUserRequestConverterId: string, scimEnterpriseUserResponseConverterId: string, scimGroupRequestConverterId: string, scimGroupResponseConverterId: string, scimUserRequestConverterId: string, scimUserResponseConverterId: string>, lastUpdateInstant: int, loginConfiguration: record<requireAuthentication: bool>, logoutURL: string, maximumPasswordAge: record<days: int, enabled: bool>, minimumPasswordAge: record<seconds: int, enabled: bool>, multiFactorConfiguration: record<authenticator: record, email: record, loginPolicy: string, sms: record, voice: record>, name: string, oauthConfiguration: record<clientCredentialsAccessTokenPopulateLambdaId: string>, passwordEncryptionConfiguration: record<encryptionScheme: string, encryptionSchemeFactor: int, modifyEncryptionSchemeOnLogin: bool>, passwordValidationRules: record<breachDetection: record, disallowUserLoginId: bool, maxLength: int, minLength: int, rememberPreviousPasswords: record, requireMixedCase: bool, requireNonAlpha: bool, requireNumber: bool, validateOnLogin: bool>, phoneConfiguration: record<forgotPasswordTemplateId: string, identityUpdateTemplateId: string, implicitPhoneVerificationAllowed: bool, loginIdInUseOnCreateTemplateId: string, loginIdInUseOnUpdateTemplateId: string, loginNewDeviceTemplateId: string, loginSuspiciousTemplateId: string, messengerId: string, passwordResetSuccessTemplateId: string, passwordUpdateTemplateId: string, passwordlessTemplateId: string, setPasswordTemplateId: string, twoFactorMethodAddTemplateId: string, twoFactorMethodRemoveTemplateId: string, unverified: record, verificationCompleteTemplateId: string, verificationStrategy: string, verificationTemplateId: string, verifyPhoneNumber: bool>, rateLimitConfiguration: record<failedLogin: record, forgotPassword: record, sendEmailVerification: record, sendPasswordless: record, sendPasswordlessPhone: record, sendPhoneVerification: record, sendRegistrationVerification: record, sendTwoFactor: record>, registrationConfiguration: record<blockedDomains: list>, scimServerConfiguration: record<clientEntityTypeId: string, schemas: record, serverEntityTypeId: string, enabled: bool>, ssoConfiguration: record<allowAccessTokenBootstrap: bool, deviceTrustTimeToLiveInSeconds: int>, state: string, themeId: string, userDeletePolicy: record<unverified: record>, usernameConfiguration: record<unique: record>, webAuthnConfiguration: record<bootstrapWorkflow: record, debug: bool, reauthenticationWorkflow: record, relyingPartyId: string, relyingPartyName: string, enabled: bool>>, tenants: table<data: record, accessControlConfiguration: record, captchaConfiguration: record, configured: bool, connectorPolicies: list, emailConfiguration: record, eventConfiguration: record, externalIdentifierConfiguration: record, failedAuthenticationConfiguration: record, familyConfiguration: record, formConfiguration: record, httpSessionMaxInactiveInterval: int, id: string, insertInstant: int, issuer: string, jwtConfiguration: record, lambdaConfiguration: record, lastUpdateInstant: int, loginConfiguration: record, logoutURL: string, maximumPasswordAge: record, minimumPasswordAge: record, multiFactorConfiguration: record, name: string, oauthConfiguration: record, passwordEncryptionConfiguration: record, passwordValidationRules: record, phoneConfiguration: record, rateLimitConfiguration: record, registrationConfiguration: record, scimServerConfiguration: record, ssoConfiguration: record, state: string, themeId: string, userDeletePolicy: record, usernameConfiguration: record, webAuthnConfiguration: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/tenant")
  let body = {sourceTenantId: $sourceTenantId, tenant: $tenant, webhookIds: $webhookIds, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates, via PATCH, the Tenant Manager configuration.
#
# PATCH /api/tenant-manager
# operationId: patchTenantManagerConfigurationWithId
# --tenantManagerConfiguration shape: {applicationConfigurations?: list, attributeFormId?: string, brandName?: string, identityProviderTypeConfigurations?: record, insertInstant?: int, lastUpdateInstant?: int}
export def "tenant-manager patch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tenantManagerConfiguration: record # Configuration object for the Tenant Manager. — shape: {applicationConfigurations?: list, attributeFormId?: string, brandName?: string, identityProviderTypeConfigurations?: record, insertInstant?: int, lastUpdateInstant?: int}
]: any -> record<tenantManagerConfiguration: record<applicationConfigurations: list<record>, attributeFormId: string, brandName: string, identityProviderTypeConfigurations: record, insertInstant: int, lastUpdateInstant: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/tenant-manager")
  let body = {tenantManagerConfiguration: $tenantManagerConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates the Tenant Manager configuration.
#
# PUT /api/tenant-manager
# operationId: updateTenantManagerConfigurationWithId
# --tenantManagerConfiguration shape: {applicationConfigurations?: list, attributeFormId?: string, brandName?: string, identityProviderTypeConfigurations?: record, insertInstant?: int, lastUpdateInstant?: int}
export def "tenant-manager updateTenantManagerConfigurationWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tenantManagerConfiguration: record # Configuration object for the Tenant Manager. — shape: {applicationConfigurations?: list, attributeFormId?: string, brandName?: string, identityProviderTypeConfigurations?: record, insertInstant?: int, lastUpdateInstant?: int}
]: any -> record<tenantManagerConfiguration: record<applicationConfigurations: list<record>, attributeFormId: string, brandName: string, identityProviderTypeConfigurations: record, insertInstant: int, lastUpdateInstant: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/tenant-manager")
  let body = {tenantManagerConfiguration: $tenantManagerConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a tenant manager identity provider type configuration for the given identity provider type.
#
# POST /api/tenant-manager/identity-provider/{type}
# operationId: createTenantManagerIdentityProviderTypeConfigurationWithId
# --typeConfiguration shape: {defaultAttributeMappings?: record, insertInstant?: int, lastUpdateInstant?: int, linkingStrategy?: "CreatePendingLink"|"Disabled"|"LinkAnonymously"|"LinkByEmail"|"LinkByEmailForExistingUser"|"LinkByUsername"|"LinkByUsernameForExistingUser"|"Unsupported", type?: "Apple"|"EpicGames"|"ExternalJWT"|"Facebook"|"Google"|"HYPR"|"LinkedIn"|"Nintendo"|"OpenIDConnect"|"SAMLv2"|"SAMLv2IdPInitiated"|"SonyPSN"|"Steam"|"Twitch"|"Twitter"|"Xbox", enabled?: bool}
export def "tenant-manager-identity-provider createTenantManagerIdentityProviderTypeConfigurationWithId" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --typeConfiguration: record # Configuration object for identity provider types allowed in Tenant Manager — shape: {defaultAttributeMappings?: record, insertInstant?: int, lastUpdateInstant?: int, linkingStrategy?: "CreatePendingLink"|"Disabled"|"LinkAnonymously"|"LinkByEmail"|"LinkByEmailForExistingUser"|"LinkByUsername"|"LinkByUsernameForExistingUser"|"Unsupported", type?: "Apple"|"EpicGames"|"ExternalJWT"|"Facebook"|"Google"|"HYPR"|"LinkedIn"|"Nintendo"|"OpenIDConnect"|"SAMLv2"|"SAMLv2IdPInitiated"|"SonyPSN"|"Steam"|"Twitch"|"Twitter"|"Xbox", enabled?: bool}
]: any -> record<typeConfiguration: record<defaultAttributeMappings: record, insertInstant: int, lastUpdateInstant: int, linkingStrategy: string, type: string, enabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/tenant-manager/identity-provider/($type)")
  let body = {typeConfiguration: $typeConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the tenant manager identity provider type configuration for the given identity provider type.
#
# DELETE /api/tenant-manager/identity-provider/{type}
# operationId: deleteTenantManagerIdentityProviderTypeConfigurationWithId
export def "tenant-manager-identity-provider delete" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/tenant-manager/identity-provider/($type)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patches the tenant manager identity provider type configuration for the given identity provider type.
#
# PATCH /api/tenant-manager/identity-provider/{type}
# operationId: patchTenantManagerIdentityProviderTypeConfigurationWithId
# --typeConfiguration shape: {defaultAttributeMappings?: record, insertInstant?: int, lastUpdateInstant?: int, linkingStrategy?: "CreatePendingLink"|"Disabled"|"LinkAnonymously"|"LinkByEmail"|"LinkByEmailForExistingUser"|"LinkByUsername"|"LinkByUsernameForExistingUser"|"Unsupported", type?: "Apple"|"EpicGames"|"ExternalJWT"|"Facebook"|"Google"|"HYPR"|"LinkedIn"|"Nintendo"|"OpenIDConnect"|"SAMLv2"|"SAMLv2IdPInitiated"|"SonyPSN"|"Steam"|"Twitch"|"Twitter"|"Xbox", enabled?: bool}
export def "tenant-manager-identity-provider patch" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --typeConfiguration: record # Configuration object for identity provider types allowed in Tenant Manager — shape: {defaultAttributeMappings?: record, insertInstant?: int, lastUpdateInstant?: int, linkingStrategy?: "CreatePendingLink"|"Disabled"|"LinkAnonymously"|"LinkByEmail"|"LinkByEmailForExistingUser"|"LinkByUsername"|"LinkByUsernameForExistingUser"|"Unsupported", type?: "Apple"|"EpicGames"|"ExternalJWT"|"Facebook"|"Google"|"HYPR"|"LinkedIn"|"Nintendo"|"OpenIDConnect"|"SAMLv2"|"SAMLv2IdPInitiated"|"SonyPSN"|"Steam"|"Twitch"|"Twitter"|"Xbox", enabled?: bool}
]: any -> record<typeConfiguration: record<defaultAttributeMappings: record, insertInstant: int, lastUpdateInstant: int, linkingStrategy: string, type: string, enabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/tenant-manager/identity-provider/($type)")
  let body = {typeConfiguration: $typeConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates the tenant manager identity provider type configuration for the given identity provider type.
#
# PUT /api/tenant-manager/identity-provider/{type}
# operationId: updateTenantManagerIdentityProviderTypeConfigurationWithId
# --typeConfiguration shape: {defaultAttributeMappings?: record, insertInstant?: int, lastUpdateInstant?: int, linkingStrategy?: "CreatePendingLink"|"Disabled"|"LinkAnonymously"|"LinkByEmail"|"LinkByEmailForExistingUser"|"LinkByUsername"|"LinkByUsernameForExistingUser"|"Unsupported", type?: "Apple"|"EpicGames"|"ExternalJWT"|"Facebook"|"Google"|"HYPR"|"LinkedIn"|"Nintendo"|"OpenIDConnect"|"SAMLv2"|"SAMLv2IdPInitiated"|"SonyPSN"|"Steam"|"Twitch"|"Twitter"|"Xbox", enabled?: bool}
export def "tenant-manager-identity-provider updateTenantManagerIdentityProviderTypeConfigurationWithId" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --typeConfiguration: record # Configuration object for identity provider types allowed in Tenant Manager — shape: {defaultAttributeMappings?: record, insertInstant?: int, lastUpdateInstant?: int, linkingStrategy?: "CreatePendingLink"|"Disabled"|"LinkAnonymously"|"LinkByEmail"|"LinkByEmailForExistingUser"|"LinkByUsername"|"LinkByUsernameForExistingUser"|"Unsupported", type?: "Apple"|"EpicGames"|"ExternalJWT"|"Facebook"|"Google"|"HYPR"|"LinkedIn"|"Nintendo"|"OpenIDConnect"|"SAMLv2"|"SAMLv2IdPInitiated"|"SonyPSN"|"Steam"|"Twitch"|"Twitter"|"Xbox", enabled?: bool}
]: any -> record<typeConfiguration: record<defaultAttributeMappings: record, insertInstant: int, lastUpdateInstant: int, linkingStrategy: string, type: string, enabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/tenant-manager/identity-provider/($type)")
  let body = {typeConfiguration: $typeConfiguration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the password validation rules for a specific tenant. This method requires a tenantId to be provided  through the use of a Tenant scoped API key or an HTTP header X-FusionAuth-TenantId to specify the Tenant Id.  This API does not require an API key.
#
# GET /api/tenant/password-validation-rules
# operationId: retrievePasswordValidationRulesWithId
export def "tenant-password-validation-rules retrievePasswordValidationRulesWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<passwordValidationRules: record<breachDetection: record<matchMode: string, notifyUserEmailTemplateId: string, onLogin: string, enabled: bool>, disallowUserLoginId: bool, maxLength: int, minLength: int, rememberPreviousPasswords: record<count: int, enabled: bool>, requireMixedCase: bool, requireNonAlpha: bool, requireNumber: bool, validateOnLogin: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/tenant/password-validation-rules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the password validation rules for a specific tenant.  This API does not require an API key.
#
# GET /api/tenant/password-validation-rules/{tenantId}
# operationId: retrievePasswordValidationRulesWithTenantIdWithId
export def "tenant-password-validation-rules retrievePasswordValidationRulesWithTenantIdWithId" [
  tenantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<passwordValidationRules: record<breachDetection: record<matchMode: string, notifyUserEmailTemplateId: string, onLogin: string, enabled: bool>, disallowUserLoginId: bool, maxLength: int, minLength: int, rememberPreviousPasswords: record<count: int, enabled: bool>, requireMixedCase: bool, requireNonAlpha: bool, requireNumber: bool, validateOnLogin: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/tenant/password-validation-rules/($tenantId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searches tenants with the specified criteria and pagination.
#
# POST /api/tenant/search
# operationId: searchTenantsWithId
# --search shape: {name?: string, numberOfResults?: int, orderBy?: string, startRow?: int}
export def "tenant-search searchTenantsWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: record # Search criteria for Tenants — shape: {name?: string, numberOfResults?: int, orderBy?: string, startRow?: int}
]: any -> record<tenants: table<data: record, accessControlConfiguration: record, captchaConfiguration: record, configured: bool, connectorPolicies: list, emailConfiguration: record, eventConfiguration: record, externalIdentifierConfiguration: record, failedAuthenticationConfiguration: record, familyConfiguration: record, formConfiguration: record, httpSessionMaxInactiveInterval: int, id: string, insertInstant: int, issuer: string, jwtConfiguration: record, lambdaConfiguration: record, lastUpdateInstant: int, loginConfiguration: record, logoutURL: string, maximumPasswordAge: record, minimumPasswordAge: record, multiFactorConfiguration: record, name: string, oauthConfiguration: record, passwordEncryptionConfiguration: record, passwordValidationRules: record, phoneConfiguration: record, rateLimitConfiguration: record, registrationConfiguration: record, scimServerConfiguration: record, ssoConfiguration: record, state: string, themeId: string, userDeletePolicy: record, usernameConfiguration: record, webAuthnConfiguration: record>, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/tenant/search")
  let body = {search: $search} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a tenant. You can optionally specify an Id for the tenant, if not provided one will be generated.
#
# POST /api/tenant/{tenantId}
# operationId: createTenantWithId
# --tenant shape: {data?: record, accessControlConfiguration?: record, captchaConfiguration?: record, configured?: bool, connectorPolicies?: list, emailConfiguration?: record, eventConfiguration?: record, externalIdentifierConfiguration?: record, failedAuthenticationConfiguration?: record, familyConfiguration?: record, formConfiguration?: record, httpSessionMaxInactiveInterval?: int, id?: string, insertInstant?: int, issuer?: string, jwtConfiguration?: record, lambdaConfiguration?: record, lastUpdateInstant?: int, loginConfiguration?: record, logoutURL?: string, maximumPasswordAge?: record, minimumPasswordAge?: record, multiFactorConfiguration?: record, name?: string, oauthConfiguration?: record, passwordEncryptionConfiguration?: record, passwordValidationRules?: record, phoneConfiguration?: record, rateLimitConfiguration?: record, registrationConfiguration?: record, scimServerConfiguration?: record, ssoConfiguration?: record, state?: "Active"|"Inactive"|"PendingDelete", themeId?: string, userDeletePolicy?: record, usernameConfiguration?: record, webAuthnConfiguration?: record}
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "tenant createTenantWithId" [
  tenantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --sourceTenantId: string # format: uuid
  --tenant: record # shape: {data?: record, accessControlConfiguration?: record, captchaConfiguration?: record, configured?: bool, connectorPolicies?: list, emailConfiguration?: record, eventConfiguration?: record, externalIdentifierConfiguration?: record, failedAuthenticationConfiguration?: record, familyConfiguration?: record, formConfiguration?: record, httpSessionMaxInactiveInterval?: int, id?: string, insertInstant?: int, issuer?: string, jwtConfiguration?: record, lambdaConfiguration?: record, lastUpdateInstant?: int, loginConfiguration?: record, logoutURL?: string, maximumPasswordAge?: record, minimumPasswordAge?: record, multiFactorConfiguration?: record, name?: string, oauthConfiguration?: record, passwordEncryptionConfiguration?: record, passwordValidationRules?: record, phoneConfiguration?: record, rateLimitConfiguration?: record, registrationConfiguration?: record, scimServerConfiguration?: record, ssoConfiguration?: record, state?: "Active"|"Inactive"|"PendingDelete", themeId?: string, userDeletePolicy?: record, usernameConfiguration?: record, webAuthnConfiguration?: record}
  --webhookIds: list
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<tenant: record<data: record, accessControlConfiguration: record<uiIPAccessControlListId: string>, captchaConfiguration: record<captchaMethod: string, secretKey: string, siteKey: string, threshold: float, enabled: bool>, configured: bool, connectorPolicies: list<record>, emailConfiguration: record<additionalHeaders: list, debug: bool, defaultFromEmail: string, defaultFromName: string, emailUpdateEmailTemplateId: string, emailVerifiedEmailTemplateId: string, forgotPasswordEmailTemplateId: string, host: string, implicitEmailVerificationAllowed: bool, loginIdInUseOnCreateEmailTemplateId: string, loginIdInUseOnUpdateEmailTemplateId: string, loginNewDeviceEmailTemplateId: string, loginSuspiciousEmailTemplateId: string, password: string, passwordResetSuccessEmailTemplateId: string, passwordUpdateEmailTemplateId: string, passwordlessEmailTemplateId: string, port: int, properties: string, security: string, setPasswordEmailTemplateId: string, twoFactorMethodAddEmailTemplateId: string, twoFactorMethodRemoveEmailTemplateId: string, unverified: record, username: string, verificationEmailTemplateId: string, verificationStrategy: string, verifyEmail: bool, verifyEmailWhenChanged: bool>, eventConfiguration: record<events: record>, externalIdentifierConfiguration: record<authorizationGrantIdTimeToLiveInSeconds: int, changePasswordIdGenerator: record, changePasswordIdTimeToLiveInSeconds: int, deviceCodeTimeToLiveInSeconds: int, deviceUserCodeIdGenerator: record, emailVerificationIdGenerator: record, emailVerificationIdTimeToLiveInSeconds: int, emailVerificationOneTimeCodeGenerator: record, externalAuthenticationIdTimeToLiveInSeconds: int, identityProviderConnectionTestTimeToLiveInSeconds: int, loginIntentTimeToLiveInSeconds: int, oneTimePasswordTimeToLiveInSeconds: int, passwordlessLoginGenerator: record, passwordlessLoginOneTimeCodeGenerator: record, passwordlessLoginTimeToLiveInSeconds: int, pendingAccountLinkTimeToLiveInSeconds: int, phoneVerificationIdGenerator: record, phoneVerificationIdTimeToLiveInSeconds: int, phoneVerificationOneTimeCodeGenerator: record, registrationVerificationIdGenerator: record, registrationVerificationIdTimeToLiveInSeconds: int, registrationVerificationOneTimeCodeGenerator: record, rememberOAuthScopeConsentChoiceTimeToLiveInSeconds: int, samlv2AuthNRequestIdTimeToLiveInSeconds: int, setupPasswordIdGenerator: record, setupPasswordIdTimeToLiveInSeconds: int, trustTokenTimeToLiveInSeconds: int, twoFactorIdTimeToLiveInSeconds: int, twoFactorOneTimeCodeIdGenerator: record, twoFactorOneTimeCodeIdTimeToLiveInSeconds: int, twoFactorTrustIdTimeToLiveInSeconds: int, webAuthnAuthenticationChallengeTimeToLiveInSeconds: int, webAuthnRegistrationChallengeTimeToLiveInSeconds: int>, failedAuthenticationConfiguration: record<actionCancelPolicy: record, actionDuration: int, actionDurationUnit: string, emailUser: bool, resetCountInSeconds: int, tooManyAttempts: int, userActionId: string>, familyConfiguration: record<allowChildRegistrations: bool, confirmChildEmailTemplateId: string, deleteOrphanedAccounts: bool, deleteOrphanedAccountsDays: int, familyRequestEmailTemplateId: string, maximumChildAge: int, minimumOwnerAge: int, parentEmailRequired: bool, parentRegistrationEmailTemplateId: string, enabled: bool>, formConfiguration: record<adminUserFormId: string>, httpSessionMaxInactiveInterval: int, id: string, insertInstant: int, issuer: string, jwtConfiguration: record<accessTokenKeyId: string, idTokenKeyId: string, refreshTokenExpirationPolicy: string, refreshTokenOneTimeUseConfiguration: record, refreshTokenRevocationPolicy: record, refreshTokenSlidingWindowConfiguration: record, refreshTokenTimeToLiveInMinutes: int, refreshTokenUsagePolicy: string, timeToLiveInSeconds: int, enabled: bool>, lambdaConfiguration: record<loginValidationId: string, multiFactorRequirementId: string, scimEnterpriseUserRequestConverterId: string, scimEnterpriseUserResponseConverterId: string, scimGroupRequestConverterId: string, scimGroupResponseConverterId: string, scimUserRequestConverterId: string, scimUserResponseConverterId: string>, lastUpdateInstant: int, loginConfiguration: record<requireAuthentication: bool>, logoutURL: string, maximumPasswordAge: record<days: int, enabled: bool>, minimumPasswordAge: record<seconds: int, enabled: bool>, multiFactorConfiguration: record<authenticator: record, email: record, loginPolicy: string, sms: record, voice: record>, name: string, oauthConfiguration: record<clientCredentialsAccessTokenPopulateLambdaId: string>, passwordEncryptionConfiguration: record<encryptionScheme: string, encryptionSchemeFactor: int, modifyEncryptionSchemeOnLogin: bool>, passwordValidationRules: record<breachDetection: record, disallowUserLoginId: bool, maxLength: int, minLength: int, rememberPreviousPasswords: record, requireMixedCase: bool, requireNonAlpha: bool, requireNumber: bool, validateOnLogin: bool>, phoneConfiguration: record<forgotPasswordTemplateId: string, identityUpdateTemplateId: string, implicitPhoneVerificationAllowed: bool, loginIdInUseOnCreateTemplateId: string, loginIdInUseOnUpdateTemplateId: string, loginNewDeviceTemplateId: string, loginSuspiciousTemplateId: string, messengerId: string, passwordResetSuccessTemplateId: string, passwordUpdateTemplateId: string, passwordlessTemplateId: string, setPasswordTemplateId: string, twoFactorMethodAddTemplateId: string, twoFactorMethodRemoveTemplateId: string, unverified: record, verificationCompleteTemplateId: string, verificationStrategy: string, verificationTemplateId: string, verifyPhoneNumber: bool>, rateLimitConfiguration: record<failedLogin: record, forgotPassword: record, sendEmailVerification: record, sendPasswordless: record, sendPasswordlessPhone: record, sendPhoneVerification: record, sendRegistrationVerification: record, sendTwoFactor: record>, registrationConfiguration: record<blockedDomains: list>, scimServerConfiguration: record<clientEntityTypeId: string, schemas: record, serverEntityTypeId: string, enabled: bool>, ssoConfiguration: record<allowAccessTokenBootstrap: bool, deviceTrustTimeToLiveInSeconds: int>, state: string, themeId: string, userDeletePolicy: record<unverified: record>, usernameConfiguration: record<unique: record>, webAuthnConfiguration: record<bootstrapWorkflow: record, debug: bool, reauthenticationWorkflow: record, relyingPartyId: string, relyingPartyName: string, enabled: bool>>, tenants: table<data: record, accessControlConfiguration: record, captchaConfiguration: record, configured: bool, connectorPolicies: list, emailConfiguration: record, eventConfiguration: record, externalIdentifierConfiguration: record, failedAuthenticationConfiguration: record, familyConfiguration: record, formConfiguration: record, httpSessionMaxInactiveInterval: int, id: string, insertInstant: int, issuer: string, jwtConfiguration: record, lambdaConfiguration: record, lastUpdateInstant: int, loginConfiguration: record, logoutURL: string, maximumPasswordAge: record, minimumPasswordAge: record, multiFactorConfiguration: record, name: string, oauthConfiguration: record, passwordEncryptionConfiguration: record, passwordValidationRules: record, phoneConfiguration: record, rateLimitConfiguration: record, registrationConfiguration: record, scimServerConfiguration: record, ssoConfiguration: record, state: string, themeId: string, userDeletePolicy: record, usernameConfiguration: record, webAuthnConfiguration: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/tenant/($tenantId)")
  let body = {sourceTenantId: $sourceTenantId, tenant: $tenant, webhookIds: $webhookIds, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the tenant based on the given request (sent to the API as JSON). This permanently deletes all information, metrics, reports and data associated with the tenant and everything under the tenant (applications, users, etc). OR Deletes the tenant for the given Id asynchronously. This method is helpful if you do not want to wait for the delete operation to complete. OR Deletes the tenant based on the given Id on the URL. This permanently deletes all information, metrics, reports and data associated with the tenant and everything under the tenant (applications, users, etc).
#
# DELETE /api/tenant/{tenantId}
# operationId: deleteTenantWithId
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "tenant delete" [
  tenantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --async: string
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --async: string@bool-completer
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "async" $async "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/tenant/($tenantId)" $qp)
  let body = {async: $async, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates, via PATCH, the tenant with the given Id.
#
# PATCH /api/tenant/{tenantId}
# operationId: patchTenantWithId
# --tenant shape: {data?: record, accessControlConfiguration?: record, captchaConfiguration?: record, configured?: bool, connectorPolicies?: list, emailConfiguration?: record, eventConfiguration?: record, externalIdentifierConfiguration?: record, failedAuthenticationConfiguration?: record, familyConfiguration?: record, formConfiguration?: record, httpSessionMaxInactiveInterval?: int, id?: string, insertInstant?: int, issuer?: string, jwtConfiguration?: record, lambdaConfiguration?: record, lastUpdateInstant?: int, loginConfiguration?: record, logoutURL?: string, maximumPasswordAge?: record, minimumPasswordAge?: record, multiFactorConfiguration?: record, name?: string, oauthConfiguration?: record, passwordEncryptionConfiguration?: record, passwordValidationRules?: record, phoneConfiguration?: record, rateLimitConfiguration?: record, registrationConfiguration?: record, scimServerConfiguration?: record, ssoConfiguration?: record, state?: "Active"|"Inactive"|"PendingDelete", themeId?: string, userDeletePolicy?: record, usernameConfiguration?: record, webAuthnConfiguration?: record}
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "tenant patch" [
  tenantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --sourceTenantId: string # format: uuid
  --tenant: record # shape: {data?: record, accessControlConfiguration?: record, captchaConfiguration?: record, configured?: bool, connectorPolicies?: list, emailConfiguration?: record, eventConfiguration?: record, externalIdentifierConfiguration?: record, failedAuthenticationConfiguration?: record, familyConfiguration?: record, formConfiguration?: record, httpSessionMaxInactiveInterval?: int, id?: string, insertInstant?: int, issuer?: string, jwtConfiguration?: record, lambdaConfiguration?: record, lastUpdateInstant?: int, loginConfiguration?: record, logoutURL?: string, maximumPasswordAge?: record, minimumPasswordAge?: record, multiFactorConfiguration?: record, name?: string, oauthConfiguration?: record, passwordEncryptionConfiguration?: record, passwordValidationRules?: record, phoneConfiguration?: record, rateLimitConfiguration?: record, registrationConfiguration?: record, scimServerConfiguration?: record, ssoConfiguration?: record, state?: "Active"|"Inactive"|"PendingDelete", themeId?: string, userDeletePolicy?: record, usernameConfiguration?: record, webAuthnConfiguration?: record}
  --webhookIds: list
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<tenant: record<data: record, accessControlConfiguration: record<uiIPAccessControlListId: string>, captchaConfiguration: record<captchaMethod: string, secretKey: string, siteKey: string, threshold: float, enabled: bool>, configured: bool, connectorPolicies: list<record>, emailConfiguration: record<additionalHeaders: list, debug: bool, defaultFromEmail: string, defaultFromName: string, emailUpdateEmailTemplateId: string, emailVerifiedEmailTemplateId: string, forgotPasswordEmailTemplateId: string, host: string, implicitEmailVerificationAllowed: bool, loginIdInUseOnCreateEmailTemplateId: string, loginIdInUseOnUpdateEmailTemplateId: string, loginNewDeviceEmailTemplateId: string, loginSuspiciousEmailTemplateId: string, password: string, passwordResetSuccessEmailTemplateId: string, passwordUpdateEmailTemplateId: string, passwordlessEmailTemplateId: string, port: int, properties: string, security: string, setPasswordEmailTemplateId: string, twoFactorMethodAddEmailTemplateId: string, twoFactorMethodRemoveEmailTemplateId: string, unverified: record, username: string, verificationEmailTemplateId: string, verificationStrategy: string, verifyEmail: bool, verifyEmailWhenChanged: bool>, eventConfiguration: record<events: record>, externalIdentifierConfiguration: record<authorizationGrantIdTimeToLiveInSeconds: int, changePasswordIdGenerator: record, changePasswordIdTimeToLiveInSeconds: int, deviceCodeTimeToLiveInSeconds: int, deviceUserCodeIdGenerator: record, emailVerificationIdGenerator: record, emailVerificationIdTimeToLiveInSeconds: int, emailVerificationOneTimeCodeGenerator: record, externalAuthenticationIdTimeToLiveInSeconds: int, identityProviderConnectionTestTimeToLiveInSeconds: int, loginIntentTimeToLiveInSeconds: int, oneTimePasswordTimeToLiveInSeconds: int, passwordlessLoginGenerator: record, passwordlessLoginOneTimeCodeGenerator: record, passwordlessLoginTimeToLiveInSeconds: int, pendingAccountLinkTimeToLiveInSeconds: int, phoneVerificationIdGenerator: record, phoneVerificationIdTimeToLiveInSeconds: int, phoneVerificationOneTimeCodeGenerator: record, registrationVerificationIdGenerator: record, registrationVerificationIdTimeToLiveInSeconds: int, registrationVerificationOneTimeCodeGenerator: record, rememberOAuthScopeConsentChoiceTimeToLiveInSeconds: int, samlv2AuthNRequestIdTimeToLiveInSeconds: int, setupPasswordIdGenerator: record, setupPasswordIdTimeToLiveInSeconds: int, trustTokenTimeToLiveInSeconds: int, twoFactorIdTimeToLiveInSeconds: int, twoFactorOneTimeCodeIdGenerator: record, twoFactorOneTimeCodeIdTimeToLiveInSeconds: int, twoFactorTrustIdTimeToLiveInSeconds: int, webAuthnAuthenticationChallengeTimeToLiveInSeconds: int, webAuthnRegistrationChallengeTimeToLiveInSeconds: int>, failedAuthenticationConfiguration: record<actionCancelPolicy: record, actionDuration: int, actionDurationUnit: string, emailUser: bool, resetCountInSeconds: int, tooManyAttempts: int, userActionId: string>, familyConfiguration: record<allowChildRegistrations: bool, confirmChildEmailTemplateId: string, deleteOrphanedAccounts: bool, deleteOrphanedAccountsDays: int, familyRequestEmailTemplateId: string, maximumChildAge: int, minimumOwnerAge: int, parentEmailRequired: bool, parentRegistrationEmailTemplateId: string, enabled: bool>, formConfiguration: record<adminUserFormId: string>, httpSessionMaxInactiveInterval: int, id: string, insertInstant: int, issuer: string, jwtConfiguration: record<accessTokenKeyId: string, idTokenKeyId: string, refreshTokenExpirationPolicy: string, refreshTokenOneTimeUseConfiguration: record, refreshTokenRevocationPolicy: record, refreshTokenSlidingWindowConfiguration: record, refreshTokenTimeToLiveInMinutes: int, refreshTokenUsagePolicy: string, timeToLiveInSeconds: int, enabled: bool>, lambdaConfiguration: record<loginValidationId: string, multiFactorRequirementId: string, scimEnterpriseUserRequestConverterId: string, scimEnterpriseUserResponseConverterId: string, scimGroupRequestConverterId: string, scimGroupResponseConverterId: string, scimUserRequestConverterId: string, scimUserResponseConverterId: string>, lastUpdateInstant: int, loginConfiguration: record<requireAuthentication: bool>, logoutURL: string, maximumPasswordAge: record<days: int, enabled: bool>, minimumPasswordAge: record<seconds: int, enabled: bool>, multiFactorConfiguration: record<authenticator: record, email: record, loginPolicy: string, sms: record, voice: record>, name: string, oauthConfiguration: record<clientCredentialsAccessTokenPopulateLambdaId: string>, passwordEncryptionConfiguration: record<encryptionScheme: string, encryptionSchemeFactor: int, modifyEncryptionSchemeOnLogin: bool>, passwordValidationRules: record<breachDetection: record, disallowUserLoginId: bool, maxLength: int, minLength: int, rememberPreviousPasswords: record, requireMixedCase: bool, requireNonAlpha: bool, requireNumber: bool, validateOnLogin: bool>, phoneConfiguration: record<forgotPasswordTemplateId: string, identityUpdateTemplateId: string, implicitPhoneVerificationAllowed: bool, loginIdInUseOnCreateTemplateId: string, loginIdInUseOnUpdateTemplateId: string, loginNewDeviceTemplateId: string, loginSuspiciousTemplateId: string, messengerId: string, passwordResetSuccessTemplateId: string, passwordUpdateTemplateId: string, passwordlessTemplateId: string, setPasswordTemplateId: string, twoFactorMethodAddTemplateId: string, twoFactorMethodRemoveTemplateId: string, unverified: record, verificationCompleteTemplateId: string, verificationStrategy: string, verificationTemplateId: string, verifyPhoneNumber: bool>, rateLimitConfiguration: record<failedLogin: record, forgotPassword: record, sendEmailVerification: record, sendPasswordless: record, sendPasswordlessPhone: record, sendPhoneVerification: record, sendRegistrationVerification: record, sendTwoFactor: record>, registrationConfiguration: record<blockedDomains: list>, scimServerConfiguration: record<clientEntityTypeId: string, schemas: record, serverEntityTypeId: string, enabled: bool>, ssoConfiguration: record<allowAccessTokenBootstrap: bool, deviceTrustTimeToLiveInSeconds: int>, state: string, themeId: string, userDeletePolicy: record<unverified: record>, usernameConfiguration: record<unique: record>, webAuthnConfiguration: record<bootstrapWorkflow: record, debug: bool, reauthenticationWorkflow: record, relyingPartyId: string, relyingPartyName: string, enabled: bool>>, tenants: table<data: record, accessControlConfiguration: record, captchaConfiguration: record, configured: bool, connectorPolicies: list, emailConfiguration: record, eventConfiguration: record, externalIdentifierConfiguration: record, failedAuthenticationConfiguration: record, familyConfiguration: record, formConfiguration: record, httpSessionMaxInactiveInterval: int, id: string, insertInstant: int, issuer: string, jwtConfiguration: record, lambdaConfiguration: record, lastUpdateInstant: int, loginConfiguration: record, logoutURL: string, maximumPasswordAge: record, minimumPasswordAge: record, multiFactorConfiguration: record, name: string, oauthConfiguration: record, passwordEncryptionConfiguration: record, passwordValidationRules: record, phoneConfiguration: record, rateLimitConfiguration: record, registrationConfiguration: record, scimServerConfiguration: record, ssoConfiguration: record, state: string, themeId: string, userDeletePolicy: record, usernameConfiguration: record, webAuthnConfiguration: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/tenant/($tenantId)")
  let body = {sourceTenantId: $sourceTenantId, tenant: $tenant, webhookIds: $webhookIds, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the tenant for the given Id.
#
# GET /api/tenant/{tenantId}
# operationId: retrieveTenantWithId
export def "tenant retrieveTenantWithId" [
  tenantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
]: nothing -> record<tenant: record<data: record, accessControlConfiguration: record<uiIPAccessControlListId: string>, captchaConfiguration: record<captchaMethod: string, secretKey: string, siteKey: string, threshold: float, enabled: bool>, configured: bool, connectorPolicies: list<record>, emailConfiguration: record<additionalHeaders: list, debug: bool, defaultFromEmail: string, defaultFromName: string, emailUpdateEmailTemplateId: string, emailVerifiedEmailTemplateId: string, forgotPasswordEmailTemplateId: string, host: string, implicitEmailVerificationAllowed: bool, loginIdInUseOnCreateEmailTemplateId: string, loginIdInUseOnUpdateEmailTemplateId: string, loginNewDeviceEmailTemplateId: string, loginSuspiciousEmailTemplateId: string, password: string, passwordResetSuccessEmailTemplateId: string, passwordUpdateEmailTemplateId: string, passwordlessEmailTemplateId: string, port: int, properties: string, security: string, setPasswordEmailTemplateId: string, twoFactorMethodAddEmailTemplateId: string, twoFactorMethodRemoveEmailTemplateId: string, unverified: record, username: string, verificationEmailTemplateId: string, verificationStrategy: string, verifyEmail: bool, verifyEmailWhenChanged: bool>, eventConfiguration: record<events: record>, externalIdentifierConfiguration: record<authorizationGrantIdTimeToLiveInSeconds: int, changePasswordIdGenerator: record, changePasswordIdTimeToLiveInSeconds: int, deviceCodeTimeToLiveInSeconds: int, deviceUserCodeIdGenerator: record, emailVerificationIdGenerator: record, emailVerificationIdTimeToLiveInSeconds: int, emailVerificationOneTimeCodeGenerator: record, externalAuthenticationIdTimeToLiveInSeconds: int, identityProviderConnectionTestTimeToLiveInSeconds: int, loginIntentTimeToLiveInSeconds: int, oneTimePasswordTimeToLiveInSeconds: int, passwordlessLoginGenerator: record, passwordlessLoginOneTimeCodeGenerator: record, passwordlessLoginTimeToLiveInSeconds: int, pendingAccountLinkTimeToLiveInSeconds: int, phoneVerificationIdGenerator: record, phoneVerificationIdTimeToLiveInSeconds: int, phoneVerificationOneTimeCodeGenerator: record, registrationVerificationIdGenerator: record, registrationVerificationIdTimeToLiveInSeconds: int, registrationVerificationOneTimeCodeGenerator: record, rememberOAuthScopeConsentChoiceTimeToLiveInSeconds: int, samlv2AuthNRequestIdTimeToLiveInSeconds: int, setupPasswordIdGenerator: record, setupPasswordIdTimeToLiveInSeconds: int, trustTokenTimeToLiveInSeconds: int, twoFactorIdTimeToLiveInSeconds: int, twoFactorOneTimeCodeIdGenerator: record, twoFactorOneTimeCodeIdTimeToLiveInSeconds: int, twoFactorTrustIdTimeToLiveInSeconds: int, webAuthnAuthenticationChallengeTimeToLiveInSeconds: int, webAuthnRegistrationChallengeTimeToLiveInSeconds: int>, failedAuthenticationConfiguration: record<actionCancelPolicy: record, actionDuration: int, actionDurationUnit: string, emailUser: bool, resetCountInSeconds: int, tooManyAttempts: int, userActionId: string>, familyConfiguration: record<allowChildRegistrations: bool, confirmChildEmailTemplateId: string, deleteOrphanedAccounts: bool, deleteOrphanedAccountsDays: int, familyRequestEmailTemplateId: string, maximumChildAge: int, minimumOwnerAge: int, parentEmailRequired: bool, parentRegistrationEmailTemplateId: string, enabled: bool>, formConfiguration: record<adminUserFormId: string>, httpSessionMaxInactiveInterval: int, id: string, insertInstant: int, issuer: string, jwtConfiguration: record<accessTokenKeyId: string, idTokenKeyId: string, refreshTokenExpirationPolicy: string, refreshTokenOneTimeUseConfiguration: record, refreshTokenRevocationPolicy: record, refreshTokenSlidingWindowConfiguration: record, refreshTokenTimeToLiveInMinutes: int, refreshTokenUsagePolicy: string, timeToLiveInSeconds: int, enabled: bool>, lambdaConfiguration: record<loginValidationId: string, multiFactorRequirementId: string, scimEnterpriseUserRequestConverterId: string, scimEnterpriseUserResponseConverterId: string, scimGroupRequestConverterId: string, scimGroupResponseConverterId: string, scimUserRequestConverterId: string, scimUserResponseConverterId: string>, lastUpdateInstant: int, loginConfiguration: record<requireAuthentication: bool>, logoutURL: string, maximumPasswordAge: record<days: int, enabled: bool>, minimumPasswordAge: record<seconds: int, enabled: bool>, multiFactorConfiguration: record<authenticator: record, email: record, loginPolicy: string, sms: record, voice: record>, name: string, oauthConfiguration: record<clientCredentialsAccessTokenPopulateLambdaId: string>, passwordEncryptionConfiguration: record<encryptionScheme: string, encryptionSchemeFactor: int, modifyEncryptionSchemeOnLogin: bool>, passwordValidationRules: record<breachDetection: record, disallowUserLoginId: bool, maxLength: int, minLength: int, rememberPreviousPasswords: record, requireMixedCase: bool, requireNonAlpha: bool, requireNumber: bool, validateOnLogin: bool>, phoneConfiguration: record<forgotPasswordTemplateId: string, identityUpdateTemplateId: string, implicitPhoneVerificationAllowed: bool, loginIdInUseOnCreateTemplateId: string, loginIdInUseOnUpdateTemplateId: string, loginNewDeviceTemplateId: string, loginSuspiciousTemplateId: string, messengerId: string, passwordResetSuccessTemplateId: string, passwordUpdateTemplateId: string, passwordlessTemplateId: string, setPasswordTemplateId: string, twoFactorMethodAddTemplateId: string, twoFactorMethodRemoveTemplateId: string, unverified: record, verificationCompleteTemplateId: string, verificationStrategy: string, verificationTemplateId: string, verifyPhoneNumber: bool>, rateLimitConfiguration: record<failedLogin: record, forgotPassword: record, sendEmailVerification: record, sendPasswordless: record, sendPasswordlessPhone: record, sendPhoneVerification: record, sendRegistrationVerification: record, sendTwoFactor: record>, registrationConfiguration: record<blockedDomains: list>, scimServerConfiguration: record<clientEntityTypeId: string, schemas: record, serverEntityTypeId: string, enabled: bool>, ssoConfiguration: record<allowAccessTokenBootstrap: bool, deviceTrustTimeToLiveInSeconds: int>, state: string, themeId: string, userDeletePolicy: record<unverified: record>, usernameConfiguration: record<unique: record>, webAuthnConfiguration: record<bootstrapWorkflow: record, debug: bool, reauthenticationWorkflow: record, relyingPartyId: string, relyingPartyName: string, enabled: bool>>, tenants: table<data: record, accessControlConfiguration: record, captchaConfiguration: record, configured: bool, connectorPolicies: list, emailConfiguration: record, eventConfiguration: record, externalIdentifierConfiguration: record, failedAuthenticationConfiguration: record, familyConfiguration: record, formConfiguration: record, httpSessionMaxInactiveInterval: int, id: string, insertInstant: int, issuer: string, jwtConfiguration: record, lambdaConfiguration: record, lastUpdateInstant: int, loginConfiguration: record, logoutURL: string, maximumPasswordAge: record, minimumPasswordAge: record, multiFactorConfiguration: record, name: string, oauthConfiguration: record, passwordEncryptionConfiguration: record, passwordValidationRules: record, phoneConfiguration: record, rateLimitConfiguration: record, registrationConfiguration: record, scimServerConfiguration: record, ssoConfiguration: record, state: string, themeId: string, userDeletePolicy: record, usernameConfiguration: record, webAuthnConfiguration: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/tenant/($tenantId)")
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the tenant with the given Id.
#
# PUT /api/tenant/{tenantId}
# operationId: updateTenantWithId
# --tenant shape: {data?: record, accessControlConfiguration?: record, captchaConfiguration?: record, configured?: bool, connectorPolicies?: list, emailConfiguration?: record, eventConfiguration?: record, externalIdentifierConfiguration?: record, failedAuthenticationConfiguration?: record, familyConfiguration?: record, formConfiguration?: record, httpSessionMaxInactiveInterval?: int, id?: string, insertInstant?: int, issuer?: string, jwtConfiguration?: record, lambdaConfiguration?: record, lastUpdateInstant?: int, loginConfiguration?: record, logoutURL?: string, maximumPasswordAge?: record, minimumPasswordAge?: record, multiFactorConfiguration?: record, name?: string, oauthConfiguration?: record, passwordEncryptionConfiguration?: record, passwordValidationRules?: record, phoneConfiguration?: record, rateLimitConfiguration?: record, registrationConfiguration?: record, scimServerConfiguration?: record, ssoConfiguration?: record, state?: "Active"|"Inactive"|"PendingDelete", themeId?: string, userDeletePolicy?: record, usernameConfiguration?: record, webAuthnConfiguration?: record}
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "tenant updateTenantWithId" [
  tenantId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --sourceTenantId: string # format: uuid
  --tenant: record # shape: {data?: record, accessControlConfiguration?: record, captchaConfiguration?: record, configured?: bool, connectorPolicies?: list, emailConfiguration?: record, eventConfiguration?: record, externalIdentifierConfiguration?: record, failedAuthenticationConfiguration?: record, familyConfiguration?: record, formConfiguration?: record, httpSessionMaxInactiveInterval?: int, id?: string, insertInstant?: int, issuer?: string, jwtConfiguration?: record, lambdaConfiguration?: record, lastUpdateInstant?: int, loginConfiguration?: record, logoutURL?: string, maximumPasswordAge?: record, minimumPasswordAge?: record, multiFactorConfiguration?: record, name?: string, oauthConfiguration?: record, passwordEncryptionConfiguration?: record, passwordValidationRules?: record, phoneConfiguration?: record, rateLimitConfiguration?: record, registrationConfiguration?: record, scimServerConfiguration?: record, ssoConfiguration?: record, state?: "Active"|"Inactive"|"PendingDelete", themeId?: string, userDeletePolicy?: record, usernameConfiguration?: record, webAuthnConfiguration?: record}
  --webhookIds: list
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<tenant: record<data: record, accessControlConfiguration: record<uiIPAccessControlListId: string>, captchaConfiguration: record<captchaMethod: string, secretKey: string, siteKey: string, threshold: float, enabled: bool>, configured: bool, connectorPolicies: list<record>, emailConfiguration: record<additionalHeaders: list, debug: bool, defaultFromEmail: string, defaultFromName: string, emailUpdateEmailTemplateId: string, emailVerifiedEmailTemplateId: string, forgotPasswordEmailTemplateId: string, host: string, implicitEmailVerificationAllowed: bool, loginIdInUseOnCreateEmailTemplateId: string, loginIdInUseOnUpdateEmailTemplateId: string, loginNewDeviceEmailTemplateId: string, loginSuspiciousEmailTemplateId: string, password: string, passwordResetSuccessEmailTemplateId: string, passwordUpdateEmailTemplateId: string, passwordlessEmailTemplateId: string, port: int, properties: string, security: string, setPasswordEmailTemplateId: string, twoFactorMethodAddEmailTemplateId: string, twoFactorMethodRemoveEmailTemplateId: string, unverified: record, username: string, verificationEmailTemplateId: string, verificationStrategy: string, verifyEmail: bool, verifyEmailWhenChanged: bool>, eventConfiguration: record<events: record>, externalIdentifierConfiguration: record<authorizationGrantIdTimeToLiveInSeconds: int, changePasswordIdGenerator: record, changePasswordIdTimeToLiveInSeconds: int, deviceCodeTimeToLiveInSeconds: int, deviceUserCodeIdGenerator: record, emailVerificationIdGenerator: record, emailVerificationIdTimeToLiveInSeconds: int, emailVerificationOneTimeCodeGenerator: record, externalAuthenticationIdTimeToLiveInSeconds: int, identityProviderConnectionTestTimeToLiveInSeconds: int, loginIntentTimeToLiveInSeconds: int, oneTimePasswordTimeToLiveInSeconds: int, passwordlessLoginGenerator: record, passwordlessLoginOneTimeCodeGenerator: record, passwordlessLoginTimeToLiveInSeconds: int, pendingAccountLinkTimeToLiveInSeconds: int, phoneVerificationIdGenerator: record, phoneVerificationIdTimeToLiveInSeconds: int, phoneVerificationOneTimeCodeGenerator: record, registrationVerificationIdGenerator: record, registrationVerificationIdTimeToLiveInSeconds: int, registrationVerificationOneTimeCodeGenerator: record, rememberOAuthScopeConsentChoiceTimeToLiveInSeconds: int, samlv2AuthNRequestIdTimeToLiveInSeconds: int, setupPasswordIdGenerator: record, setupPasswordIdTimeToLiveInSeconds: int, trustTokenTimeToLiveInSeconds: int, twoFactorIdTimeToLiveInSeconds: int, twoFactorOneTimeCodeIdGenerator: record, twoFactorOneTimeCodeIdTimeToLiveInSeconds: int, twoFactorTrustIdTimeToLiveInSeconds: int, webAuthnAuthenticationChallengeTimeToLiveInSeconds: int, webAuthnRegistrationChallengeTimeToLiveInSeconds: int>, failedAuthenticationConfiguration: record<actionCancelPolicy: record, actionDuration: int, actionDurationUnit: string, emailUser: bool, resetCountInSeconds: int, tooManyAttempts: int, userActionId: string>, familyConfiguration: record<allowChildRegistrations: bool, confirmChildEmailTemplateId: string, deleteOrphanedAccounts: bool, deleteOrphanedAccountsDays: int, familyRequestEmailTemplateId: string, maximumChildAge: int, minimumOwnerAge: int, parentEmailRequired: bool, parentRegistrationEmailTemplateId: string, enabled: bool>, formConfiguration: record<adminUserFormId: string>, httpSessionMaxInactiveInterval: int, id: string, insertInstant: int, issuer: string, jwtConfiguration: record<accessTokenKeyId: string, idTokenKeyId: string, refreshTokenExpirationPolicy: string, refreshTokenOneTimeUseConfiguration: record, refreshTokenRevocationPolicy: record, refreshTokenSlidingWindowConfiguration: record, refreshTokenTimeToLiveInMinutes: int, refreshTokenUsagePolicy: string, timeToLiveInSeconds: int, enabled: bool>, lambdaConfiguration: record<loginValidationId: string, multiFactorRequirementId: string, scimEnterpriseUserRequestConverterId: string, scimEnterpriseUserResponseConverterId: string, scimGroupRequestConverterId: string, scimGroupResponseConverterId: string, scimUserRequestConverterId: string, scimUserResponseConverterId: string>, lastUpdateInstant: int, loginConfiguration: record<requireAuthentication: bool>, logoutURL: string, maximumPasswordAge: record<days: int, enabled: bool>, minimumPasswordAge: record<seconds: int, enabled: bool>, multiFactorConfiguration: record<authenticator: record, email: record, loginPolicy: string, sms: record, voice: record>, name: string, oauthConfiguration: record<clientCredentialsAccessTokenPopulateLambdaId: string>, passwordEncryptionConfiguration: record<encryptionScheme: string, encryptionSchemeFactor: int, modifyEncryptionSchemeOnLogin: bool>, passwordValidationRules: record<breachDetection: record, disallowUserLoginId: bool, maxLength: int, minLength: int, rememberPreviousPasswords: record, requireMixedCase: bool, requireNonAlpha: bool, requireNumber: bool, validateOnLogin: bool>, phoneConfiguration: record<forgotPasswordTemplateId: string, identityUpdateTemplateId: string, implicitPhoneVerificationAllowed: bool, loginIdInUseOnCreateTemplateId: string, loginIdInUseOnUpdateTemplateId: string, loginNewDeviceTemplateId: string, loginSuspiciousTemplateId: string, messengerId: string, passwordResetSuccessTemplateId: string, passwordUpdateTemplateId: string, passwordlessTemplateId: string, setPasswordTemplateId: string, twoFactorMethodAddTemplateId: string, twoFactorMethodRemoveTemplateId: string, unverified: record, verificationCompleteTemplateId: string, verificationStrategy: string, verificationTemplateId: string, verifyPhoneNumber: bool>, rateLimitConfiguration: record<failedLogin: record, forgotPassword: record, sendEmailVerification: record, sendPasswordless: record, sendPasswordlessPhone: record, sendPhoneVerification: record, sendRegistrationVerification: record, sendTwoFactor: record>, registrationConfiguration: record<blockedDomains: list>, scimServerConfiguration: record<clientEntityTypeId: string, schemas: record, serverEntityTypeId: string, enabled: bool>, ssoConfiguration: record<allowAccessTokenBootstrap: bool, deviceTrustTimeToLiveInSeconds: int>, state: string, themeId: string, userDeletePolicy: record<unverified: record>, usernameConfiguration: record<unique: record>, webAuthnConfiguration: record<bootstrapWorkflow: record, debug: bool, reauthenticationWorkflow: record, relyingPartyId: string, relyingPartyName: string, enabled: bool>>, tenants: table<data: record, accessControlConfiguration: record, captchaConfiguration: record, configured: bool, connectorPolicies: list, emailConfiguration: record, eventConfiguration: record, externalIdentifierConfiguration: record, failedAuthenticationConfiguration: record, familyConfiguration: record, formConfiguration: record, httpSessionMaxInactiveInterval: int, id: string, insertInstant: int, issuer: string, jwtConfiguration: record, lambdaConfiguration: record, lastUpdateInstant: int, loginConfiguration: record, logoutURL: string, maximumPasswordAge: record, minimumPasswordAge: record, multiFactorConfiguration: record, name: string, oauthConfiguration: record, passwordEncryptionConfiguration: record, passwordValidationRules: record, phoneConfiguration: record, rateLimitConfiguration: record, registrationConfiguration: record, scimServerConfiguration: record, ssoConfiguration: record, state: string, themeId: string, userDeletePolicy: record, usernameConfiguration: record, webAuthnConfiguration: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/tenant/($tenantId)")
  let body = {sourceTenantId: $sourceTenantId, tenant: $tenant, webhookIds: $webhookIds, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a Theme. You can optionally specify an Id for the theme, if not provided one will be generated.
#
# POST /api/theme
# operationId: createTheme
# --theme shape: {data?: record, defaultMessages?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, localizedMessages?: record, name?: string, stylesheet?: string, templates?: record, type?: "advanced"|"simple", variables?: record}
export def "theme createTheme" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sourceThemeId: string # format: uuid
  --theme: record # shape: {data?: record, defaultMessages?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, localizedMessages?: record, name?: string, stylesheet?: string, templates?: record, type?: "advanced"|"simple", variables?: record}
]: any -> record<theme: record<data: record, defaultMessages: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedMessages: record, name: string, stylesheet: string, templates: record<accountEdit: string, accountIndex: string, accountTwoFactorDisable: string, accountTwoFactorEnable: string, accountTwoFactorIndex: string, accountWebAuthnAdd: string, accountWebAuthnDelete: string, accountWebAuthnIndex: string, confirmationRequired: string, emailComplete: string, emailSent: string, emailVerificationRequired: string, emailVerify: string, helpers: string, index: string, oauth2Authorize: string, oauth2AuthorizedNotRegistered: string, oauth2ChildRegistrationNotAllowed: string, oauth2ChildRegistrationNotAllowedComplete: string, oauth2CompleteRegistration: string, oauth2Consent: string, oauth2Device: string, oauth2DeviceComplete: string, oauth2Error: string, oauth2Logout: string, oauth2Passwordless: string, oauth2Register: string, oauth2StartIdPLink: string, oauth2TwoFactor: string, oauth2TwoFactorEnable: string, oauth2TwoFactorEnableComplete: string, oauth2TwoFactorMethods: string, oauth2Wait: string, oauth2WebAuthn: string, oauth2WebAuthnReauth: string, oauth2WebAuthnReauthEnable: string, passwordChange: string, passwordComplete: string, passwordForgot: string, passwordSent: string, phoneComplete: string, phoneSent: string, phoneVerificationRequired: string, phoneVerify: string, registrationComplete: string, registrationSent: string, registrationVerificationRequired: string, registrationVerify: string, samlv2Logout: string, unauthorized: string, emailSend: string, registrationSend: string>, type: string, variables: record<alertBackgroundColor: string, alertFontColor: string, backgroundImageURL: string, backgroundSize: string, borderRadius: string, deleteButtonColor: string, deleteButtonFocusColor: string, deleteButtonTextColor: string, deleteButtonTextFocusColor: string, errorFontColor: string, errorIconColor: string, favicons: list, fontColor: string, fontFamily: string, footerDisplay: bool, iconBackgroundColor: string, iconColor: string, infoIconColor: string, inputBackgroundColor: string, inputIconColor: string, inputTextColor: string, linkTextColor: string, linkTextFocusColor: string, logoImageSize: string, logoImageURL: string, monoFontColor: string, monoFontFamily: string, pageBackgroundColor: string, panelBackgroundColor: string, primaryButtonColor: string, primaryButtonFocusColor: string, primaryButtonTextColor: string, primaryButtonTextFocusColor: string>>, themes: table<data: record, defaultMessages: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedMessages: record, name: string, stylesheet: string, templates: record, type: string, variables: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/theme")
  let body = {sourceThemeId: $sourceThemeId, theme: $theme} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Searches themes with the specified criteria and pagination.
#
# POST /api/theme/search
# operationId: searchThemesWithId
# --search shape: {name?: string, type?: "advanced"|"simple", numberOfResults?: int, orderBy?: string, startRow?: int}
export def "theme-search searchThemesWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: record # Search criteria for themes — shape: {name?: string, type?: "advanced"|"simple", numberOfResults?: int, orderBy?: string, startRow?: int}
]: any -> record<themes: table<data: record, defaultMessages: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedMessages: record, name: string, stylesheet: string, templates: record, type: string, variables: record>, total: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/theme/search")
  let body = {search: $search} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a Theme. You can optionally specify an Id for the theme, if not provided one will be generated.
#
# POST /api/theme/{themeId}
# operationId: createThemeWithId
# --theme shape: {data?: record, defaultMessages?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, localizedMessages?: record, name?: string, stylesheet?: string, templates?: record, type?: "advanced"|"simple", variables?: record}
export def "theme createThemeWithId" [
  themeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sourceThemeId: string # format: uuid
  --theme: record # shape: {data?: record, defaultMessages?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, localizedMessages?: record, name?: string, stylesheet?: string, templates?: record, type?: "advanced"|"simple", variables?: record}
]: any -> record<theme: record<data: record, defaultMessages: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedMessages: record, name: string, stylesheet: string, templates: record<accountEdit: string, accountIndex: string, accountTwoFactorDisable: string, accountTwoFactorEnable: string, accountTwoFactorIndex: string, accountWebAuthnAdd: string, accountWebAuthnDelete: string, accountWebAuthnIndex: string, confirmationRequired: string, emailComplete: string, emailSent: string, emailVerificationRequired: string, emailVerify: string, helpers: string, index: string, oauth2Authorize: string, oauth2AuthorizedNotRegistered: string, oauth2ChildRegistrationNotAllowed: string, oauth2ChildRegistrationNotAllowedComplete: string, oauth2CompleteRegistration: string, oauth2Consent: string, oauth2Device: string, oauth2DeviceComplete: string, oauth2Error: string, oauth2Logout: string, oauth2Passwordless: string, oauth2Register: string, oauth2StartIdPLink: string, oauth2TwoFactor: string, oauth2TwoFactorEnable: string, oauth2TwoFactorEnableComplete: string, oauth2TwoFactorMethods: string, oauth2Wait: string, oauth2WebAuthn: string, oauth2WebAuthnReauth: string, oauth2WebAuthnReauthEnable: string, passwordChange: string, passwordComplete: string, passwordForgot: string, passwordSent: string, phoneComplete: string, phoneSent: string, phoneVerificationRequired: string, phoneVerify: string, registrationComplete: string, registrationSent: string, registrationVerificationRequired: string, registrationVerify: string, samlv2Logout: string, unauthorized: string, emailSend: string, registrationSend: string>, type: string, variables: record<alertBackgroundColor: string, alertFontColor: string, backgroundImageURL: string, backgroundSize: string, borderRadius: string, deleteButtonColor: string, deleteButtonFocusColor: string, deleteButtonTextColor: string, deleteButtonTextFocusColor: string, errorFontColor: string, errorIconColor: string, favicons: list, fontColor: string, fontFamily: string, footerDisplay: bool, iconBackgroundColor: string, iconColor: string, infoIconColor: string, inputBackgroundColor: string, inputIconColor: string, inputTextColor: string, linkTextColor: string, linkTextFocusColor: string, logoImageSize: string, logoImageURL: string, monoFontColor: string, monoFontFamily: string, pageBackgroundColor: string, panelBackgroundColor: string, primaryButtonColor: string, primaryButtonFocusColor: string, primaryButtonTextColor: string, primaryButtonTextFocusColor: string>>, themes: table<data: record, defaultMessages: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedMessages: record, name: string, stylesheet: string, templates: record, type: string, variables: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/theme/($themeId)")
  let body = {sourceThemeId: $sourceThemeId, theme: $theme} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the theme for the given Id.
#
# DELETE /api/theme/{themeId}
# operationId: deleteThemeWithId
export def "theme delete" [
  themeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/theme/($themeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates, via PATCH, the theme with the given Id.
#
# PATCH /api/theme/{themeId}
# operationId: patchThemeWithId
# --theme shape: {data?: record, defaultMessages?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, localizedMessages?: record, name?: string, stylesheet?: string, templates?: record, type?: "advanced"|"simple", variables?: record}
export def "theme patch" [
  themeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sourceThemeId: string # format: uuid
  --theme: record # shape: {data?: record, defaultMessages?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, localizedMessages?: record, name?: string, stylesheet?: string, templates?: record, type?: "advanced"|"simple", variables?: record}
]: any -> record<theme: record<data: record, defaultMessages: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedMessages: record, name: string, stylesheet: string, templates: record<accountEdit: string, accountIndex: string, accountTwoFactorDisable: string, accountTwoFactorEnable: string, accountTwoFactorIndex: string, accountWebAuthnAdd: string, accountWebAuthnDelete: string, accountWebAuthnIndex: string, confirmationRequired: string, emailComplete: string, emailSent: string, emailVerificationRequired: string, emailVerify: string, helpers: string, index: string, oauth2Authorize: string, oauth2AuthorizedNotRegistered: string, oauth2ChildRegistrationNotAllowed: string, oauth2ChildRegistrationNotAllowedComplete: string, oauth2CompleteRegistration: string, oauth2Consent: string, oauth2Device: string, oauth2DeviceComplete: string, oauth2Error: string, oauth2Logout: string, oauth2Passwordless: string, oauth2Register: string, oauth2StartIdPLink: string, oauth2TwoFactor: string, oauth2TwoFactorEnable: string, oauth2TwoFactorEnableComplete: string, oauth2TwoFactorMethods: string, oauth2Wait: string, oauth2WebAuthn: string, oauth2WebAuthnReauth: string, oauth2WebAuthnReauthEnable: string, passwordChange: string, passwordComplete: string, passwordForgot: string, passwordSent: string, phoneComplete: string, phoneSent: string, phoneVerificationRequired: string, phoneVerify: string, registrationComplete: string, registrationSent: string, registrationVerificationRequired: string, registrationVerify: string, samlv2Logout: string, unauthorized: string, emailSend: string, registrationSend: string>, type: string, variables: record<alertBackgroundColor: string, alertFontColor: string, backgroundImageURL: string, backgroundSize: string, borderRadius: string, deleteButtonColor: string, deleteButtonFocusColor: string, deleteButtonTextColor: string, deleteButtonTextFocusColor: string, errorFontColor: string, errorIconColor: string, favicons: list, fontColor: string, fontFamily: string, footerDisplay: bool, iconBackgroundColor: string, iconColor: string, infoIconColor: string, inputBackgroundColor: string, inputIconColor: string, inputTextColor: string, linkTextColor: string, linkTextFocusColor: string, logoImageSize: string, logoImageURL: string, monoFontColor: string, monoFontFamily: string, pageBackgroundColor: string, panelBackgroundColor: string, primaryButtonColor: string, primaryButtonFocusColor: string, primaryButtonTextColor: string, primaryButtonTextFocusColor: string>>, themes: table<data: record, defaultMessages: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedMessages: record, name: string, stylesheet: string, templates: record, type: string, variables: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/theme/($themeId)")
  let body = {sourceThemeId: $sourceThemeId, theme: $theme} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the theme for the given Id.
#
# GET /api/theme/{themeId}
# operationId: retrieveThemeWithId
export def "theme retrieveThemeWithId" [
  themeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<theme: record<data: record, defaultMessages: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedMessages: record, name: string, stylesheet: string, templates: record<accountEdit: string, accountIndex: string, accountTwoFactorDisable: string, accountTwoFactorEnable: string, accountTwoFactorIndex: string, accountWebAuthnAdd: string, accountWebAuthnDelete: string, accountWebAuthnIndex: string, confirmationRequired: string, emailComplete: string, emailSent: string, emailVerificationRequired: string, emailVerify: string, helpers: string, index: string, oauth2Authorize: string, oauth2AuthorizedNotRegistered: string, oauth2ChildRegistrationNotAllowed: string, oauth2ChildRegistrationNotAllowedComplete: string, oauth2CompleteRegistration: string, oauth2Consent: string, oauth2Device: string, oauth2DeviceComplete: string, oauth2Error: string, oauth2Logout: string, oauth2Passwordless: string, oauth2Register: string, oauth2StartIdPLink: string, oauth2TwoFactor: string, oauth2TwoFactorEnable: string, oauth2TwoFactorEnableComplete: string, oauth2TwoFactorMethods: string, oauth2Wait: string, oauth2WebAuthn: string, oauth2WebAuthnReauth: string, oauth2WebAuthnReauthEnable: string, passwordChange: string, passwordComplete: string, passwordForgot: string, passwordSent: string, phoneComplete: string, phoneSent: string, phoneVerificationRequired: string, phoneVerify: string, registrationComplete: string, registrationSent: string, registrationVerificationRequired: string, registrationVerify: string, samlv2Logout: string, unauthorized: string, emailSend: string, registrationSend: string>, type: string, variables: record<alertBackgroundColor: string, alertFontColor: string, backgroundImageURL: string, backgroundSize: string, borderRadius: string, deleteButtonColor: string, deleteButtonFocusColor: string, deleteButtonTextColor: string, deleteButtonTextFocusColor: string, errorFontColor: string, errorIconColor: string, favicons: list, fontColor: string, fontFamily: string, footerDisplay: bool, iconBackgroundColor: string, iconColor: string, infoIconColor: string, inputBackgroundColor: string, inputIconColor: string, inputTextColor: string, linkTextColor: string, linkTextFocusColor: string, logoImageSize: string, logoImageURL: string, monoFontColor: string, monoFontFamily: string, pageBackgroundColor: string, panelBackgroundColor: string, primaryButtonColor: string, primaryButtonFocusColor: string, primaryButtonTextColor: string, primaryButtonTextFocusColor: string>>, themes: table<data: record, defaultMessages: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedMessages: record, name: string, stylesheet: string, templates: record, type: string, variables: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/theme/($themeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the theme with the given Id.
#
# PUT /api/theme/{themeId}
# operationId: updateThemeWithId
# --theme shape: {data?: record, defaultMessages?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, localizedMessages?: record, name?: string, stylesheet?: string, templates?: record, type?: "advanced"|"simple", variables?: record}
export def "theme updateThemeWithId" [
  themeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sourceThemeId: string # format: uuid
  --theme: record # shape: {data?: record, defaultMessages?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, localizedMessages?: record, name?: string, stylesheet?: string, templates?: record, type?: "advanced"|"simple", variables?: record}
]: any -> record<theme: record<data: record, defaultMessages: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedMessages: record, name: string, stylesheet: string, templates: record<accountEdit: string, accountIndex: string, accountTwoFactorDisable: string, accountTwoFactorEnable: string, accountTwoFactorIndex: string, accountWebAuthnAdd: string, accountWebAuthnDelete: string, accountWebAuthnIndex: string, confirmationRequired: string, emailComplete: string, emailSent: string, emailVerificationRequired: string, emailVerify: string, helpers: string, index: string, oauth2Authorize: string, oauth2AuthorizedNotRegistered: string, oauth2ChildRegistrationNotAllowed: string, oauth2ChildRegistrationNotAllowedComplete: string, oauth2CompleteRegistration: string, oauth2Consent: string, oauth2Device: string, oauth2DeviceComplete: string, oauth2Error: string, oauth2Logout: string, oauth2Passwordless: string, oauth2Register: string, oauth2StartIdPLink: string, oauth2TwoFactor: string, oauth2TwoFactorEnable: string, oauth2TwoFactorEnableComplete: string, oauth2TwoFactorMethods: string, oauth2Wait: string, oauth2WebAuthn: string, oauth2WebAuthnReauth: string, oauth2WebAuthnReauthEnable: string, passwordChange: string, passwordComplete: string, passwordForgot: string, passwordSent: string, phoneComplete: string, phoneSent: string, phoneVerificationRequired: string, phoneVerify: string, registrationComplete: string, registrationSent: string, registrationVerificationRequired: string, registrationVerify: string, samlv2Logout: string, unauthorized: string, emailSend: string, registrationSend: string>, type: string, variables: record<alertBackgroundColor: string, alertFontColor: string, backgroundImageURL: string, backgroundSize: string, borderRadius: string, deleteButtonColor: string, deleteButtonFocusColor: string, deleteButtonTextColor: string, deleteButtonTextFocusColor: string, errorFontColor: string, errorIconColor: string, favicons: list, fontColor: string, fontFamily: string, footerDisplay: bool, iconBackgroundColor: string, iconColor: string, infoIconColor: string, inputBackgroundColor: string, inputIconColor: string, inputTextColor: string, linkTextColor: string, linkTextFocusColor: string, logoImageSize: string, logoImageURL: string, monoFontColor: string, monoFontFamily: string, pageBackgroundColor: string, panelBackgroundColor: string, primaryButtonColor: string, primaryButtonFocusColor: string, primaryButtonTextColor: string, primaryButtonTextFocusColor: string>>, themes: table<data: record, defaultMessages: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedMessages: record, name: string, stylesheet: string, templates: record, type: string, variables: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/theme/($themeId)")
  let body = {sourceThemeId: $sourceThemeId, theme: $theme} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Complete login using a 2FA challenge
#
# POST /api/two-factor/login
# operationId: twoFactorLoginWithId
# --metaData shape: {data?: record, device?: record, resources?: list, scopes?: list}
export def "two-factor-login twoFactorLoginWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --code: string
  --trustComputer: string@bool-completer
  --twoFactorId: string
  --userId: string # format: uuid
  --applicationId: string # format: uuid
  --ipAddress: string
  --metaData: record # shape: {data?: record, device?: record, resources?: list, scopes?: list}
  --newDevice: string@bool-completer
  --noJWT: string@bool-completer
]: any -> record<actions: table<actionId: string, actionerUserId: string, expiry: int, localizedName: string, localizedOption: string, localizedReason: string, name: string, option: string, reason: string, reasonCode: string>, changePasswordId: string, changePasswordReason: string, configurableMethods: list<string>, emailVerificationId: string, identityVerificationId: string, methods: table<authenticator: record, email: string, id: string, lastUsed: bool, method: string, mobilePhone: string, secret: string>, pendingIdPLinkId: string, refreshToken: string, refreshTokenId: string, registrationVerificationId: string, state: record, threatsDetected: list<any>, token: string, tokenExpirationInstant: int, trustToken: string, twoFactorId: string, twoFactorTrustId: string, user: record<preferredLanguages: list<string>, active: bool, birthDate: string, cleanSpeakId: string, data: record, email: string, expiry: int, firstName: string, fullName: string, imageUrl: string, insertInstant: int, lastName: string, legacyIdentifier: string, lastUpdateInstant: int, middleName: string, mobilePhone: string, parentEmail: string, phoneNumber: string, tenantId: string, timezone: string, twoFactor: record<methods: list, recoveryCodes: list>, memberships: list<record>, registrations: list<record>, identities: list<record>, breachedPasswordLastCheckedInstant: int, breachedPasswordStatus: string, connectorId: string, encryptionScheme: string, factor: int, id: string, lastLoginInstant: int, password: string, passwordChangeReason: string, passwordChangeRequired: bool, passwordLastUpdateInstant: int, salt: string, uniqueUsername: string, username: string, usernameStatus: string, verified: bool, verifiedInstant: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/two-factor/login")
  let body = {code: $code, trustComputer: $trustComputer, twoFactorId: $twoFactorId, userId: $userId, applicationId: $applicationId, ipAddress: $ipAddress, metaData: $metaData, newDevice: $newDevice, noJWT: $noJWT} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate a Two Factor secret that can be used to enable Two Factor authentication for a User. The response will contain both the secret and a Base32 encoded form of the secret which can be shown to a User when using a 2 Step Authentication application such as Google Authenticator.
#
# GET /api/two-factor/secret
# operationId: generateTwoFactorSecretUsingJWTWithId
export def "two-factor-secret generateTwoFactorSecretUsingJWTWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<secret: string, secretBase32Encoded: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/two-factor/secret")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Send a Two Factor authentication code to assist in setting up Two Factor authentication or disabling.
#
# POST /api/two-factor/send
# operationId: sendTwoFactorCodeForEnableDisableWithId
export def "two-factor-send sendTwoFactorCodeForEnableDisableWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applicationId: string # format: uuid
  --email: string
  --messageType: string@messageType-completer
  --method: string
  --methodId: string
  --mobilePhone: string
  --userId: string # format: uuid
]: any -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/two-factor/send")
  let body = {applicationId: $applicationId, email: $email, messageType: $messageType, method: $method, methodId: $methodId, mobilePhone: $mobilePhone, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send a Two Factor authentication code to allow the completion of Two Factor authentication.
#
# POST /api/two-factor/send/{twoFactorId}
# operationId: sendTwoFactorCodeForLoginUsingMethodWithId
export def "two-factor-send sendTwoFactorCodeForLoginUsingMethodWithId" [
  twoFactorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applicationId: string # format: uuid
  --email: string
  --messageType: string@messageType-completer
  --method: string
  --methodId: string
  --mobilePhone: string
  --userId: string # format: uuid
]: any -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/two-factor/send/($twoFactorId)")
  let body = {applicationId: $applicationId, email: $email, messageType: $messageType, method: $method, methodId: $methodId, mobilePhone: $mobilePhone, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Start a Two-Factor login request by generating a two-factor identifier. This code can then be sent to the Two Factor Send  API (/api/two-factor/send)in order to send a one-time use code to a user. You can also use one-time use code returned  to send the code out-of-band. The Two-Factor login is completed by making a request to the Two-Factor Login  API (/api/two-factor/login). with the two-factor identifier and the one-time use code.  This API is intended to allow you to begin a Two-Factor login outside a normal login that originated from the Login API (/api/login).
#
# POST /api/two-factor/start
# operationId: startTwoFactorLoginWithId
export def "two-factor-start startTwoFactorLoginWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applicationId: string # format: uuid
  --code: string
  --loginId: string
  --loginIdTypes: list
  --state: record
  --trustChallenge: string
  --userId: string # format: uuid
]: any -> record<code: string, methods: table<authenticator: record, email: string, id: string, lastUsed: bool, method: string, mobilePhone: string, secret: string>, twoFactorId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/two-factor/start")
  let body = {applicationId: $applicationId, code: $code, loginId: $loginId, loginIdTypes: $loginIdTypes, state: $state, trustChallenge: $trustChallenge, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a user's two-factor status.  This can be used to see if a user will need to complete a two-factor challenge to complete a login, and optionally identify the state of the two-factor trust across various applications. This operation provides more payload options than retrieveTwoFactorStatus.
#
# POST /api/two-factor/status
# operationId: retrieveTwoFactorStatusWithRequestWithId
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "two-factor-status retrieveTwoFactorStatusWithRequestWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userId: string # format: uuid
  --accessToken: string
  --action: string@action-completer # Communicate various actionscontexts in which multi-factor authentication can be used.
  --applicationId: string # format: uuid
  --twoFactorTrustId: string
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<trusts: table<applicationId: string, expiration: int, startInstant: int>, twoFactorTrustId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/two-factor/status")
  let body = {userId: $userId, accessToken: $accessToken, action: $action, applicationId: $applicationId, twoFactorTrustId: $twoFactorTrustId, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a user's two-factor status.  This can be used to see if a user will need to complete a two-factor challenge to complete a login, and optionally identify the state of the two-factor trust across various applications.
#
# GET /api/two-factor/status/{twoFactorTrustId}
# operationId: retrieveTwoFactorStatusWithId
export def "two-factor-status retrieveTwoFactorStatusWithId" [
  twoFactorTrustId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userId: string # The user Id to retrieve the Two-Factor status.
  --applicationId: string # The optional applicationId to verify.
]: nothing -> record<trusts: table<applicationId: string, expiration: int, startInstant: int>, twoFactorTrustId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $userId "scalar") (serialize-qp "applicationId" $applicationId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/two-factor/status/($twoFactorTrustId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a user. You can optionally specify an Id for the user, if not provided one will be generated.
#
# POST /api/user
# operationId: createUser
# --user shape: {preferredLanguages?: list, active?: bool, birthDate?: string, cleanSpeakId?: string, data?: record, email?: string, expiry?: int, firstName?: string, fullName?: string, imageUrl?: string, insertInstant?: int, lastName?: string, legacyIdentifier?: string, lastUpdateInstant?: int, middleName?: string, mobilePhone?: string, parentEmail?: string, phoneNumber?: string, tenantId?: string, timezone?: string, twoFactor?: record, memberships?: list, registrations?: list, identities?: list, breachedPasswordLastCheckedInstant?: int, breachedPasswordStatus?: "None"|"ExactMatch"|"SubAddressMatch"|"PasswordOnly"|"CommonPassword", connectorId?: string, encryptionScheme?: string, factor?: int, id?: string, lastLoginInstant?: int, password?: string, passwordChangeReason?: "Administrative"|"Breached"|"Expired"|"Validation", passwordChangeRequired?: bool, passwordLastUpdateInstant?: int, salt?: string, uniqueUsername?: string, username?: string, usernameStatus?: "ACTIVE"|"PENDING"|"REJECTED", verified?: bool, verifiedInstant?: int}
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "user createUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --applicationId: string # format: uuid
  --currentPassword: string
  --disableDomainBlock: string@bool-completer
  --sendSetPasswordEmail: string@bool-completer
  --sendSetPasswordIdentityType: string@sendSetPasswordIdentityType-completer # Used to indicate which identity type a password "request" might go to. It could be  used for send set passwords or send password resets.
  --skipVerification: string@bool-completer
  --user: record # The public, global view of a User. This object contains all global information about the user including birthdate, registration information  preferred languages, global attributes, etc. — shape: {preferredLanguages?: list, active?: bool, birthDate?: string, cleanSpeakId?: string, data?: record, email?: string, expiry?: int, firstName?: string, fullName?: string, imageUrl?: string, insertInstant?: int, lastName?: string, legacyIdentifier?: string, lastUpdateInstant?: int, middleName?: string, mobilePhone?: string, parentEmail?: string, phoneNumber?: string, tenantId?: string, timezone?: string, twoFactor?: record, memberships?: list, registrations?: list, identities?: list, breachedPasswordLastCheckedInstant?: int, breachedPasswordStatus?: "None"|"ExactMatch"|"SubAddressMatch"|"PasswordOnly"|"CommonPassword", connectorId?: string, encryptionScheme?: string, factor?: int, id?: string, lastLoginInstant?: int, password?: string, passwordChangeReason?: "Administrative"|"Breached"|"Expired"|"Validation", passwordChangeRequired?: bool, passwordLastUpdateInstant?: int, salt?: string, uniqueUsername?: string, username?: string, usernameStatus?: "ACTIVE"|"PENDING"|"REJECTED", verified?: bool, verifiedInstant?: int}
  --verificationIds: list
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<emailVerificationId: string, emailVerificationOneTimeCode: string, registrationVerificationIds: record, registrationVerificationOneTimeCodes: record, token: string, tokenExpirationInstant: int, user: record<preferredLanguages: list<string>, active: bool, birthDate: string, cleanSpeakId: string, data: record, email: string, expiry: int, firstName: string, fullName: string, imageUrl: string, insertInstant: int, lastName: string, legacyIdentifier: string, lastUpdateInstant: int, middleName: string, mobilePhone: string, parentEmail: string, phoneNumber: string, tenantId: string, timezone: string, twoFactor: record<methods: list, recoveryCodes: list>, memberships: list<record>, registrations: list<record>, identities: list<record>, breachedPasswordLastCheckedInstant: int, breachedPasswordStatus: string, connectorId: string, encryptionScheme: string, factor: int, id: string, lastLoginInstant: int, password: string, passwordChangeReason: string, passwordChangeRequired: bool, passwordLastUpdateInstant: int, salt: string, uniqueUsername: string, username: string, usernameStatus: string, verified: bool, verifiedInstant: int>, verificationIds: table<id: string, oneTimeCode: string, type: record, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/user")
  let body = {applicationId: $applicationId, currentPassword: $currentPassword, disableDomainBlock: $disableDomainBlock, sendSetPasswordEmail: $sendSetPasswordEmail, sendSetPasswordIdentityType: $sendSetPasswordIdentityType, skipVerification: $skipVerification, user: $user, verificationIds: $verificationIds, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the user by a verificationId. The intended use of this API is to retrieve a user after the forgot password workflow has been initiated and you may not know the user's email or username. OR Retrieves the user for the given username. OR Retrieves the user for the loginId, using specific loginIdTypes. OR Retrieves the user for the loginId. The loginId can be either the username or the email. OR Retrieves the user for the given email. OR Retrieves the user by a change password Id. The intended use of this API is to retrieve a user after the forgot password workflow has been initiated and you may not know the user's email or username.
#
# GET /api/user
# operationId: retrieveUser
export def "user retrieveUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --verificationId: string # The unique verification Id that has been set on the user object.
  --username: string # The username of the user.
  --loginId: string # The email or username of the user.
  --loginIdTypes: list # The identity types that FusionAuth will compare the loginId to.
  --email: string # The email of the user.
  --changePasswordId: string # The unique change password Id that was sent via email or returned by the Forgot Password API.
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
]: nothing -> record<emailVerificationId: string, emailVerificationOneTimeCode: string, registrationVerificationIds: record, registrationVerificationOneTimeCodes: record, token: string, tokenExpirationInstant: int, user: record<preferredLanguages: list<string>, active: bool, birthDate: string, cleanSpeakId: string, data: record, email: string, expiry: int, firstName: string, fullName: string, imageUrl: string, insertInstant: int, lastName: string, legacyIdentifier: string, lastUpdateInstant: int, middleName: string, mobilePhone: string, parentEmail: string, phoneNumber: string, tenantId: string, timezone: string, twoFactor: record<methods: list, recoveryCodes: list>, memberships: list<record>, registrations: list<record>, identities: list<record>, breachedPasswordLastCheckedInstant: int, breachedPasswordStatus: string, connectorId: string, encryptionScheme: string, factor: int, id: string, lastLoginInstant: int, password: string, passwordChangeReason: string, passwordChangeRequired: bool, passwordLastUpdateInstant: int, salt: string, uniqueUsername: string, username: string, usernameStatus: string, verified: bool, verifiedInstant: int>, verificationIds: table<id: string, oneTimeCode: string, type: record, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "verificationId" $verificationId "scalar") (serialize-qp "username" $username "scalar") (serialize-qp "loginId" $loginId "scalar") (serialize-qp "loginIdTypes" $loginIdTypes "multi") (serialize-qp "email" $email "scalar") (serialize-qp "changePasswordId" $changePasswordId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/user" $qp)
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a user action. This action cannot be taken on a user until this call successfully returns. Anytime after that the user action can be applied to any user.
#
# POST /api/user-action
# operationId: createUserAction
# --userAction shape: {active?: bool, cancelEmailTemplateId?: string, endEmailTemplateId?: string, id?: string, includeEmailInEventJSON?: bool, insertInstant?: int, lastUpdateInstant?: int, localizedNames?: record, modifyEmailTemplateId?: string, name?: string, options?: list, preventLogin?: bool, sendEndEvent?: bool, startEmailTemplateId?: string, temporal?: bool, transactionType?: "None"|"Any"|"SimpleMajority"|"SuperMajority"|"AbsoluteMajority", userEmailingEnabled?: bool, userNotificationsEnabled?: bool}
export def "user-action createUserAction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --userAction: record # An action that can be executed on a user (discipline or reward potentially). — shape: {active?: bool, cancelEmailTemplateId?: string, endEmailTemplateId?: string, id?: string, includeEmailInEventJSON?: bool, insertInstant?: int, lastUpdateInstant?: int, localizedNames?: record, modifyEmailTemplateId?: string, name?: string, options?: list, preventLogin?: bool, sendEndEvent?: bool, startEmailTemplateId?: string, temporal?: bool, transactionType?: "None"|"Any"|"SimpleMajority"|"SuperMajority"|"AbsoluteMajority", userEmailingEnabled?: bool, userNotificationsEnabled?: bool}
]: any -> record<userAction: record<active: bool, cancelEmailTemplateId: string, endEmailTemplateId: string, id: string, includeEmailInEventJSON: bool, insertInstant: int, lastUpdateInstant: int, localizedNames: record, modifyEmailTemplateId: string, name: string, options: list<record>, preventLogin: bool, sendEndEvent: bool, startEmailTemplateId: string, temporal: bool, transactionType: string, userEmailingEnabled: bool, userNotificationsEnabled: bool>, userActions: table<active: bool, cancelEmailTemplateId: string, endEmailTemplateId: string, id: string, includeEmailInEventJSON: bool, insertInstant: int, lastUpdateInstant: int, localizedNames: record, modifyEmailTemplateId: string, name: string, options: list, preventLogin: bool, sendEndEvent: bool, startEmailTemplateId: string, temporal: bool, transactionType: string, userEmailingEnabled: bool, userNotificationsEnabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/user-action")
  let body = {userAction: $userAction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the user action for the given Id. If you pass in null for the Id, this will return all the user actions. OR Retrieves all the user actions that are currently inactive.
#
# GET /api/user-action
# operationId: retrieveUserAction
export def "user-action retrieveUserAction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --inactive: string
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
]: nothing -> record<userAction: record<active: bool, cancelEmailTemplateId: string, endEmailTemplateId: string, id: string, includeEmailInEventJSON: bool, insertInstant: int, lastUpdateInstant: int, localizedNames: record, modifyEmailTemplateId: string, name: string, options: list<record>, preventLogin: bool, sendEndEvent: bool, startEmailTemplateId: string, temporal: bool, transactionType: string, userEmailingEnabled: bool, userNotificationsEnabled: bool>, userActions: table<active: bool, cancelEmailTemplateId: string, endEmailTemplateId: string, id: string, includeEmailInEventJSON: bool, insertInstant: int, lastUpdateInstant: int, localizedNames: record, modifyEmailTemplateId: string, name: string, options: list, preventLogin: bool, sendEndEvent: bool, startEmailTemplateId: string, temporal: bool, transactionType: string, userEmailingEnabled: bool, userNotificationsEnabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "inactive" $inactive "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/user-action" $qp)
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a user reason. This user action reason cannot be used when actioning a user until this call completes successfully. Anytime after that the user action reason can be used.
#
# POST /api/user-action-reason
# operationId: createUserActionReason
# --userActionReason shape: {code?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, localizedTexts?: record, text?: string}
export def "user-action-reason createUserActionReason" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userActionReason: record # Models action reasons. — shape: {code?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, localizedTexts?: record, text?: string}
]: any -> record<userActionReason: record<code: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedTexts: record, text: string>, userActionReasons: table<code: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedTexts: record, text: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/user-action-reason")
  let body = {userActionReason: $userActionReason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the user action reason for the given Id. If you pass in null for the Id, this will return all the user action reasons.
#
# GET /api/user-action-reason
# operationId: retrieveUserActionReason
export def "user-action-reason retrieveUserActionReason" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<userActionReason: record<code: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedTexts: record, text: string>, userActionReasons: table<code: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedTexts: record, text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/user-action-reason")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a user reason. This user action reason cannot be used when actioning a user until this call completes successfully. Anytime after that the user action reason can be used.
#
# POST /api/user-action-reason/{userActionReasonId}
# operationId: createUserActionReasonWithId
# --userActionReason shape: {code?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, localizedTexts?: record, text?: string}
export def "user-action-reason createUserActionReasonWithId" [
  userActionReasonId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userActionReason: record # Models action reasons. — shape: {code?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, localizedTexts?: record, text?: string}
]: any -> record<userActionReason: record<code: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedTexts: record, text: string>, userActionReasons: table<code: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedTexts: record, text: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user-action-reason/($userActionReasonId)")
  let body = {userActionReason: $userActionReason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the user action reason for the given Id.
#
# DELETE /api/user-action-reason/{userActionReasonId}
# operationId: deleteUserActionReasonWithId
export def "user-action-reason delete" [
  userActionReasonId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user-action-reason/($userActionReasonId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates, via PATCH, the user action reason with the given Id.
#
# PATCH /api/user-action-reason/{userActionReasonId}
# operationId: patchUserActionReasonWithId
# --userActionReason shape: {code?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, localizedTexts?: record, text?: string}
export def "user-action-reason patch" [
  userActionReasonId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userActionReason: record # Models action reasons. — shape: {code?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, localizedTexts?: record, text?: string}
]: any -> record<userActionReason: record<code: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedTexts: record, text: string>, userActionReasons: table<code: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedTexts: record, text: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user-action-reason/($userActionReasonId)")
  let body = {userActionReason: $userActionReason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the user action reason for the given Id. If you pass in null for the Id, this will return all the user action reasons.
#
# GET /api/user-action-reason/{userActionReasonId}
# operationId: retrieveUserActionReasonWithId
export def "user-action-reason retrieveUserActionReasonWithId" [
  userActionReasonId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<userActionReason: record<code: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedTexts: record, text: string>, userActionReasons: table<code: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedTexts: record, text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user-action-reason/($userActionReasonId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the user action reason with the given Id.
#
# PUT /api/user-action-reason/{userActionReasonId}
# operationId: updateUserActionReasonWithId
# --userActionReason shape: {code?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, localizedTexts?: record, text?: string}
export def "user-action-reason updateUserActionReasonWithId" [
  userActionReasonId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userActionReason: record # Models action reasons. — shape: {code?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, localizedTexts?: record, text?: string}
]: any -> record<userActionReason: record<code: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedTexts: record, text: string>, userActionReasons: table<code: string, id: string, insertInstant: int, lastUpdateInstant: int, localizedTexts: record, text: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user-action-reason/($userActionReasonId)")
  let body = {userActionReason: $userActionReason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a user action. This action cannot be taken on a user until this call successfully returns. Anytime after that the user action can be applied to any user.
#
# POST /api/user-action/{userActionId}
# operationId: createUserActionWithId
# --userAction shape: {active?: bool, cancelEmailTemplateId?: string, endEmailTemplateId?: string, id?: string, includeEmailInEventJSON?: bool, insertInstant?: int, lastUpdateInstant?: int, localizedNames?: record, modifyEmailTemplateId?: string, name?: string, options?: list, preventLogin?: bool, sendEndEvent?: bool, startEmailTemplateId?: string, temporal?: bool, transactionType?: "None"|"Any"|"SimpleMajority"|"SuperMajority"|"AbsoluteMajority", userEmailingEnabled?: bool, userNotificationsEnabled?: bool}
export def "user-action createUserActionWithId" [
  userActionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --userAction: record # An action that can be executed on a user (discipline or reward potentially). — shape: {active?: bool, cancelEmailTemplateId?: string, endEmailTemplateId?: string, id?: string, includeEmailInEventJSON?: bool, insertInstant?: int, lastUpdateInstant?: int, localizedNames?: record, modifyEmailTemplateId?: string, name?: string, options?: list, preventLogin?: bool, sendEndEvent?: bool, startEmailTemplateId?: string, temporal?: bool, transactionType?: "None"|"Any"|"SimpleMajority"|"SuperMajority"|"AbsoluteMajority", userEmailingEnabled?: bool, userNotificationsEnabled?: bool}
]: any -> record<userAction: record<active: bool, cancelEmailTemplateId: string, endEmailTemplateId: string, id: string, includeEmailInEventJSON: bool, insertInstant: int, lastUpdateInstant: int, localizedNames: record, modifyEmailTemplateId: string, name: string, options: list<record>, preventLogin: bool, sendEndEvent: bool, startEmailTemplateId: string, temporal: bool, transactionType: string, userEmailingEnabled: bool, userNotificationsEnabled: bool>, userActions: table<active: bool, cancelEmailTemplateId: string, endEmailTemplateId: string, id: string, includeEmailInEventJSON: bool, insertInstant: int, lastUpdateInstant: int, localizedNames: record, modifyEmailTemplateId: string, name: string, options: list, preventLogin: bool, sendEndEvent: bool, startEmailTemplateId: string, temporal: bool, transactionType: string, userEmailingEnabled: bool, userNotificationsEnabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user-action/($userActionId)")
  let body = {userAction: $userAction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the user action for the given Id. This permanently deletes the user action and also any history and logs of the action being applied to any users. OR Deactivates the user action with the given Id.
#
# DELETE /api/user-action/{userActionId}
# operationId: deleteUserActionWithId
export def "user-action delete" [
  userActionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hardDelete: string
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
]: nothing -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hardDelete" $hardDelete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/user-action/($userActionId)" $qp)
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates, via PATCH, the user action with the given Id.
#
# PATCH /api/user-action/{userActionId}
# operationId: patchUserActionWithId
# --userAction shape: {active?: bool, cancelEmailTemplateId?: string, endEmailTemplateId?: string, id?: string, includeEmailInEventJSON?: bool, insertInstant?: int, lastUpdateInstant?: int, localizedNames?: record, modifyEmailTemplateId?: string, name?: string, options?: list, preventLogin?: bool, sendEndEvent?: bool, startEmailTemplateId?: string, temporal?: bool, transactionType?: "None"|"Any"|"SimpleMajority"|"SuperMajority"|"AbsoluteMajority", userEmailingEnabled?: bool, userNotificationsEnabled?: bool}
export def "user-action patch" [
  userActionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --userAction: record # An action that can be executed on a user (discipline or reward potentially). — shape: {active?: bool, cancelEmailTemplateId?: string, endEmailTemplateId?: string, id?: string, includeEmailInEventJSON?: bool, insertInstant?: int, lastUpdateInstant?: int, localizedNames?: record, modifyEmailTemplateId?: string, name?: string, options?: list, preventLogin?: bool, sendEndEvent?: bool, startEmailTemplateId?: string, temporal?: bool, transactionType?: "None"|"Any"|"SimpleMajority"|"SuperMajority"|"AbsoluteMajority", userEmailingEnabled?: bool, userNotificationsEnabled?: bool}
]: any -> record<userAction: record<active: bool, cancelEmailTemplateId: string, endEmailTemplateId: string, id: string, includeEmailInEventJSON: bool, insertInstant: int, lastUpdateInstant: int, localizedNames: record, modifyEmailTemplateId: string, name: string, options: list<record>, preventLogin: bool, sendEndEvent: bool, startEmailTemplateId: string, temporal: bool, transactionType: string, userEmailingEnabled: bool, userNotificationsEnabled: bool>, userActions: table<active: bool, cancelEmailTemplateId: string, endEmailTemplateId: string, id: string, includeEmailInEventJSON: bool, insertInstant: int, lastUpdateInstant: int, localizedNames: record, modifyEmailTemplateId: string, name: string, options: list, preventLogin: bool, sendEndEvent: bool, startEmailTemplateId: string, temporal: bool, transactionType: string, userEmailingEnabled: bool, userNotificationsEnabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user-action/($userActionId)")
  let body = {userAction: $userAction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates the user action with the given Id. OR Reactivates the user action with the given Id.
#
# PUT /api/user-action/{userActionId}
# operationId: updateUserActionWithId
# --userAction shape: {active?: bool, cancelEmailTemplateId?: string, endEmailTemplateId?: string, id?: string, includeEmailInEventJSON?: bool, insertInstant?: int, lastUpdateInstant?: int, localizedNames?: record, modifyEmailTemplateId?: string, name?: string, options?: list, preventLogin?: bool, sendEndEvent?: bool, startEmailTemplateId?: string, temporal?: bool, transactionType?: "None"|"Any"|"SimpleMajority"|"SuperMajority"|"AbsoluteMajority", userEmailingEnabled?: bool, userNotificationsEnabled?: bool}
export def "user-action updateUserActionWithId" [
  userActionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reactivate: string
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --userAction: record # An action that can be executed on a user (discipline or reward potentially). — shape: {active?: bool, cancelEmailTemplateId?: string, endEmailTemplateId?: string, id?: string, includeEmailInEventJSON?: bool, insertInstant?: int, lastUpdateInstant?: int, localizedNames?: record, modifyEmailTemplateId?: string, name?: string, options?: list, preventLogin?: bool, sendEndEvent?: bool, startEmailTemplateId?: string, temporal?: bool, transactionType?: "None"|"Any"|"SimpleMajority"|"SuperMajority"|"AbsoluteMajority", userEmailingEnabled?: bool, userNotificationsEnabled?: bool}
]: any -> record<userAction: record<active: bool, cancelEmailTemplateId: string, endEmailTemplateId: string, id: string, includeEmailInEventJSON: bool, insertInstant: int, lastUpdateInstant: int, localizedNames: record, modifyEmailTemplateId: string, name: string, options: list<record>, preventLogin: bool, sendEndEvent: bool, startEmailTemplateId: string, temporal: bool, transactionType: string, userEmailingEnabled: bool, userNotificationsEnabled: bool>, userActions: table<active: bool, cancelEmailTemplateId: string, endEmailTemplateId: string, id: string, includeEmailInEventJSON: bool, insertInstant: int, lastUpdateInstant: int, localizedNames: record, modifyEmailTemplateId: string, name: string, options: list, preventLogin: bool, sendEndEvent: bool, startEmailTemplateId: string, temporal: bool, transactionType: string, userEmailingEnabled: bool, userNotificationsEnabled: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reactivate" $reactivate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/user-action/($userActionId)" $qp)
  let body = {userAction: $userAction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the user action for the given Id. If you pass in null for the Id, this will return all the user actions.
#
# GET /api/user-action/{userActionId}
# operationId: retrieveUserActionWithId
export def "user-action retrieveUserActionWithId" [
  userActionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
]: nothing -> record<userAction: record<active: bool, cancelEmailTemplateId: string, endEmailTemplateId: string, id: string, includeEmailInEventJSON: bool, insertInstant: int, lastUpdateInstant: int, localizedNames: record, modifyEmailTemplateId: string, name: string, options: list<record>, preventLogin: bool, sendEndEvent: bool, startEmailTemplateId: string, temporal: bool, transactionType: string, userEmailingEnabled: bool, userNotificationsEnabled: bool>, userActions: table<active: bool, cancelEmailTemplateId: string, endEmailTemplateId: string, id: string, includeEmailInEventJSON: bool, insertInstant: int, lastUpdateInstant: int, localizedNames: record, modifyEmailTemplateId: string, name: string, options: list, preventLogin: bool, sendEndEvent: bool, startEmailTemplateId: string, temporal: bool, transactionType: string, userEmailingEnabled: bool, userNotificationsEnabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user-action/($userActionId)")
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Takes an action on a user. The user being actioned is called the "actionee" and the user taking the action is called the "actioner". Both user ids are required in the request object.
#
# POST /api/user/action
# operationId: actionUserWithId
# --action shape: {actioneeUserId?: string, actionerUserId?: string, applicationIds?: list, comment?: string, emailUser?: bool, expiry?: int, notifyUser?: bool, option?: string, reasonId?: string, userActionId?: string}
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "user-action actionUserWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --action: record # shape: {actioneeUserId?: string, actionerUserId?: string, applicationIds?: list, comment?: string, emailUser?: bool, expiry?: int, notifyUser?: bool, option?: string, reasonId?: string, userActionId?: string}
  --broadcast: string@bool-completer
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<action: record<actioneeUserId: string, actionerUserId: string, applicationIds: list<string>, comment: string, emailUserOnEnd: bool, endEventSent: bool, expiry: int, history: record<historyItems: list>, id: string, insertInstant: int, localizedName: string, localizedOption: string, localizedReason: string, name: string, notifyUserOnEnd: bool, option: string, reason: string, reasonCode: string, userActionId: string>, actions: table<actioneeUserId: string, actionerUserId: string, applicationIds: list, comment: string, emailUserOnEnd: bool, endEventSent: bool, expiry: int, history: record, id: string, insertInstant: int, localizedName: string, localizedOption: string, localizedReason: string, name: string, notifyUserOnEnd: bool, option: string, reason: string, reasonCode: string, userActionId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/user/action")
  let body = {action: $action, broadcast: $broadcast, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves all the actions for the user with the given Id that are currently inactive. An inactive action means one that is time based and has been canceled or has expired, or is not time based. OR Retrieves all the actions for the user with the given Id that are currently active. An active action means one that is time based and has not been canceled, and has not ended. OR Retrieves all the actions for the user with the given Id that are currently preventing the User from logging in. OR Retrieves all the actions for the user with the given Id. This will return all time based actions that are active, and inactive as well as non-time based actions.
#
# GET /api/user/action
# operationId: retrieveUserActioning
export def "user-action retrieveUserActioning" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userId: string # The Id of the user to fetch the actions for.
  --active: string
  --preventingLogin: string
]: nothing -> record<action: record<actioneeUserId: string, actionerUserId: string, applicationIds: list<string>, comment: string, emailUserOnEnd: bool, endEventSent: bool, expiry: int, history: record<historyItems: list>, id: string, insertInstant: int, localizedName: string, localizedOption: string, localizedReason: string, name: string, notifyUserOnEnd: bool, option: string, reason: string, reasonCode: string, userActionId: string>, actions: table<actioneeUserId: string, actionerUserId: string, applicationIds: list, comment: string, emailUserOnEnd: bool, endEventSent: bool, expiry: int, history: record, id: string, insertInstant: int, localizedName: string, localizedOption: string, localizedReason: string, name: string, notifyUserOnEnd: bool, option: string, reason: string, reasonCode: string, userActionId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $userId "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "preventingLogin" $preventingLogin "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/user/action" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancels the user action.
#
# DELETE /api/user/action/{actionId}
# operationId: cancelActionWithId
# --action shape: {actioneeUserId?: string, actionerUserId?: string, applicationIds?: list, comment?: string, emailUser?: bool, expiry?: int, notifyUser?: bool, option?: string, reasonId?: string, userActionId?: string}
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "user-action cancelActionWithId" [
  actionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --action: record # shape: {actioneeUserId?: string, actionerUserId?: string, applicationIds?: list, comment?: string, emailUser?: bool, expiry?: int, notifyUser?: bool, option?: string, reasonId?: string, userActionId?: string}
  --broadcast: string@bool-completer
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<action: record<actioneeUserId: string, actionerUserId: string, applicationIds: list<string>, comment: string, emailUserOnEnd: bool, endEventSent: bool, expiry: int, history: record<historyItems: list>, id: string, insertInstant: int, localizedName: string, localizedOption: string, localizedReason: string, name: string, notifyUserOnEnd: bool, option: string, reason: string, reasonCode: string, userActionId: string>, actions: table<actioneeUserId: string, actionerUserId: string, applicationIds: list, comment: string, emailUserOnEnd: bool, endEventSent: bool, expiry: int, history: record, id: string, insertInstant: int, localizedName: string, localizedOption: string, localizedReason: string, name: string, notifyUserOnEnd: bool, option: string, reason: string, reasonCode: string, userActionId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user/action/($actionId)")
  let body = {action: $action, broadcast: $broadcast, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Modifies a temporal user action by changing the expiration of the action and optionally adding a comment to the action.
#
# PUT /api/user/action/{actionId}
# operationId: modifyActionWithId
# --action shape: {actioneeUserId?: string, actionerUserId?: string, applicationIds?: list, comment?: string, emailUser?: bool, expiry?: int, notifyUser?: bool, option?: string, reasonId?: string, userActionId?: string}
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "user-action modifyActionWithId" [
  actionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --action: record # shape: {actioneeUserId?: string, actionerUserId?: string, applicationIds?: list, comment?: string, emailUser?: bool, expiry?: int, notifyUser?: bool, option?: string, reasonId?: string, userActionId?: string}
  --broadcast: string@bool-completer
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<action: record<actioneeUserId: string, actionerUserId: string, applicationIds: list<string>, comment: string, emailUserOnEnd: bool, endEventSent: bool, expiry: int, history: record<historyItems: list>, id: string, insertInstant: int, localizedName: string, localizedOption: string, localizedReason: string, name: string, notifyUserOnEnd: bool, option: string, reason: string, reasonCode: string, userActionId: string>, actions: table<actioneeUserId: string, actionerUserId: string, applicationIds: list, comment: string, emailUserOnEnd: bool, endEventSent: bool, expiry: int, history: record, id: string, insertInstant: int, localizedName: string, localizedOption: string, localizedReason: string, name: string, notifyUserOnEnd: bool, option: string, reason: string, reasonCode: string, userActionId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user/action/($actionId)")
  let body = {action: $action, broadcast: $broadcast, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves a single action log (the log of a user action that was taken on a user previously) for the given Id.
#
# GET /api/user/action/{actionId}
# operationId: retrieveActionWithId
export def "user-action retrieveActionWithId" [
  actionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<action: record<actioneeUserId: string, actionerUserId: string, applicationIds: list<string>, comment: string, emailUserOnEnd: bool, endEventSent: bool, expiry: int, history: record<historyItems: list>, id: string, insertInstant: int, localizedName: string, localizedOption: string, localizedReason: string, name: string, notifyUserOnEnd: bool, option: string, reason: string, reasonCode: string, userActionId: string>, actions: table<actioneeUserId: string, actionerUserId: string, applicationIds: list, comment: string, emailUserOnEnd: bool, endEventSent: bool, expiry: int, history: record, id: string, insertInstant: int, localizedName: string, localizedOption: string, localizedReason: string, name: string, notifyUserOnEnd: bool, option: string, reason: string, reasonCode: string, userActionId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user/action/($actionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the users with the given Ids, or users matching the provided JSON query or queryString. The order of preference is Ids, query and then queryString, it is recommended to only provide one of the three for the request.  This method can be used to deactivate or permanently delete (hard-delete) users based upon the hardDelete boolean in the request body. Using the dryRun parameter you may also request the result of the action without actually deleting or deactivating any users. OR Deactivates the users with the given Ids.
#
# DELETE /api/user/bulk
# operationId: deleteUserBulk
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "user-bulk delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userIds: string # The ids of the users to deactivate.
  --dryRun: string
  --hardDelete: string
  --dryRun: string@bool-completer
  --hardDelete: string@bool-completer
  --limit: int
  --body-query: string
  --queryString: string
  --userIds: list
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<dryRun: bool, hardDelete: bool, total: int, userIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userIds" $userIds "scalar") (serialize-qp "dryRun" $dryRun "scalar") (serialize-qp "hardDelete" $hardDelete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/user/bulk" $qp)
  let body = {dryRun: $dryRun, hardDelete: $hardDelete, limit: $limit, query: $body_query, queryString: $queryString, userIds: $userIds, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Changes a user's password using their access token (JWT) instead of the changePasswordId A common use case for this method will be if you want to allow the user to change their own password.  Remember to send refreshToken in the request body if you want to get a new refresh token when login using the returned oneTimePassword. OR Changes a user's password using their identity (loginId and password). Using a loginId instead of the changePasswordId bypasses the email verification and allows a password to be changed directly without first calling the #forgotPassword method.
#
# POST /api/user/change-password
# operationId: createUserChangePassword
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "user-change-password createUserChangePassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applicationId: string # format: uuid
  --changePasswordId: string
  --currentPassword: string
  --loginId: string
  --loginIdTypes: list
  --password: string
  --refreshToken: string
  --trustChallenge: string
  --trustToken: string
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<oneTimePassword: string, state: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/user/change-password")
  let body = {applicationId: $applicationId, changePasswordId: $changePasswordId, currentPassword: $currentPassword, loginId: $loginId, loginIdTypes: $loginIdTypes, password: $password, refreshToken: $refreshToken, trustChallenge: $trustChallenge, trustToken: $trustToken, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check to see if the user must obtain a Trust Request Id in order to complete a change password request. When a user has enabled Two-Factor authentication, before you are allowed to use the Change Password API to change your password, you must obtain a Trust Request Id by completing a Two-Factor Step-Up authentication.  An HTTP status code of 400 with a general error code of [TrustTokenRequired] indicates that a Trust Token is required to make a POST request to this API. OR Check to see if the user must obtain a Trust Request Id in order to complete a change password request. When a user has enabled Two-Factor authentication, before you are allowed to use the Change Password API to change your password, you must obtain a Trust Request Id by completing a Two-Factor Step-Up authentication.  An HTTP status code of 400 with a general error code of [TrustTokenRequired] indicates that a Trust Token is required to make a POST request to this API. OR Check to see if the user must obtain a Trust Request Id in order to complete a change password request. When a user has enabled Two-Factor authentication, before you are allowed to use the Change Password API to change your password, you must obtain a Trust Request Id by completing a Two-Factor Step-Up authentication.  An HTTP status code of 400 with a general error code of [TrustTokenRequired] indicates that a Trust Token is required to make a POST request to this API. OR Check to see if the user must obtain a Trust Request Id in order to complete a change password request. When a user has enabled Two-Factor authentication, before you are allowed to use the Change Password API to change your password, you must obtain a Trust Request Id by completing a Two-Factor Step-Up authentication.  An HTTP status code of 400 with a general error code of [TrustTokenRequired] indicates that a Trust Token is required to make a POST request to this API. OR Check to see if the user must obtain a Trust Token Id in order to complete a change password request. When a user has enabled Two-Factor authentication, before you are allowed to use the Change Password API to change your password, you must obtain a Trust Token by completing a Two-Factor Step-Up authentication.  An HTTP status code of 400 with a general error code of [TrustTokenRequired] indicates that a Trust Token is required to make a POST request to this API. OR Check to see if the user must obtain a Trust Token Id in order to complete a change password request. When a user has enabled Two-Factor authentication, before you are allowed to use the Change Password API to change your password, you must obtain a Trust Token by completing a Two-Factor Step-Up authentication.  An HTTP status code of 400 with a general error code of [TrustTokenRequired] indicates that a Trust Token is required to make a POST request to this API.
#
# GET /api/user/change-password
# operationId: retrieveUserChangePassword
export def "user-change-password retrieveUserChangePassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --loginId: string # The loginId of the User that you intend to change the password for.
  --loginIdTypes: list # The identity types that FusionAuth will compare the loginId to.
  --ipAddress: string # IP address of the user changing their password. This is used for MFA risk assessment.
]: nothing -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "loginId" $loginId "scalar") (serialize-qp "loginIdTypes" $loginIdTypes "multi") (serialize-qp "ipAddress" $ipAddress "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/user/change-password" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Changes a user's password using the change password Id. This usually occurs after an email has been sent to the user and they clicked on a link to reset their password.  As of version 1.32.2, prefer sending the changePasswordId in the request body. To do this, omit the first parameter, and set the value in the request body.
#
# POST /api/user/change-password/{changePasswordId}
# operationId: changePasswordWithId
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "user-change-password changePasswordWithId" [
  changePasswordId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applicationId: string # format: uuid
  --body-changePasswordId: string
  --currentPassword: string
  --loginId: string
  --loginIdTypes: list
  --password: string
  --refreshToken: string
  --trustChallenge: string
  --trustToken: string
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<oneTimePassword: string, state: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user/change-password/($changePasswordId)")
  let body = {applicationId: $applicationId, changePasswordId: $body_changePasswordId, currentPassword: $currentPassword, loginId: $loginId, loginIdTypes: $loginIdTypes, password: $password, refreshToken: $refreshToken, trustChallenge: $trustChallenge, trustToken: $trustToken, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check to see if the user must obtain a Trust Token Id in order to complete a change password request. When a user has enabled Two-Factor authentication, before you are allowed to use the Change Password API to change your password, you must obtain a Trust Token by completing a Two-Factor Step-Up authentication.  An HTTP status code of 400 with a general error code of [TrustTokenRequired] indicates that a Trust Token is required to make a POST request to this API. OR Check to see if the user must obtain a Trust Token Id in order to complete a change password request. When a user has enabled Two-Factor authentication, before you are allowed to use the Change Password API to change your password, you must obtain a Trust Token by completing a Two-Factor Step-Up authentication.  An HTTP status code of 400 with a general error code of [TrustTokenRequired] indicates that a Trust Token is required to make a POST request to this API.
#
# GET /api/user/change-password/{changePasswordId}
# operationId: retrieveUserChangePasswordWithId
export def "user-change-password retrieveUserChangePasswordWithId" [
  changePasswordId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ipAddress: string # IP address of the user changing their password. This is used for MFA risk assessment.
]: nothing -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ipAddress" $ipAddress "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/user/change-password/($changePasswordId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Adds a comment to the user's account.
#
# POST /api/user/comment
# operationId: commentOnUserWithId
# --userComment shape: {comment?: string, commenterId?: string, id?: string, insertInstant?: int, userId?: string}
export def "user-comment commentOnUserWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --userComment: record # A log for an event that happened to a User. — shape: {comment?: string, commenterId?: string, id?: string, insertInstant?: int, userId?: string}
]: any -> record<userComment: record<comment: string, commenterId: string, id: string, insertInstant: int, userId: string>, userComments: table<comment: string, commenterId: string, id: string, insertInstant: int, userId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/user/comment")
  let body = {userComment: $userComment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Searches user comments with the specified criteria and pagination.
#
# POST /api/user/comment/search
# operationId: searchUserCommentsWithId
# --search shape: {comment?: string, commenterId?: string, tenantId?: string, userId?: string, numberOfResults?: int, orderBy?: string, startRow?: int}
export def "user-comment-search searchUserCommentsWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: record # Search criteria for user comments. — shape: {comment?: string, commenterId?: string, tenantId?: string, userId?: string, numberOfResults?: int, orderBy?: string, startRow?: int}
]: any -> record<total: int, userComments: table<comment: string, commenterId: string, id: string, insertInstant: int, userId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/user/comment/search")
  let body = {search: $search} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves all the comments for the user with the given Id.
#
# GET /api/user/comment/{userId}
# operationId: retrieveUserCommentsWithId
export def "user-comment retrieveUserCommentsWithId" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
]: nothing -> record<userComment: record<comment: string, commenterId: string, id: string, insertInstant: int, userId: string>, userComments: table<comment: string, commenterId: string, id: string, insertInstant: int, userId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user/comment/($userId)")
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a single User consent.
#
# POST /api/user/consent
# operationId: createUserConsent
# --userConsent shape: {data?: record, consent?: record, consentId?: string, giverUserId?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, status?: "Active"|"Revoked", userId?: string, values?: list}
export def "user-consent createUserConsent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userConsent: record # Models a User consent. — shape: {data?: record, consent?: record, consentId?: string, giverUserId?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, status?: "Active"|"Revoked", userId?: string, values?: list}
]: any -> record<userConsent: record<data: record, consent: record<data: record, consentEmailTemplateId: string, countryMinimumAgeForSelfConsent: record, defaultMinimumAgeForSelfConsent: int, emailPlus: record, id: string, insertInstant: int, lastUpdateInstant: int, multipleValuesAllowed: bool, name: string, values: list>, consentId: string, giverUserId: string, id: string, insertInstant: int, lastUpdateInstant: int, status: string, userId: string, values: list<string>>, userConsents: table<data: record, consent: record, consentId: string, giverUserId: string, id: string, insertInstant: int, lastUpdateInstant: int, status: string, userId: string, values: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/user/consent")
  let body = {userConsent: $userConsent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves all the consents for a User.
#
# GET /api/user/consent
# operationId: retrieveUserConsentsWithId
export def "user-consent retrieveUserConsentsWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userId: string # The User's Id
]: nothing -> record<userConsent: record<data: record, consent: record<data: record, consentEmailTemplateId: string, countryMinimumAgeForSelfConsent: record, defaultMinimumAgeForSelfConsent: int, emailPlus: record, id: string, insertInstant: int, lastUpdateInstant: int, multipleValuesAllowed: bool, name: string, values: list>, consentId: string, giverUserId: string, id: string, insertInstant: int, lastUpdateInstant: int, status: string, userId: string, values: list<string>>, userConsents: table<data: record, consent: record, consentId: string, giverUserId: string, id: string, insertInstant: int, lastUpdateInstant: int, status: string, userId: string, values: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $userId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/user/consent" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a single User consent.
#
# POST /api/user/consent/{userConsentId}
# operationId: createUserConsentWithId
# --userConsent shape: {data?: record, consent?: record, consentId?: string, giverUserId?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, status?: "Active"|"Revoked", userId?: string, values?: list}
export def "user-consent createUserConsentWithId" [
  userConsentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userConsent: record # Models a User consent. — shape: {data?: record, consent?: record, consentId?: string, giverUserId?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, status?: "Active"|"Revoked", userId?: string, values?: list}
]: any -> record<userConsent: record<data: record, consent: record<data: record, consentEmailTemplateId: string, countryMinimumAgeForSelfConsent: record, defaultMinimumAgeForSelfConsent: int, emailPlus: record, id: string, insertInstant: int, lastUpdateInstant: int, multipleValuesAllowed: bool, name: string, values: list>, consentId: string, giverUserId: string, id: string, insertInstant: int, lastUpdateInstant: int, status: string, userId: string, values: list<string>>, userConsents: table<data: record, consent: record, consentId: string, giverUserId: string, id: string, insertInstant: int, lastUpdateInstant: int, status: string, userId: string, values: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user/consent/($userConsentId)")
  let body = {userConsent: $userConsent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates, via PATCH, a single User consent by Id.
#
# PATCH /api/user/consent/{userConsentId}
# operationId: patchUserConsentWithId
# --userConsent shape: {data?: record, consent?: record, consentId?: string, giverUserId?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, status?: "Active"|"Revoked", userId?: string, values?: list}
export def "user-consent patch" [
  userConsentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userConsent: record # Models a User consent. — shape: {data?: record, consent?: record, consentId?: string, giverUserId?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, status?: "Active"|"Revoked", userId?: string, values?: list}
]: any -> record<userConsent: record<data: record, consent: record<data: record, consentEmailTemplateId: string, countryMinimumAgeForSelfConsent: record, defaultMinimumAgeForSelfConsent: int, emailPlus: record, id: string, insertInstant: int, lastUpdateInstant: int, multipleValuesAllowed: bool, name: string, values: list>, consentId: string, giverUserId: string, id: string, insertInstant: int, lastUpdateInstant: int, status: string, userId: string, values: list<string>>, userConsents: table<data: record, consent: record, consentId: string, giverUserId: string, id: string, insertInstant: int, lastUpdateInstant: int, status: string, userId: string, values: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user/consent/($userConsentId)")
  let body = {userConsent: $userConsent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a single User consent by Id.
#
# GET /api/user/consent/{userConsentId}
# operationId: retrieveUserConsentWithId
export def "user-consent retrieveUserConsentWithId" [
  userConsentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<userConsent: record<data: record, consent: record<data: record, consentEmailTemplateId: string, countryMinimumAgeForSelfConsent: record, defaultMinimumAgeForSelfConsent: int, emailPlus: record, id: string, insertInstant: int, lastUpdateInstant: int, multipleValuesAllowed: bool, name: string, values: list>, consentId: string, giverUserId: string, id: string, insertInstant: int, lastUpdateInstant: int, status: string, userId: string, values: list<string>>, userConsents: table<data: record, consent: record, consentId: string, giverUserId: string, id: string, insertInstant: int, lastUpdateInstant: int, status: string, userId: string, values: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user/consent/($userConsentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revokes a single User consent by Id.
#
# DELETE /api/user/consent/{userConsentId}
# operationId: revokeUserConsentWithId
export def "user-consent revokeUserConsentWithId" [
  userConsentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user/consent/($userConsentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a single User consent by Id.
#
# PUT /api/user/consent/{userConsentId}
# operationId: updateUserConsentWithId
# --userConsent shape: {data?: record, consent?: record, consentId?: string, giverUserId?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, status?: "Active"|"Revoked", userId?: string, values?: list}
export def "user-consent updateUserConsentWithId" [
  userConsentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userConsent: record # Models a User consent. — shape: {data?: record, consent?: record, consentId?: string, giverUserId?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, status?: "Active"|"Revoked", userId?: string, values?: list}
]: any -> record<userConsent: record<data: record, consent: record<data: record, consentEmailTemplateId: string, countryMinimumAgeForSelfConsent: record, defaultMinimumAgeForSelfConsent: int, emailPlus: record, id: string, insertInstant: int, lastUpdateInstant: int, multipleValuesAllowed: bool, name: string, values: list>, consentId: string, giverUserId: string, id: string, insertInstant: int, lastUpdateInstant: int, status: string, userId: string, values: list<string>>, userConsents: table<data: record, consent: record, consentId: string, giverUserId: string, id: string, insertInstant: int, lastUpdateInstant: int, status: string, userId: string, values: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user/consent/($userConsentId)")
  let body = {userConsent: $userConsent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a family with the user Id in the request as the owner and sole member of the family. You can optionally specify an Id for the family, if not provided one will be generated.
#
# POST /api/user/family
# operationId: createFamily
# --familyMember shape: {data?: record, insertInstant?: int, lastUpdateInstant?: int, owner?: bool, role?: "Child"|"Teen"|"Adult", userId?: string}
export def "user-family createFamily" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --familyMember: record # Models a single family member. — shape: {data?: record, insertInstant?: int, lastUpdateInstant?: int, owner?: bool, role?: "Child"|"Teen"|"Adult", userId?: string}
]: any -> record<families: table<members: list, id: string, insertInstant: int, lastUpdateInstant: int>, family: record<members: list<record>, id: string, insertInstant: int, lastUpdateInstant: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/user/family")
  let body = {familyMember: $familyMember} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves all the families that a user belongs to.
#
# GET /api/user/family
# operationId: retrieveFamiliesWithId
export def "user-family retrieveFamiliesWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userId: string # The User's id
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
]: nothing -> record<families: table<members: list, id: string, insertInstant: int, lastUpdateInstant: int>, family: record<members: list<record>, id: string, insertInstant: int, lastUpdateInstant: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $userId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/user/family" $qp)
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves all the children for the given parent email address.
#
# GET /api/user/family/pending
# operationId: retrievePendingChildrenWithId
export def "user-family-pending retrievePendingChildrenWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --parentEmail: string # The email of the parent.
]: nothing -> record<users: table<preferredLanguages: list, active: bool, birthDate: string, cleanSpeakId: string, data: record, email: string, expiry: int, firstName: string, fullName: string, imageUrl: string, insertInstant: int, lastName: string, legacyIdentifier: string, lastUpdateInstant: int, middleName: string, mobilePhone: string, parentEmail: string, phoneNumber: string, tenantId: string, timezone: string, twoFactor: record, memberships: list, registrations: list, identities: list, breachedPasswordLastCheckedInstant: int, breachedPasswordStatus: string, connectorId: string, encryptionScheme: string, factor: int, id: string, lastLoginInstant: int, password: string, passwordChangeReason: string, passwordChangeRequired: bool, passwordLastUpdateInstant: int, salt: string, uniqueUsername: string, username: string, usernameStatus: string, verified: bool, verifiedInstant: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "parentEmail" $parentEmail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/user/family/pending" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sends out an email to a parent that they need to register and create a family or need to log in and add a child to their existing family.
#
# POST /api/user/family/request
# operationId: sendFamilyRequestEmailWithId
export def "user-family-request sendFamilyRequestEmailWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --parentEmail: string
]: any -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/user/family/request")
  let body = {parentEmail: $parentEmail} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates a family with a given Id. OR Adds a user to an existing family. The family Id must be specified.
#
# PUT /api/user/family/{familyId}
# operationId: updateUserFamilyWithId
# --familyMember shape: {data?: record, insertInstant?: int, lastUpdateInstant?: int, owner?: bool, role?: "Child"|"Teen"|"Adult", userId?: string}
export def "user-family updateUserFamilyWithId" [
  familyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --familyMember: record # Models a single family member. — shape: {data?: record, insertInstant?: int, lastUpdateInstant?: int, owner?: bool, role?: "Child"|"Teen"|"Adult", userId?: string}
]: any -> record<families: table<members: list, id: string, insertInstant: int, lastUpdateInstant: int>, family: record<members: list<record>, id: string, insertInstant: int, lastUpdateInstant: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user/family/($familyId)")
  let body = {familyMember: $familyMember} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a family with the user Id in the request as the owner and sole member of the family. You can optionally specify an Id for the family, if not provided one will be generated.
#
# POST /api/user/family/{familyId}
# operationId: createFamilyWithId
# --familyMember shape: {data?: record, insertInstant?: int, lastUpdateInstant?: int, owner?: bool, role?: "Child"|"Teen"|"Adult", userId?: string}
export def "user-family createFamilyWithId" [
  familyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --familyMember: record # Models a single family member. — shape: {data?: record, insertInstant?: int, lastUpdateInstant?: int, owner?: bool, role?: "Child"|"Teen"|"Adult", userId?: string}
]: any -> record<families: table<members: list, id: string, insertInstant: int, lastUpdateInstant: int>, family: record<members: list<record>, id: string, insertInstant: int, lastUpdateInstant: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user/family/($familyId)")
  let body = {familyMember: $familyMember} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves all the members of a family by the unique Family Id.
#
# GET /api/user/family/{familyId}
# operationId: retrieveFamilyMembersByFamilyIdWithId
export def "user-family retrieveFamilyMembersByFamilyIdWithId" [
  familyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
]: nothing -> record<families: table<members: list, id: string, insertInstant: int, lastUpdateInstant: int>, family: record<members: list<record>, id: string, insertInstant: int, lastUpdateInstant: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user/family/($familyId)")
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Removes a user from the family with the given Id.
#
# DELETE /api/user/family/{familyId}/{userId}
# operationId: removeUserFromFamilyWithId
export def "user-family removeUserFromFamilyWithId" [
  familyId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
]: nothing -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user/family/($familyId)/($userId)")
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Begins the forgot password sequence, which kicks off an email to the user so that they can reset their password.
#
# POST /api/user/forgot-password
# operationId: forgotPasswordWithId
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "user-forgot-password forgotPasswordWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applicationId: string # format: uuid
  --changePasswordId: string
  --loginId: string
  --loginIdTypes: list
  --sendForgotPasswordEmail: string@bool-completer
  --sendForgotPasswordMessage: string@bool-completer
  --state: record
  --email: string
  --username: string
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<changePasswordId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/user/forgot-password")
  let body = {applicationId: $applicationId, changePasswordId: $changePasswordId, loginId: $loginId, loginIdTypes: $loginIdTypes, sendForgotPasswordEmail: $sendForgotPasswordEmail, sendForgotPasswordMessage: $sendForgotPasswordMessage, state: $state, email: $email, username: $username, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk imports users. This request performs minimal validation and runs batch inserts of users with the expectation that each user does not yet exist and each registration corresponds to an existing FusionAuth Application. This is done to increases the insert performance.  Therefore, if you encounter an error due to a database key violation, the response will likely offer a generic explanation. If you encounter an error, you may optionally enable additional validation to receive a JSON response body with specific validation errors. This will slow the request down but will allow you to identify the cause of the failure. See the validateDbConstraints request parameter.
#
# POST /api/user/import
# operationId: importUsersWithId
# --users item shape: {preferredLanguages?: list, active?: bool, birthDate?: string, cleanSpeakId?: string, data?: record, email?: string, expiry?: int, firstName?: string, fullName?: string, imageUrl?: string, insertInstant?: int, lastName?: string, legacyIdentifier?: string, lastUpdateInstant?: int, middleName?: string, mobilePhone?: string, parentEmail?: string, phoneNumber?: string, tenantId?: string, timezone?: string, twoFactor?: record, memberships?: list, registrations?: list, identities?: list, breachedPasswordLastCheckedInstant?: int, breachedPasswordStatus?: "None"|"ExactMatch"|"SubAddressMatch"|"PasswordOnly"|"CommonPassword", connectorId?: string, encryptionScheme?: string, factor?: int, id?: string, lastLoginInstant?: int, password?: string, passwordChangeReason?: "Administrative"|"Breached"|"Expired"|"Validation", passwordChangeRequired?: bool, passwordLastUpdateInstant?: int, salt?: string, uniqueUsername?: string, username?: string, usernameStatus?: "ACTIVE"|"PENDING"|"REJECTED", verified?: bool, verifiedInstant?: int}
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "user-import importUsersWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --encryptionScheme: string
  --factor: int
  --users: list # item shape: {preferredLanguages?: list, active?: bool, birthDate?: string, cleanSpeakId?: string, data?: record, email?: string, expiry?: int, firstName?: string, fullName?: string, imageUrl?: string, insertInstant?: int, lastName?: string, legacyIdentifier?: string, lastUpdateInstant?: int, middleName?: string, mobilePhone?: string, parentEmail?: string, phoneNumber?: string, tenantId?: string, timezone?: string, twoFactor?: record, memberships?: list, registrations?: list, identities?: list, breachedPasswordLastCheckedInstant?: int, breachedPasswordStatus?: "None"|"ExactMatch"|"SubAddressMatch"|"PasswordOnly"|"CommonPassword", connectorId?: string, encryptionScheme?: string, factor?: int, id?: string, lastLoginInstant?: int, password?: string, passwordChangeReason?: "Administrative"|"Breached"|"Expired"|"Validation", passwordChangeRequired?: bool, passwordLastUpdateInstant?: int, salt?: string, uniqueUsername?: string, username?: string, usernameStatus?: "ACTIVE"|"PENDING"|"REJECTED", verified?: bool, verifiedInstant?: int}
  --validateDbConstraints: string@bool-completer
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/user/import")
  let body = {encryptionScheme: $encryptionScheme, factor: $factor, users: $users, validateDbConstraints: $validateDbConstraints, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the last number of login records for a user. OR Retrieves the last number of login records.
#
# GET /api/user/recent-login
# operationId: retrieveUserRecentLogin
export def "user-recent-login retrieveUserRecentLogin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userId: string # The Id of the user.
  --offset: string # The initial record. e.g. 0 is the last login, 100 will be the 100th most recent login.
  --limit: string # (Optional, defaults to 10) The number of records to retrieve.
]: nothing -> record<logins: table<applicationName: string, location: record, loginId: string, loginIdType: record, applicationId: string, instant: int, ipAddress: string, userId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $userId "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/user/recent-login" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk imports refresh tokens. This request performs minimal validation and runs batch inserts of refresh tokens with the expectation that each token represents a user that already exists and is registered for the corresponding FusionAuth Application. This is done to increases the insert performance.  Therefore, if you encounter an error due to a database key violation, the response will likely offer a generic explanation. If you encounter an error, you may optionally enable additional validation to receive a JSON response body with specific validation errors. This will slow the request down but will allow you to identify the cause of the failure. See the validateDbConstraints request parameter.
#
# POST /api/user/refresh-token/import
# operationId: importRefreshTokensWithId
# --refreshTokens item shape: {applicationId?: string, data?: record, id?: string, insertInstant?: int, metaData?: record, startInstant?: int, tenantId?: string, token?: string, userId?: string}
export def "user-refresh-token-import importRefreshTokensWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --refreshTokens: list # item shape: {applicationId?: string, data?: record, id?: string, insertInstant?: int, metaData?: record, startInstant?: int, tenantId?: string, token?: string, userId?: string}
  --validateDbConstraints: string@bool-completer
]: any -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/user/refresh-token/import")
  let body = {refreshTokens: $refreshTokens, validateDbConstraints: $validateDbConstraints} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Registers a user for an application. If you provide the User and the UserRegistration object on this request, it will create the user as well as register them for the application. This is called a Full Registration. However, if you only provide the UserRegistration object, then the user must already exist and they will be registered for the application. The user Id can also be provided and it will either be used to look up an existing user or it will be used for the newly created User.
#
# POST /api/user/registration
# operationId: register
# --registration shape: {data?: record, preferredLanguages?: list, tokens?: record, applicationId?: string, authenticationToken?: string, cleanSpeakId?: string, id?: string, insertInstant?: int, lastLoginInstant?: int, lastUpdateInstant?: int, roles?: list, timezone?: string, username?: string, usernameStatus?: "ACTIVE"|"PENDING"|"REJECTED", verified?: bool, verifiedInstant?: int}
# --user shape: {preferredLanguages?: list, active?: bool, birthDate?: string, cleanSpeakId?: string, data?: record, email?: string, expiry?: int, firstName?: string, fullName?: string, imageUrl?: string, insertInstant?: int, lastName?: string, legacyIdentifier?: string, lastUpdateInstant?: int, middleName?: string, mobilePhone?: string, parentEmail?: string, phoneNumber?: string, tenantId?: string, timezone?: string, twoFactor?: record, memberships?: list, registrations?: list, identities?: list, breachedPasswordLastCheckedInstant?: int, breachedPasswordStatus?: "None"|"ExactMatch"|"SubAddressMatch"|"PasswordOnly"|"CommonPassword", connectorId?: string, encryptionScheme?: string, factor?: int, id?: string, lastLoginInstant?: int, password?: string, passwordChangeReason?: "Administrative"|"Breached"|"Expired"|"Validation", passwordChangeRequired?: bool, passwordLastUpdateInstant?: int, salt?: string, uniqueUsername?: string, username?: string, usernameStatus?: "ACTIVE"|"PENDING"|"REJECTED", verified?: bool, verifiedInstant?: int}
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "user-registration register" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --disableDomainBlock: string@bool-completer
  --generateAuthenticationToken: string@bool-completer
  --registration: record # User registration information for a single application. — shape: {data?: record, preferredLanguages?: list, tokens?: record, applicationId?: string, authenticationToken?: string, cleanSpeakId?: string, id?: string, insertInstant?: int, lastLoginInstant?: int, lastUpdateInstant?: int, roles?: list, timezone?: string, username?: string, usernameStatus?: "ACTIVE"|"PENDING"|"REJECTED", verified?: bool, verifiedInstant?: int}
  --sendSetPasswordEmail: string@bool-completer
  --sendSetPasswordIdentityType: string@sendSetPasswordIdentityType-completer # Used to indicate which identity type a password "request" might go to. It could be  used for send set passwords or send password resets.
  --skipRegistrationVerification: string@bool-completer
  --skipVerification: string@bool-completer
  --user: record # The public, global view of a User. This object contains all global information about the user including birthdate, registration information  preferred languages, global attributes, etc. — shape: {preferredLanguages?: list, active?: bool, birthDate?: string, cleanSpeakId?: string, data?: record, email?: string, expiry?: int, firstName?: string, fullName?: string, imageUrl?: string, insertInstant?: int, lastName?: string, legacyIdentifier?: string, lastUpdateInstant?: int, middleName?: string, mobilePhone?: string, parentEmail?: string, phoneNumber?: string, tenantId?: string, timezone?: string, twoFactor?: record, memberships?: list, registrations?: list, identities?: list, breachedPasswordLastCheckedInstant?: int, breachedPasswordStatus?: "None"|"ExactMatch"|"SubAddressMatch"|"PasswordOnly"|"CommonPassword", connectorId?: string, encryptionScheme?: string, factor?: int, id?: string, lastLoginInstant?: int, password?: string, passwordChangeReason?: "Administrative"|"Breached"|"Expired"|"Validation", passwordChangeRequired?: bool, passwordLastUpdateInstant?: int, salt?: string, uniqueUsername?: string, username?: string, usernameStatus?: "ACTIVE"|"PENDING"|"REJECTED", verified?: bool, verifiedInstant?: int}
  --verificationIds: list
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<refreshToken: string, refreshTokenId: string, registration: record<data: record, preferredLanguages: list<string>, tokens: record, applicationId: string, authenticationToken: string, cleanSpeakId: string, id: string, insertInstant: int, lastLoginInstant: int, lastUpdateInstant: int, roles: list<any>, timezone: string, username: string, usernameStatus: string, verified: bool, verifiedInstant: int>, registrationVerificationId: string, registrationVerificationOneTimeCode: string, token: string, tokenExpirationInstant: int, user: record<preferredLanguages: list<string>, active: bool, birthDate: string, cleanSpeakId: string, data: record, email: string, expiry: int, firstName: string, fullName: string, imageUrl: string, insertInstant: int, lastName: string, legacyIdentifier: string, lastUpdateInstant: int, middleName: string, mobilePhone: string, parentEmail: string, phoneNumber: string, tenantId: string, timezone: string, twoFactor: record<methods: list, recoveryCodes: list>, memberships: list<record>, registrations: list<record>, identities: list<record>, breachedPasswordLastCheckedInstant: int, breachedPasswordStatus: string, connectorId: string, encryptionScheme: string, factor: int, id: string, lastLoginInstant: int, password: string, passwordChangeReason: string, passwordChangeRequired: bool, passwordLastUpdateInstant: int, salt: string, uniqueUsername: string, username: string, usernameStatus: string, verified: bool, verifiedInstant: int>, verificationIds: table<id: string, oneTimeCode: string, type: record, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/user/registration")
  let body = {disableDomainBlock: $disableDomainBlock, generateAuthenticationToken: $generateAuthenticationToken, registration: $registration, sendSetPasswordEmail: $sendSetPasswordEmail, sendSetPasswordIdentityType: $sendSetPasswordIdentityType, skipRegistrationVerification: $skipRegistrationVerification, skipVerification: $skipVerification, user: $user, verificationIds: $verificationIds, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates, via PATCH, the registration for the user with the given Id and the application defined in the request.
#
# PATCH /api/user/registration/{userId}
# operationId: patchRegistrationWithId
# --registration shape: {data?: record, preferredLanguages?: list, tokens?: record, applicationId?: string, authenticationToken?: string, cleanSpeakId?: string, id?: string, insertInstant?: int, lastLoginInstant?: int, lastUpdateInstant?: int, roles?: list, timezone?: string, username?: string, usernameStatus?: "ACTIVE"|"PENDING"|"REJECTED", verified?: bool, verifiedInstant?: int}
# --user shape: {preferredLanguages?: list, active?: bool, birthDate?: string, cleanSpeakId?: string, data?: record, email?: string, expiry?: int, firstName?: string, fullName?: string, imageUrl?: string, insertInstant?: int, lastName?: string, legacyIdentifier?: string, lastUpdateInstant?: int, middleName?: string, mobilePhone?: string, parentEmail?: string, phoneNumber?: string, tenantId?: string, timezone?: string, twoFactor?: record, memberships?: list, registrations?: list, identities?: list, breachedPasswordLastCheckedInstant?: int, breachedPasswordStatus?: "None"|"ExactMatch"|"SubAddressMatch"|"PasswordOnly"|"CommonPassword", connectorId?: string, encryptionScheme?: string, factor?: int, id?: string, lastLoginInstant?: int, password?: string, passwordChangeReason?: "Administrative"|"Breached"|"Expired"|"Validation", passwordChangeRequired?: bool, passwordLastUpdateInstant?: int, salt?: string, uniqueUsername?: string, username?: string, usernameStatus?: "ACTIVE"|"PENDING"|"REJECTED", verified?: bool, verifiedInstant?: int}
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "user-registration patch" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --disableDomainBlock: string@bool-completer
  --generateAuthenticationToken: string@bool-completer
  --registration: record # User registration information for a single application. — shape: {data?: record, preferredLanguages?: list, tokens?: record, applicationId?: string, authenticationToken?: string, cleanSpeakId?: string, id?: string, insertInstant?: int, lastLoginInstant?: int, lastUpdateInstant?: int, roles?: list, timezone?: string, username?: string, usernameStatus?: "ACTIVE"|"PENDING"|"REJECTED", verified?: bool, verifiedInstant?: int}
  --sendSetPasswordEmail: string@bool-completer
  --sendSetPasswordIdentityType: string@sendSetPasswordIdentityType-completer # Used to indicate which identity type a password "request" might go to. It could be  used for send set passwords or send password resets.
  --skipRegistrationVerification: string@bool-completer
  --skipVerification: string@bool-completer
  --user: record # The public, global view of a User. This object contains all global information about the user including birthdate, registration information  preferred languages, global attributes, etc. — shape: {preferredLanguages?: list, active?: bool, birthDate?: string, cleanSpeakId?: string, data?: record, email?: string, expiry?: int, firstName?: string, fullName?: string, imageUrl?: string, insertInstant?: int, lastName?: string, legacyIdentifier?: string, lastUpdateInstant?: int, middleName?: string, mobilePhone?: string, parentEmail?: string, phoneNumber?: string, tenantId?: string, timezone?: string, twoFactor?: record, memberships?: list, registrations?: list, identities?: list, breachedPasswordLastCheckedInstant?: int, breachedPasswordStatus?: "None"|"ExactMatch"|"SubAddressMatch"|"PasswordOnly"|"CommonPassword", connectorId?: string, encryptionScheme?: string, factor?: int, id?: string, lastLoginInstant?: int, password?: string, passwordChangeReason?: "Administrative"|"Breached"|"Expired"|"Validation", passwordChangeRequired?: bool, passwordLastUpdateInstant?: int, salt?: string, uniqueUsername?: string, username?: string, usernameStatus?: "ACTIVE"|"PENDING"|"REJECTED", verified?: bool, verifiedInstant?: int}
  --verificationIds: list
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<refreshToken: string, refreshTokenId: string, registration: record<data: record, preferredLanguages: list<string>, tokens: record, applicationId: string, authenticationToken: string, cleanSpeakId: string, id: string, insertInstant: int, lastLoginInstant: int, lastUpdateInstant: int, roles: list<any>, timezone: string, username: string, usernameStatus: string, verified: bool, verifiedInstant: int>, registrationVerificationId: string, registrationVerificationOneTimeCode: string, token: string, tokenExpirationInstant: int, user: record<preferredLanguages: list<string>, active: bool, birthDate: string, cleanSpeakId: string, data: record, email: string, expiry: int, firstName: string, fullName: string, imageUrl: string, insertInstant: int, lastName: string, legacyIdentifier: string, lastUpdateInstant: int, middleName: string, mobilePhone: string, parentEmail: string, phoneNumber: string, tenantId: string, timezone: string, twoFactor: record<methods: list, recoveryCodes: list>, memberships: list<record>, registrations: list<record>, identities: list<record>, breachedPasswordLastCheckedInstant: int, breachedPasswordStatus: string, connectorId: string, encryptionScheme: string, factor: int, id: string, lastLoginInstant: int, password: string, passwordChangeReason: string, passwordChangeRequired: bool, passwordLastUpdateInstant: int, salt: string, uniqueUsername: string, username: string, usernameStatus: string, verified: bool, verifiedInstant: int>, verificationIds: table<id: string, oneTimeCode: string, type: record, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user/registration/($userId)")
  let body = {disableDomainBlock: $disableDomainBlock, generateAuthenticationToken: $generateAuthenticationToken, registration: $registration, sendSetPasswordEmail: $sendSetPasswordEmail, sendSetPasswordIdentityType: $sendSetPasswordIdentityType, skipRegistrationVerification: $skipRegistrationVerification, skipVerification: $skipVerification, user: $user, verificationIds: $verificationIds, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Registers a user for an application. If you provide the User and the UserRegistration object on this request, it will create the user as well as register them for the application. This is called a Full Registration. However, if you only provide the UserRegistration object, then the user must already exist and they will be registered for the application. The user Id can also be provided and it will either be used to look up an existing user or it will be used for the newly created User.
#
# POST /api/user/registration/{userId}
# operationId: registerWithId
# --registration shape: {data?: record, preferredLanguages?: list, tokens?: record, applicationId?: string, authenticationToken?: string, cleanSpeakId?: string, id?: string, insertInstant?: int, lastLoginInstant?: int, lastUpdateInstant?: int, roles?: list, timezone?: string, username?: string, usernameStatus?: "ACTIVE"|"PENDING"|"REJECTED", verified?: bool, verifiedInstant?: int}
# --user shape: {preferredLanguages?: list, active?: bool, birthDate?: string, cleanSpeakId?: string, data?: record, email?: string, expiry?: int, firstName?: string, fullName?: string, imageUrl?: string, insertInstant?: int, lastName?: string, legacyIdentifier?: string, lastUpdateInstant?: int, middleName?: string, mobilePhone?: string, parentEmail?: string, phoneNumber?: string, tenantId?: string, timezone?: string, twoFactor?: record, memberships?: list, registrations?: list, identities?: list, breachedPasswordLastCheckedInstant?: int, breachedPasswordStatus?: "None"|"ExactMatch"|"SubAddressMatch"|"PasswordOnly"|"CommonPassword", connectorId?: string, encryptionScheme?: string, factor?: int, id?: string, lastLoginInstant?: int, password?: string, passwordChangeReason?: "Administrative"|"Breached"|"Expired"|"Validation", passwordChangeRequired?: bool, passwordLastUpdateInstant?: int, salt?: string, uniqueUsername?: string, username?: string, usernameStatus?: "ACTIVE"|"PENDING"|"REJECTED", verified?: bool, verifiedInstant?: int}
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "user-registration registerWithId" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --disableDomainBlock: string@bool-completer
  --generateAuthenticationToken: string@bool-completer
  --registration: record # User registration information for a single application. — shape: {data?: record, preferredLanguages?: list, tokens?: record, applicationId?: string, authenticationToken?: string, cleanSpeakId?: string, id?: string, insertInstant?: int, lastLoginInstant?: int, lastUpdateInstant?: int, roles?: list, timezone?: string, username?: string, usernameStatus?: "ACTIVE"|"PENDING"|"REJECTED", verified?: bool, verifiedInstant?: int}
  --sendSetPasswordEmail: string@bool-completer
  --sendSetPasswordIdentityType: string@sendSetPasswordIdentityType-completer # Used to indicate which identity type a password "request" might go to. It could be  used for send set passwords or send password resets.
  --skipRegistrationVerification: string@bool-completer
  --skipVerification: string@bool-completer
  --user: record # The public, global view of a User. This object contains all global information about the user including birthdate, registration information  preferred languages, global attributes, etc. — shape: {preferredLanguages?: list, active?: bool, birthDate?: string, cleanSpeakId?: string, data?: record, email?: string, expiry?: int, firstName?: string, fullName?: string, imageUrl?: string, insertInstant?: int, lastName?: string, legacyIdentifier?: string, lastUpdateInstant?: int, middleName?: string, mobilePhone?: string, parentEmail?: string, phoneNumber?: string, tenantId?: string, timezone?: string, twoFactor?: record, memberships?: list, registrations?: list, identities?: list, breachedPasswordLastCheckedInstant?: int, breachedPasswordStatus?: "None"|"ExactMatch"|"SubAddressMatch"|"PasswordOnly"|"CommonPassword", connectorId?: string, encryptionScheme?: string, factor?: int, id?: string, lastLoginInstant?: int, password?: string, passwordChangeReason?: "Administrative"|"Breached"|"Expired"|"Validation", passwordChangeRequired?: bool, passwordLastUpdateInstant?: int, salt?: string, uniqueUsername?: string, username?: string, usernameStatus?: "ACTIVE"|"PENDING"|"REJECTED", verified?: bool, verifiedInstant?: int}
  --verificationIds: list
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<refreshToken: string, refreshTokenId: string, registration: record<data: record, preferredLanguages: list<string>, tokens: record, applicationId: string, authenticationToken: string, cleanSpeakId: string, id: string, insertInstant: int, lastLoginInstant: int, lastUpdateInstant: int, roles: list<any>, timezone: string, username: string, usernameStatus: string, verified: bool, verifiedInstant: int>, registrationVerificationId: string, registrationVerificationOneTimeCode: string, token: string, tokenExpirationInstant: int, user: record<preferredLanguages: list<string>, active: bool, birthDate: string, cleanSpeakId: string, data: record, email: string, expiry: int, firstName: string, fullName: string, imageUrl: string, insertInstant: int, lastName: string, legacyIdentifier: string, lastUpdateInstant: int, middleName: string, mobilePhone: string, parentEmail: string, phoneNumber: string, tenantId: string, timezone: string, twoFactor: record<methods: list, recoveryCodes: list>, memberships: list<record>, registrations: list<record>, identities: list<record>, breachedPasswordLastCheckedInstant: int, breachedPasswordStatus: string, connectorId: string, encryptionScheme: string, factor: int, id: string, lastLoginInstant: int, password: string, passwordChangeReason: string, passwordChangeRequired: bool, passwordLastUpdateInstant: int, salt: string, uniqueUsername: string, username: string, usernameStatus: string, verified: bool, verifiedInstant: int>, verificationIds: table<id: string, oneTimeCode: string, type: record, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user/registration/($userId)")
  let body = {disableDomainBlock: $disableDomainBlock, generateAuthenticationToken: $generateAuthenticationToken, registration: $registration, sendSetPasswordEmail: $sendSetPasswordEmail, sendSetPasswordIdentityType: $sendSetPasswordIdentityType, skipRegistrationVerification: $skipRegistrationVerification, skipVerification: $skipVerification, user: $user, verificationIds: $verificationIds, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates the registration for the user with the given Id and the application defined in the request.
#
# PUT /api/user/registration/{userId}
# operationId: updateRegistrationWithId
# --registration shape: {data?: record, preferredLanguages?: list, tokens?: record, applicationId?: string, authenticationToken?: string, cleanSpeakId?: string, id?: string, insertInstant?: int, lastLoginInstant?: int, lastUpdateInstant?: int, roles?: list, timezone?: string, username?: string, usernameStatus?: "ACTIVE"|"PENDING"|"REJECTED", verified?: bool, verifiedInstant?: int}
# --user shape: {preferredLanguages?: list, active?: bool, birthDate?: string, cleanSpeakId?: string, data?: record, email?: string, expiry?: int, firstName?: string, fullName?: string, imageUrl?: string, insertInstant?: int, lastName?: string, legacyIdentifier?: string, lastUpdateInstant?: int, middleName?: string, mobilePhone?: string, parentEmail?: string, phoneNumber?: string, tenantId?: string, timezone?: string, twoFactor?: record, memberships?: list, registrations?: list, identities?: list, breachedPasswordLastCheckedInstant?: int, breachedPasswordStatus?: "None"|"ExactMatch"|"SubAddressMatch"|"PasswordOnly"|"CommonPassword", connectorId?: string, encryptionScheme?: string, factor?: int, id?: string, lastLoginInstant?: int, password?: string, passwordChangeReason?: "Administrative"|"Breached"|"Expired"|"Validation", passwordChangeRequired?: bool, passwordLastUpdateInstant?: int, salt?: string, uniqueUsername?: string, username?: string, usernameStatus?: "ACTIVE"|"PENDING"|"REJECTED", verified?: bool, verifiedInstant?: int}
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "user-registration updateRegistrationWithId" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --disableDomainBlock: string@bool-completer
  --generateAuthenticationToken: string@bool-completer
  --registration: record # User registration information for a single application. — shape: {data?: record, preferredLanguages?: list, tokens?: record, applicationId?: string, authenticationToken?: string, cleanSpeakId?: string, id?: string, insertInstant?: int, lastLoginInstant?: int, lastUpdateInstant?: int, roles?: list, timezone?: string, username?: string, usernameStatus?: "ACTIVE"|"PENDING"|"REJECTED", verified?: bool, verifiedInstant?: int}
  --sendSetPasswordEmail: string@bool-completer
  --sendSetPasswordIdentityType: string@sendSetPasswordIdentityType-completer # Used to indicate which identity type a password "request" might go to. It could be  used for send set passwords or send password resets.
  --skipRegistrationVerification: string@bool-completer
  --skipVerification: string@bool-completer
  --user: record # The public, global view of a User. This object contains all global information about the user including birthdate, registration information  preferred languages, global attributes, etc. — shape: {preferredLanguages?: list, active?: bool, birthDate?: string, cleanSpeakId?: string, data?: record, email?: string, expiry?: int, firstName?: string, fullName?: string, imageUrl?: string, insertInstant?: int, lastName?: string, legacyIdentifier?: string, lastUpdateInstant?: int, middleName?: string, mobilePhone?: string, parentEmail?: string, phoneNumber?: string, tenantId?: string, timezone?: string, twoFactor?: record, memberships?: list, registrations?: list, identities?: list, breachedPasswordLastCheckedInstant?: int, breachedPasswordStatus?: "None"|"ExactMatch"|"SubAddressMatch"|"PasswordOnly"|"CommonPassword", connectorId?: string, encryptionScheme?: string, factor?: int, id?: string, lastLoginInstant?: int, password?: string, passwordChangeReason?: "Administrative"|"Breached"|"Expired"|"Validation", passwordChangeRequired?: bool, passwordLastUpdateInstant?: int, salt?: string, uniqueUsername?: string, username?: string, usernameStatus?: "ACTIVE"|"PENDING"|"REJECTED", verified?: bool, verifiedInstant?: int}
  --verificationIds: list
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<refreshToken: string, refreshTokenId: string, registration: record<data: record, preferredLanguages: list<string>, tokens: record, applicationId: string, authenticationToken: string, cleanSpeakId: string, id: string, insertInstant: int, lastLoginInstant: int, lastUpdateInstant: int, roles: list<any>, timezone: string, username: string, usernameStatus: string, verified: bool, verifiedInstant: int>, registrationVerificationId: string, registrationVerificationOneTimeCode: string, token: string, tokenExpirationInstant: int, user: record<preferredLanguages: list<string>, active: bool, birthDate: string, cleanSpeakId: string, data: record, email: string, expiry: int, firstName: string, fullName: string, imageUrl: string, insertInstant: int, lastName: string, legacyIdentifier: string, lastUpdateInstant: int, middleName: string, mobilePhone: string, parentEmail: string, phoneNumber: string, tenantId: string, timezone: string, twoFactor: record<methods: list, recoveryCodes: list>, memberships: list<record>, registrations: list<record>, identities: list<record>, breachedPasswordLastCheckedInstant: int, breachedPasswordStatus: string, connectorId: string, encryptionScheme: string, factor: int, id: string, lastLoginInstant: int, password: string, passwordChangeReason: string, passwordChangeRequired: bool, passwordLastUpdateInstant: int, salt: string, uniqueUsername: string, username: string, usernameStatus: string, verified: bool, verifiedInstant: int>, verificationIds: table<id: string, oneTimeCode: string, type: record, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user/registration/($userId)")
  let body = {disableDomainBlock: $disableDomainBlock, generateAuthenticationToken: $generateAuthenticationToken, registration: $registration, sendSetPasswordEmail: $sendSetPasswordEmail, sendSetPasswordIdentityType: $sendSetPasswordIdentityType, skipRegistrationVerification: $skipRegistrationVerification, skipVerification: $skipVerification, user: $user, verificationIds: $verificationIds, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the user registration for the given user and application along with the given JSON body that contains the event information. OR Deletes the user registration for the given user and application.
#
# DELETE /api/user/registration/{userId}/{applicationId}
# operationId: deleteUserRegistrationWithId
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "user-registration delete" [
  userId: string
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user/registration/($userId)/($applicationId)")
  let body = {eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the user registration for the user with the given Id and the given application Id.
#
# GET /api/user/registration/{userId}/{applicationId}
# operationId: retrieveRegistrationWithId
export def "user-registration retrieveRegistrationWithId" [
  userId: string
  applicationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
]: nothing -> record<refreshToken: string, refreshTokenId: string, registration: record<data: record, preferredLanguages: list<string>, tokens: record, applicationId: string, authenticationToken: string, cleanSpeakId: string, id: string, insertInstant: int, lastLoginInstant: int, lastUpdateInstant: int, roles: list<any>, timezone: string, username: string, usernameStatus: string, verified: bool, verifiedInstant: int>, registrationVerificationId: string, registrationVerificationOneTimeCode: string, token: string, tokenExpirationInstant: int, user: record<preferredLanguages: list<string>, active: bool, birthDate: string, cleanSpeakId: string, data: record, email: string, expiry: int, firstName: string, fullName: string, imageUrl: string, insertInstant: int, lastName: string, legacyIdentifier: string, lastUpdateInstant: int, middleName: string, mobilePhone: string, parentEmail: string, phoneNumber: string, tenantId: string, timezone: string, twoFactor: record<methods: list, recoveryCodes: list>, memberships: list<record>, registrations: list<record>, identities: list<record>, breachedPasswordLastCheckedInstant: int, breachedPasswordStatus: string, connectorId: string, encryptionScheme: string, factor: int, id: string, lastLoginInstant: int, password: string, passwordChangeReason: string, passwordChangeRequired: bool, passwordLastUpdateInstant: int, salt: string, uniqueUsername: string, username: string, usernameStatus: string, verified: bool, verifiedInstant: int>, verificationIds: table<id: string, oneTimeCode: string, type: record, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user/registration/($userId)/($applicationId)")
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the users for the given Ids. If any Id is invalid, it is ignored.
#
# GET /api/user/search
# operationId: searchUsersByIdsWithId
export def "user-search searchUsersByIdsWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ids: string # The user Ids to search for.
]: nothing -> record<total: int, nextResults: string, users: table<preferredLanguages: list, active: bool, birthDate: string, cleanSpeakId: string, data: record, email: string, expiry: int, firstName: string, fullName: string, imageUrl: string, insertInstant: int, lastName: string, legacyIdentifier: string, lastUpdateInstant: int, middleName: string, mobilePhone: string, parentEmail: string, phoneNumber: string, tenantId: string, timezone: string, twoFactor: record, memberships: list, registrations: list, identities: list, breachedPasswordLastCheckedInstant: int, breachedPasswordStatus: string, connectorId: string, encryptionScheme: string, factor: int, id: string, lastLoginInstant: int, password: string, passwordChangeReason: string, passwordChangeRequired: bool, passwordLastUpdateInstant: int, salt: string, uniqueUsername: string, username: string, usernameStatus: string, verified: bool, verifiedInstant: int>, expandable: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/user/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the users for the given search criteria and pagination.
#
# POST /api/user/search
# operationId: searchUsersByQueryWithId
# --search shape: {accurateTotal?: bool, ids?: list, nextResults?: string, query?: string, queryString?: string, sortFields?: list}
export def "user-search searchUsersByQueryWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: record # This class is the user query. It provides a build pattern as well as public fields for use on forms and in actions. — shape: {accurateTotal?: bool, ids?: list, nextResults?: string, query?: string, queryString?: string, sortFields?: list}
  --expand: list
]: any -> record<total: int, nextResults: string, users: table<preferredLanguages: list, active: bool, birthDate: string, cleanSpeakId: string, data: record, email: string, expiry: int, firstName: string, fullName: string, imageUrl: string, insertInstant: int, lastName: string, legacyIdentifier: string, lastUpdateInstant: int, middleName: string, mobilePhone: string, parentEmail: string, phoneNumber: string, tenantId: string, timezone: string, twoFactor: record, memberships: list, registrations: list, identities: list, breachedPasswordLastCheckedInstant: int, breachedPasswordStatus: string, connectorId: string, encryptionScheme: string, factor: int, id: string, lastLoginInstant: int, password: string, passwordChangeReason: string, passwordChangeRequired: bool, passwordLastUpdateInstant: int, salt: string, uniqueUsername: string, username: string, usernameStatus: string, verified: bool, verifiedInstant: int>, expandable: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/user/search")
  let body = {search: $search, expand: $expand} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate two-factor recovery codes for a user. Generating two-factor recovery codes will invalidate any existing recovery codes.
#
# POST /api/user/two-factor/recovery-code/{userId}
# operationId: generateTwoFactorRecoveryCodesWithId
export def "user-two-factor-recovery-code generateTwoFactorRecoveryCodesWithId" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<recoveryCodes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user/two-factor/recovery-code/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve two-factor recovery codes for a user.
#
# GET /api/user/two-factor/recovery-code/{userId}
# operationId: retrieveTwoFactorRecoveryCodesWithId
export def "user-two-factor-recovery-code retrieveTwoFactorRecoveryCodesWithId" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<recoveryCodes: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user/two-factor/recovery-code/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable two-factor authentication for a user using a JSON body rather than URL parameters. OR Disable two-factor authentication for a user.
#
# DELETE /api/user/two-factor/{userId}
# operationId: deleteUserTwoFactorWithId
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "user-two-factor delete" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --methodId: string # The two-factor method identifier you wish to disable
  --code: string # The two-factor code used verify the the caller knows the two-factor secret.
  --applicationId: string # format: uuid
  --code: string
  --methodId: string
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "methodId" $methodId "scalar") (serialize-qp "code" $code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/user/two-factor/($userId)" $qp)
  let body = {applicationId: $applicationId, code: $code, methodId: $methodId, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Enable two-factor authentication for a user.
#
# POST /api/user/two-factor/{userId}
# operationId: enableTwoFactorWithId
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "user-two-factor enableTwoFactorWithId" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applicationId: string # format: uuid
  --authenticatorId: string
  --code: string
  --email: string
  --method: string
  --mobilePhone: string
  --secret: string
  --secretBase32Encoded: string
  --twoFactorId: string
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<code: string, recoveryCodes: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user/two-factor/($userId)")
  let body = {applicationId: $applicationId, authenticatorId: $authenticatorId, code: $code, email: $email, method: $method, mobilePhone: $mobilePhone, secret: $secret, secretBase32Encoded: $secretBase32Encoded, twoFactorId: $twoFactorId, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Re-sends the verification email to the user. If the Application has configured a specific email template this will be used instead of the tenant configuration. OR Re-sends the verification email to the user. OR Generate a new Email Verification Id to be used with the Verify Email API. This API will not attempt to send an email to the User. This API may be used to collect the verificationId for use with a third party system.
#
# PUT /api/user/verify-email
# operationId: updateUserVerifyEmail
export def "user-verify-email updateUserVerifyEmail" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applicationId: string # The unique Application Id to used to resolve an application specific email template.
  --email: string # The email address of the user that needs a new verification email.
  --sendVerifyEmail: string
]: nothing -> record<oneTimeCode: string, verificationId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "applicationId" $applicationId "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "sendVerifyEmail" $sendVerifyEmail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/user/verify-email" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Administratively verify a user's email address. Use this method to bypass email verification for the user.  The request body will contain the userId to be verified. An API key is required when sending the userId in the request body. OR Confirms a user's email address.   The request body will contain the verificationId. You may also be required to send a one-time use code based upon your configuration. When  the tenant is configured to gate a user until their email address is verified, this procedures requires two values instead of one.  The verificationId is a high entropy value and the one-time use code is a low entropy value that is easily entered in a user interactive form. The  two values together are able to confirm a user's email address and mark the user's email address as verified.
#
# POST /api/user/verify-email
# operationId: createUserVerifyEmail
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "user-verify-email createUserVerifyEmail" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --oneTimeCode: string
  --userId: string # format: uuid
  --verificationId: string
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/user/verify-email")
  let body = {oneTimeCode: $oneTimeCode, userId: $userId, verificationId: $verificationId, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Re-sends the application registration verification email to the user. OR Generate a new Application Registration Verification Id to be used with the Verify Registration API. This API will not attempt to send an email to the User. This API may be used to collect the verificationId for use with a third party system.
#
# PUT /api/user/verify-registration
# operationId: updateUserVerifyRegistration
export def "user-verify-registration updateUserVerifyRegistration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # The email address of the user that needs a new verification email.
  --applicationId: string # The Id of the application to be verified.
  --sendVerifyPasswordEmail: string
]: nothing -> record<oneTimeCode: string, verificationId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "applicationId" $applicationId "scalar") (serialize-qp "sendVerifyPasswordEmail" $sendVerifyPasswordEmail "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/user/verify-registration" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Confirms a user's registration.   The request body will contain the verificationId. You may also be required to send a one-time use code based upon your configuration. When  the application is configured to gate a user until their registration is verified, this procedures requires two values instead of one.  The verificationId is a high entropy value and the one-time use code is a low entropy value that is easily entered in a user interactive form. The  two values together are able to confirm a user's registration and mark the user's registration as verified.
#
# POST /api/user/verify-registration
# operationId: verifyUserRegistrationWithId
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "user-verify-registration verifyUserRegistrationWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --oneTimeCode: string
  --verificationId: string
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/user/verify-registration")
  let body = {oneTimeCode: $oneTimeCode, verificationId: $verificationId, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a user. You can optionally specify an Id for the user, if not provided one will be generated.
#
# POST /api/user/{userId}
# operationId: createUserWithId
# --user shape: {preferredLanguages?: list, active?: bool, birthDate?: string, cleanSpeakId?: string, data?: record, email?: string, expiry?: int, firstName?: string, fullName?: string, imageUrl?: string, insertInstant?: int, lastName?: string, legacyIdentifier?: string, lastUpdateInstant?: int, middleName?: string, mobilePhone?: string, parentEmail?: string, phoneNumber?: string, tenantId?: string, timezone?: string, twoFactor?: record, memberships?: list, registrations?: list, identities?: list, breachedPasswordLastCheckedInstant?: int, breachedPasswordStatus?: "None"|"ExactMatch"|"SubAddressMatch"|"PasswordOnly"|"CommonPassword", connectorId?: string, encryptionScheme?: string, factor?: int, id?: string, lastLoginInstant?: int, password?: string, passwordChangeReason?: "Administrative"|"Breached"|"Expired"|"Validation", passwordChangeRequired?: bool, passwordLastUpdateInstant?: int, salt?: string, uniqueUsername?: string, username?: string, usernameStatus?: "ACTIVE"|"PENDING"|"REJECTED", verified?: bool, verifiedInstant?: int}
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "user createUserWithId" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --applicationId: string # format: uuid
  --currentPassword: string
  --disableDomainBlock: string@bool-completer
  --sendSetPasswordEmail: string@bool-completer
  --sendSetPasswordIdentityType: string@sendSetPasswordIdentityType-completer # Used to indicate which identity type a password "request" might go to. It could be  used for send set passwords or send password resets.
  --skipVerification: string@bool-completer
  --user: record # The public, global view of a User. This object contains all global information about the user including birthdate, registration information  preferred languages, global attributes, etc. — shape: {preferredLanguages?: list, active?: bool, birthDate?: string, cleanSpeakId?: string, data?: record, email?: string, expiry?: int, firstName?: string, fullName?: string, imageUrl?: string, insertInstant?: int, lastName?: string, legacyIdentifier?: string, lastUpdateInstant?: int, middleName?: string, mobilePhone?: string, parentEmail?: string, phoneNumber?: string, tenantId?: string, timezone?: string, twoFactor?: record, memberships?: list, registrations?: list, identities?: list, breachedPasswordLastCheckedInstant?: int, breachedPasswordStatus?: "None"|"ExactMatch"|"SubAddressMatch"|"PasswordOnly"|"CommonPassword", connectorId?: string, encryptionScheme?: string, factor?: int, id?: string, lastLoginInstant?: int, password?: string, passwordChangeReason?: "Administrative"|"Breached"|"Expired"|"Validation", passwordChangeRequired?: bool, passwordLastUpdateInstant?: int, salt?: string, uniqueUsername?: string, username?: string, usernameStatus?: "ACTIVE"|"PENDING"|"REJECTED", verified?: bool, verifiedInstant?: int}
  --verificationIds: list
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<emailVerificationId: string, emailVerificationOneTimeCode: string, registrationVerificationIds: record, registrationVerificationOneTimeCodes: record, token: string, tokenExpirationInstant: int, user: record<preferredLanguages: list<string>, active: bool, birthDate: string, cleanSpeakId: string, data: record, email: string, expiry: int, firstName: string, fullName: string, imageUrl: string, insertInstant: int, lastName: string, legacyIdentifier: string, lastUpdateInstant: int, middleName: string, mobilePhone: string, parentEmail: string, phoneNumber: string, tenantId: string, timezone: string, twoFactor: record<methods: list, recoveryCodes: list>, memberships: list<record>, registrations: list<record>, identities: list<record>, breachedPasswordLastCheckedInstant: int, breachedPasswordStatus: string, connectorId: string, encryptionScheme: string, factor: int, id: string, lastLoginInstant: int, password: string, passwordChangeReason: string, passwordChangeRequired: bool, passwordLastUpdateInstant: int, salt: string, uniqueUsername: string, username: string, usernameStatus: string, verified: bool, verifiedInstant: int>, verificationIds: table<id: string, oneTimeCode: string, type: record, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user/($userId)")
  let body = {applicationId: $applicationId, currentPassword: $currentPassword, disableDomainBlock: $disableDomainBlock, sendSetPasswordEmail: $sendSetPasswordEmail, sendSetPasswordIdentityType: $sendSetPasswordIdentityType, skipVerification: $skipVerification, user: $user, verificationIds: $verificationIds, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the user based on the given request (sent to the API as JSON). This permanently deletes all information, metrics, reports and data associated with the user. OR Deletes the user for the given Id. This permanently deletes all information, metrics, reports and data associated with the user. OR Deactivates the user with the given Id.
#
# DELETE /api/user/{userId}
# operationId: deleteUserWithId
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "user delete" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --hardDelete: string
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --hardDelete: string@bool-completer
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hardDelete" $hardDelete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/user/($userId)" $qp)
  let body = {hardDelete: $hardDelete, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates, via PATCH, the user with the given Id.
#
# PATCH /api/user/{userId}
# operationId: patchUserWithId
# --user shape: {preferredLanguages?: list, active?: bool, birthDate?: string, cleanSpeakId?: string, data?: record, email?: string, expiry?: int, firstName?: string, fullName?: string, imageUrl?: string, insertInstant?: int, lastName?: string, legacyIdentifier?: string, lastUpdateInstant?: int, middleName?: string, mobilePhone?: string, parentEmail?: string, phoneNumber?: string, tenantId?: string, timezone?: string, twoFactor?: record, memberships?: list, registrations?: list, identities?: list, breachedPasswordLastCheckedInstant?: int, breachedPasswordStatus?: "None"|"ExactMatch"|"SubAddressMatch"|"PasswordOnly"|"CommonPassword", connectorId?: string, encryptionScheme?: string, factor?: int, id?: string, lastLoginInstant?: int, password?: string, passwordChangeReason?: "Administrative"|"Breached"|"Expired"|"Validation", passwordChangeRequired?: bool, passwordLastUpdateInstant?: int, salt?: string, uniqueUsername?: string, username?: string, usernameStatus?: "ACTIVE"|"PENDING"|"REJECTED", verified?: bool, verifiedInstant?: int}
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "user patch" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --applicationId: string # format: uuid
  --currentPassword: string
  --disableDomainBlock: string@bool-completer
  --sendSetPasswordEmail: string@bool-completer
  --sendSetPasswordIdentityType: string@sendSetPasswordIdentityType-completer # Used to indicate which identity type a password "request" might go to. It could be  used for send set passwords or send password resets.
  --skipVerification: string@bool-completer
  --user: record # The public, global view of a User. This object contains all global information about the user including birthdate, registration information  preferred languages, global attributes, etc. — shape: {preferredLanguages?: list, active?: bool, birthDate?: string, cleanSpeakId?: string, data?: record, email?: string, expiry?: int, firstName?: string, fullName?: string, imageUrl?: string, insertInstant?: int, lastName?: string, legacyIdentifier?: string, lastUpdateInstant?: int, middleName?: string, mobilePhone?: string, parentEmail?: string, phoneNumber?: string, tenantId?: string, timezone?: string, twoFactor?: record, memberships?: list, registrations?: list, identities?: list, breachedPasswordLastCheckedInstant?: int, breachedPasswordStatus?: "None"|"ExactMatch"|"SubAddressMatch"|"PasswordOnly"|"CommonPassword", connectorId?: string, encryptionScheme?: string, factor?: int, id?: string, lastLoginInstant?: int, password?: string, passwordChangeReason?: "Administrative"|"Breached"|"Expired"|"Validation", passwordChangeRequired?: bool, passwordLastUpdateInstant?: int, salt?: string, uniqueUsername?: string, username?: string, usernameStatus?: "ACTIVE"|"PENDING"|"REJECTED", verified?: bool, verifiedInstant?: int}
  --verificationIds: list
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<emailVerificationId: string, emailVerificationOneTimeCode: string, registrationVerificationIds: record, registrationVerificationOneTimeCodes: record, token: string, tokenExpirationInstant: int, user: record<preferredLanguages: list<string>, active: bool, birthDate: string, cleanSpeakId: string, data: record, email: string, expiry: int, firstName: string, fullName: string, imageUrl: string, insertInstant: int, lastName: string, legacyIdentifier: string, lastUpdateInstant: int, middleName: string, mobilePhone: string, parentEmail: string, phoneNumber: string, tenantId: string, timezone: string, twoFactor: record<methods: list, recoveryCodes: list>, memberships: list<record>, registrations: list<record>, identities: list<record>, breachedPasswordLastCheckedInstant: int, breachedPasswordStatus: string, connectorId: string, encryptionScheme: string, factor: int, id: string, lastLoginInstant: int, password: string, passwordChangeReason: string, passwordChangeRequired: bool, passwordLastUpdateInstant: int, salt: string, uniqueUsername: string, username: string, usernameStatus: string, verified: bool, verifiedInstant: int>, verificationIds: table<id: string, oneTimeCode: string, type: record, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user/($userId)")
  let body = {applicationId: $applicationId, currentPassword: $currentPassword, disableDomainBlock: $disableDomainBlock, sendSetPasswordEmail: $sendSetPasswordEmail, sendSetPasswordIdentityType: $sendSetPasswordIdentityType, skipVerification: $skipVerification, user: $user, verificationIds: $verificationIds, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updates the user with the given Id. OR Reactivates the user with the given Id.
#
# PUT /api/user/{userId}
# operationId: updateUserWithId
# --user shape: {preferredLanguages?: list, active?: bool, birthDate?: string, cleanSpeakId?: string, data?: record, email?: string, expiry?: int, firstName?: string, fullName?: string, imageUrl?: string, insertInstant?: int, lastName?: string, legacyIdentifier?: string, lastUpdateInstant?: int, middleName?: string, mobilePhone?: string, parentEmail?: string, phoneNumber?: string, tenantId?: string, timezone?: string, twoFactor?: record, memberships?: list, registrations?: list, identities?: list, breachedPasswordLastCheckedInstant?: int, breachedPasswordStatus?: "None"|"ExactMatch"|"SubAddressMatch"|"PasswordOnly"|"CommonPassword", connectorId?: string, encryptionScheme?: string, factor?: int, id?: string, lastLoginInstant?: int, password?: string, passwordChangeReason?: "Administrative"|"Breached"|"Expired"|"Validation", passwordChangeRequired?: bool, passwordLastUpdateInstant?: int, salt?: string, uniqueUsername?: string, username?: string, usernameStatus?: "ACTIVE"|"PENDING"|"REJECTED", verified?: bool, verifiedInstant?: int}
# --eventInfo shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
export def "user updateUserWithId" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --reactivate: string
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
  --applicationId: string # format: uuid
  --currentPassword: string
  --disableDomainBlock: string@bool-completer
  --sendSetPasswordEmail: string@bool-completer
  --sendSetPasswordIdentityType: string@sendSetPasswordIdentityType-completer # Used to indicate which identity type a password "request" might go to. It could be  used for send set passwords or send password resets.
  --skipVerification: string@bool-completer
  --user: record # The public, global view of a User. This object contains all global information about the user including birthdate, registration information  preferred languages, global attributes, etc. — shape: {preferredLanguages?: list, active?: bool, birthDate?: string, cleanSpeakId?: string, data?: record, email?: string, expiry?: int, firstName?: string, fullName?: string, imageUrl?: string, insertInstant?: int, lastName?: string, legacyIdentifier?: string, lastUpdateInstant?: int, middleName?: string, mobilePhone?: string, parentEmail?: string, phoneNumber?: string, tenantId?: string, timezone?: string, twoFactor?: record, memberships?: list, registrations?: list, identities?: list, breachedPasswordLastCheckedInstant?: int, breachedPasswordStatus?: "None"|"ExactMatch"|"SubAddressMatch"|"PasswordOnly"|"CommonPassword", connectorId?: string, encryptionScheme?: string, factor?: int, id?: string, lastLoginInstant?: int, password?: string, passwordChangeReason?: "Administrative"|"Breached"|"Expired"|"Validation", passwordChangeRequired?: bool, passwordLastUpdateInstant?: int, salt?: string, uniqueUsername?: string, username?: string, usernameStatus?: "ACTIVE"|"PENDING"|"REJECTED", verified?: bool, verifiedInstant?: int}
  --verificationIds: list
  --eventInfo: record # Information about a user event (login, register, etc) that helps identify the source of the event (location, device type, OS, etc). — shape: {data?: record, deviceDescription?: string, deviceName?: string, deviceType?: string, ipAddress?: string, location?: record, os?: string, userAgent?: string}
]: any -> record<emailVerificationId: string, emailVerificationOneTimeCode: string, registrationVerificationIds: record, registrationVerificationOneTimeCodes: record, token: string, tokenExpirationInstant: int, user: record<preferredLanguages: list<string>, active: bool, birthDate: string, cleanSpeakId: string, data: record, email: string, expiry: int, firstName: string, fullName: string, imageUrl: string, insertInstant: int, lastName: string, legacyIdentifier: string, lastUpdateInstant: int, middleName: string, mobilePhone: string, parentEmail: string, phoneNumber: string, tenantId: string, timezone: string, twoFactor: record<methods: list, recoveryCodes: list>, memberships: list<record>, registrations: list<record>, identities: list<record>, breachedPasswordLastCheckedInstant: int, breachedPasswordStatus: string, connectorId: string, encryptionScheme: string, factor: int, id: string, lastLoginInstant: int, password: string, passwordChangeReason: string, passwordChangeRequired: bool, passwordLastUpdateInstant: int, salt: string, uniqueUsername: string, username: string, usernameStatus: string, verified: bool, verifiedInstant: int>, verificationIds: table<id: string, oneTimeCode: string, type: record, value: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reactivate" $reactivate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/user/($userId)" $qp)
  let body = {applicationId: $applicationId, currentPassword: $currentPassword, disableDomainBlock: $disableDomainBlock, sendSetPasswordEmail: $sendSetPasswordEmail, sendSetPasswordIdentityType: $sendSetPasswordIdentityType, skipVerification: $skipVerification, user: $user, verificationIds: $verificationIds, eventInfo: $eventInfo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the user for the given Id.
#
# GET /api/user/{userId}
# operationId: retrieveUserWithId
export def "user retrieveUserWithId" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-FusionAuth-TenantId: string # The unique Id of the tenant used to scope this API request. Only required when there is more than one tenant and the API key is not tenant-scoped.
]: nothing -> record<emailVerificationId: string, emailVerificationOneTimeCode: string, registrationVerificationIds: record, registrationVerificationOneTimeCodes: record, token: string, tokenExpirationInstant: int, user: record<preferredLanguages: list<string>, active: bool, birthDate: string, cleanSpeakId: string, data: record, email: string, expiry: int, firstName: string, fullName: string, imageUrl: string, insertInstant: int, lastName: string, legacyIdentifier: string, lastUpdateInstant: int, middleName: string, mobilePhone: string, parentEmail: string, phoneNumber: string, tenantId: string, timezone: string, twoFactor: record<methods: list, recoveryCodes: list>, memberships: list<record>, registrations: list<record>, identities: list<record>, breachedPasswordLastCheckedInstant: int, breachedPasswordStatus: string, connectorId: string, encryptionScheme: string, factor: int, id: string, lastLoginInstant: int, password: string, passwordChangeReason: string, passwordChangeRequired: bool, passwordLastUpdateInstant: int, salt: string, uniqueUsername: string, username: string, usernameStatus: string, verified: bool, verifiedInstant: int>, verificationIds: table<id: string, oneTimeCode: string, type: record, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/user/($userId)")
  let extra_headers = {"X-FusionAuth-TenantId": $X_FusionAuth_TenantId} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes all of the WebAuthn credentials for the given User Id.
#
# DELETE /api/webauthn
# operationId: deleteWebAuthnCredentialsForUserWithId
export def "webauthn delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userId: string # The unique Id of the User to delete WebAuthn passkeys for.
]: nothing -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $userId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/webauthn" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves all WebAuthn credentials for the given user.
#
# GET /api/webauthn
# operationId: retrieveWebAuthnCredentialsForUserWithId
export def "webauthn retrieveWebAuthnCredentialsForUserWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userId: string # The user's ID.
]: nothing -> record<credential: record<algorithm: string, attestationType: string, authenticatorSupportsUserVerification: bool, credentialId: string, data: record, discoverable: bool, displayName: string, id: string, insertInstant: int, lastUseInstant: int, name: string, publicKey: string, relyingPartyId: string, signCount: int, tenantId: string, transports: list<string>, userAgent: string, userId: string>, credentials: table<algorithm: string, attestationType: string, authenticatorSupportsUserVerification: bool, credentialId: string, data: record, discoverable: bool, displayName: string, id: string, insertInstant: int, lastUseInstant: int, name: string, publicKey: string, relyingPartyId: string, signCount: int, tenantId: string, transports: list, userAgent: string, userId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $userId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/webauthn" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Complete a WebAuthn authentication ceremony by validating the signature against the previously generated challenge without logging the user in
#
# POST /api/webauthn/assert
# operationId: completeWebAuthnAssertionWithId
# --credential shape: {clientExtensionResults?: record, id?: string, rpId?: string, response?: record, type?: string}
# --metaData shape: {data?: record, device?: record, resources?: list, scopes?: list}
export def "webauthn-assert completeWebAuthnAssertionWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --credential: record # Request to authenticate with WebAuthn — shape: {clientExtensionResults?: record, id?: string, rpId?: string, response?: record, type?: string}
  --origin: string
  --rpId: string
  --twoFactorTrustId: string
  --applicationId: string # format: uuid
  --ipAddress: string
  --metaData: record # shape: {data?: record, device?: record, resources?: list, scopes?: list}
  --newDevice: string@bool-completer
  --noJWT: string@bool-completer
]: any -> record<credential: record<algorithm: string, attestationType: string, authenticatorSupportsUserVerification: bool, credentialId: string, data: record, discoverable: bool, displayName: string, id: string, insertInstant: int, lastUseInstant: int, name: string, publicKey: string, relyingPartyId: string, signCount: int, tenantId: string, transports: list<string>, userAgent: string, userId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/webauthn/assert")
  let body = {credential: $credential, origin: $origin, rpId: $rpId, twoFactorTrustId: $twoFactorTrustId, applicationId: $applicationId, ipAddress: $ipAddress, metaData: $metaData, newDevice: $newDevice, noJWT: $noJWT} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Import a WebAuthn credential
#
# POST /api/webauthn/import
# operationId: importWebAuthnCredentialWithId
# --credentials item shape: {algorithm?: "ES256"|"ES384"|"ES512"|"RS256"|"RS384"|"RS512"|"PS256"|"PS384"|"PS512", attestationType?: "basic"|"self"|"attestationCa"|"anonymizationCa"|"none", authenticatorSupportsUserVerification?: bool, credentialId?: string, data?: record, discoverable?: bool, displayName?: string, id?: string, insertInstant?: int, lastUseInstant?: int, name?: string, publicKey?: string, relyingPartyId?: string, signCount?: int, tenantId?: string, transports?: list, userAgent?: string, userId?: string}
export def "webauthn-import importWebAuthnCredentialWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --credentials: list # item shape: {algorithm?: "ES256"|"ES384"|"ES512"|"RS256"|"RS384"|"RS512"|"PS256"|"PS384"|"PS512", attestationType?: "basic"|"self"|"attestationCa"|"anonymizationCa"|"none", authenticatorSupportsUserVerification?: bool, credentialId?: string, data?: record, discoverable?: bool, displayName?: string, id?: string, insertInstant?: int, lastUseInstant?: int, name?: string, publicKey?: string, relyingPartyId?: string, signCount?: int, tenantId?: string, transports?: list, userAgent?: string, userId?: string}
  --validateDbConstraints: string@bool-completer
]: any -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/webauthn/import")
  let body = {credentials: $credentials, validateDbConstraints: $validateDbConstraints} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Complete a WebAuthn authentication ceremony by validating the signature against the previously generated challenge and then login the user in
#
# POST /api/webauthn/login
# operationId: completeWebAuthnLoginWithId
# --credential shape: {clientExtensionResults?: record, id?: string, rpId?: string, response?: record, type?: string}
# --metaData shape: {data?: record, device?: record, resources?: list, scopes?: list}
export def "webauthn-login completeWebAuthnLoginWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --credential: record # Request to authenticate with WebAuthn — shape: {clientExtensionResults?: record, id?: string, rpId?: string, response?: record, type?: string}
  --origin: string
  --rpId: string
  --twoFactorTrustId: string
  --applicationId: string # format: uuid
  --ipAddress: string
  --metaData: record # shape: {data?: record, device?: record, resources?: list, scopes?: list}
  --newDevice: string@bool-completer
  --noJWT: string@bool-completer
]: any -> record<actions: table<actionId: string, actionerUserId: string, expiry: int, localizedName: string, localizedOption: string, localizedReason: string, name: string, option: string, reason: string, reasonCode: string>, changePasswordId: string, changePasswordReason: string, configurableMethods: list<string>, emailVerificationId: string, identityVerificationId: string, methods: table<authenticator: record, email: string, id: string, lastUsed: bool, method: string, mobilePhone: string, secret: string>, pendingIdPLinkId: string, refreshToken: string, refreshTokenId: string, registrationVerificationId: string, state: record, threatsDetected: list<any>, token: string, tokenExpirationInstant: int, trustToken: string, twoFactorId: string, twoFactorTrustId: string, user: record<preferredLanguages: list<string>, active: bool, birthDate: string, cleanSpeakId: string, data: record, email: string, expiry: int, firstName: string, fullName: string, imageUrl: string, insertInstant: int, lastName: string, legacyIdentifier: string, lastUpdateInstant: int, middleName: string, mobilePhone: string, parentEmail: string, phoneNumber: string, tenantId: string, timezone: string, twoFactor: record<methods: list, recoveryCodes: list>, memberships: list<record>, registrations: list<record>, identities: list<record>, breachedPasswordLastCheckedInstant: int, breachedPasswordStatus: string, connectorId: string, encryptionScheme: string, factor: int, id: string, lastLoginInstant: int, password: string, passwordChangeReason: string, passwordChangeRequired: bool, passwordLastUpdateInstant: int, salt: string, uniqueUsername: string, username: string, usernameStatus: string, verified: bool, verifiedInstant: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/webauthn/login")
  let body = {credential: $credential, origin: $origin, rpId: $rpId, twoFactorTrustId: $twoFactorTrustId, applicationId: $applicationId, ipAddress: $ipAddress, metaData: $metaData, newDevice: $newDevice, noJWT: $noJWT} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Complete a WebAuthn registration ceremony by validating the client request and saving the new credential
#
# POST /api/webauthn/register/complete
# operationId: completeWebAuthnRegistrationWithId
# --credential shape: {clientExtensionResults?: record, id?: string, rpId?: string, response?: record, transports?: list, type?: string}
export def "webauthn-register-complete completeWebAuthnRegistrationWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --credential: record # Request to register a new public key with WebAuthn — shape: {clientExtensionResults?: record, id?: string, rpId?: string, response?: record, transports?: list, type?: string}
  --origin: string
  --rpId: string
  --userId: string # format: uuid
]: any -> record<credential: record<algorithm: string, attestationType: string, authenticatorSupportsUserVerification: bool, credentialId: string, data: record, discoverable: bool, displayName: string, id: string, insertInstant: int, lastUseInstant: int, name: string, publicKey: string, relyingPartyId: string, signCount: int, tenantId: string, transports: list<string>, userAgent: string, userId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/webauthn/register/complete")
  let body = {credential: $credential, origin: $origin, rpId: $rpId, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Start a WebAuthn registration ceremony by generating a new challenge for the user
#
# POST /api/webauthn/register/start
# operationId: startWebAuthnRegistrationWithId
export def "webauthn-register-start startWebAuthnRegistrationWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --displayName: string
  --name: string
  --userAgent: string
  --userId: string # format: uuid
  --workflow: string@workflow-completer # Identifies the WebAuthn workflow. This will affect the parameters used for credential creation  and request based on the Tenant configuration.
]: any -> record<options: record<attestation: string, authenticatorSelection: record<authenticatorAttachment: string, requireResidentKey: bool, residentKey: string, userVerification: string>, challenge: string, excludeCredentials: list<record>, extensions: record<credProps: bool>, pubKeyCredParams: list<record>, rp: record<id: string, name: string>, timeout: int, user: record<displayName: string, id: string, name: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/webauthn/register/start")
  let body = {displayName: $displayName, name: $name, userAgent: $userAgent, userId: $userId, workflow: $workflow} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Start a WebAuthn authentication ceremony by generating a new challenge for the user
#
# POST /api/webauthn/start
# operationId: startWebAuthnLoginWithId
export def "webauthn-start startWebAuthnLoginWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --applicationId: string # format: uuid
  --credentialId: string # format: uuid
  --loginId: string
  --loginIdTypes: list
  --state: record
  --userId: string # format: uuid
  --workflow: string@workflow-completer # Identifies the WebAuthn workflow. This will affect the parameters used for credential creation  and request based on the Tenant configuration.
]: any -> record<options: record<allowCredentials: list<record>, challenge: string, rpId: string, timeout: int, userVerification: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/webauthn/start")
  let body = {applicationId: $applicationId, credentialId: $credentialId, loginId: $loginId, loginIdTypes: $loginIdTypes, state: $state, userId: $userId, workflow: $workflow} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the WebAuthn credential for the given Id.
#
# DELETE /api/webauthn/{id}
# operationId: deleteWebAuthnCredentialWithId
export def "webauthn delete-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/webauthn/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieves the WebAuthn credential for the given Id.
#
# GET /api/webauthn/{id}
# operationId: retrieveWebAuthnCredentialWithId
export def "webauthn retrieveWebAuthnCredentialWithId" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<credential: record<algorithm: string, attestationType: string, authenticatorSupportsUserVerification: bool, credentialId: string, data: record, discoverable: bool, displayName: string, id: string, insertInstant: int, lastUseInstant: int, name: string, publicKey: string, relyingPartyId: string, signCount: int, tenantId: string, transports: list<string>, userAgent: string, userId: string>, credentials: table<algorithm: string, attestationType: string, authenticatorSupportsUserVerification: bool, credentialId: string, data: record, discoverable: bool, displayName: string, id: string, insertInstant: int, lastUseInstant: int, name: string, publicKey: string, relyingPartyId: string, signCount: int, tenantId: string, transports: list, userAgent: string, userId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/webauthn/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a webhook. You can optionally specify an Id for the webhook, if not provided one will be generated.
#
# POST /api/webhook
# operationId: createWebhook
# --webhook shape: {connectTimeout?: int, data?: record, description?: string, eventsEnabled?: record, global?: bool, headers?: record, httpAuthenticationPassword?: string, httpAuthenticationUsername?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, readTimeout?: int, signatureConfiguration?: record, sslCertificate?: string, sslCertificateKeyId?: string, tenantIds?: list, url?: string}
export def "webhook createWebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --webhook: record # A server where events are sent. This includes user action events and any other events sent by FusionAuth. — shape: {connectTimeout?: int, data?: record, description?: string, eventsEnabled?: record, global?: bool, headers?: record, httpAuthenticationPassword?: string, httpAuthenticationUsername?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, readTimeout?: int, signatureConfiguration?: record, sslCertificate?: string, sslCertificateKeyId?: string, tenantIds?: list, url?: string}
]: any -> record<webhook: record<connectTimeout: int, data: record, description: string, eventsEnabled: record, global: bool, headers: record, httpAuthenticationPassword: string, httpAuthenticationUsername: string, id: string, insertInstant: int, lastUpdateInstant: int, readTimeout: int, signatureConfiguration: record<signingKeyId: string, enabled: bool>, sslCertificate: string, sslCertificateKeyId: string, tenantIds: list<string>, url: string>, webhooks: table<connectTimeout: int, data: record, description: string, eventsEnabled: record, global: bool, headers: record, httpAuthenticationPassword: string, httpAuthenticationUsername: string, id: string, insertInstant: int, lastUpdateInstant: int, readTimeout: int, signatureConfiguration: record, sslCertificate: string, sslCertificateKeyId: string, tenantIds: list, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/webhook")
  let body = {webhook: $webhook} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the webhook for the given Id. If you pass in null for the Id, this will return all the webhooks.
#
# GET /api/webhook
# operationId: retrieveWebhook
export def "webhook retrieveWebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<webhook: record<connectTimeout: int, data: record, description: string, eventsEnabled: record, global: bool, headers: record, httpAuthenticationPassword: string, httpAuthenticationUsername: string, id: string, insertInstant: int, lastUpdateInstant: int, readTimeout: int, signatureConfiguration: record<signingKeyId: string, enabled: bool>, sslCertificate: string, sslCertificateKeyId: string, tenantIds: list<string>, url: string>, webhooks: table<connectTimeout: int, data: record, description: string, eventsEnabled: record, global: bool, headers: record, httpAuthenticationPassword: string, httpAuthenticationUsername: string, id: string, insertInstant: int, lastUpdateInstant: int, readTimeout: int, signatureConfiguration: record, sslCertificate: string, sslCertificateKeyId: string, tenantIds: list, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/webhook")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Searches webhooks with the specified criteria and pagination.
#
# POST /api/webhook/search
# operationId: searchWebhooksWithId
# --search shape: {description?: string, tenantId?: string, url?: string, numberOfResults?: int, orderBy?: string, startRow?: int}
export def "webhook-search searchWebhooksWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: record # Search criteria for webhooks. — shape: {description?: string, tenantId?: string, url?: string, numberOfResults?: int, orderBy?: string, startRow?: int}
]: any -> record<total: int, webhooks: table<connectTimeout: int, data: record, description: string, eventsEnabled: record, global: bool, headers: record, httpAuthenticationPassword: string, httpAuthenticationUsername: string, id: string, insertInstant: int, lastUpdateInstant: int, readTimeout: int, signatureConfiguration: record, sslCertificate: string, sslCertificateKeyId: string, tenantIds: list, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/webhook/search")
  let body = {search: $search} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Creates a webhook. You can optionally specify an Id for the webhook, if not provided one will be generated.
#
# POST /api/webhook/{webhookId}
# operationId: createWebhookWithId
# --webhook shape: {connectTimeout?: int, data?: record, description?: string, eventsEnabled?: record, global?: bool, headers?: record, httpAuthenticationPassword?: string, httpAuthenticationUsername?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, readTimeout?: int, signatureConfiguration?: record, sslCertificate?: string, sslCertificateKeyId?: string, tenantIds?: list, url?: string}
export def "webhook createWebhookWithId" [
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --webhook: record # A server where events are sent. This includes user action events and any other events sent by FusionAuth. — shape: {connectTimeout?: int, data?: record, description?: string, eventsEnabled?: record, global?: bool, headers?: record, httpAuthenticationPassword?: string, httpAuthenticationUsername?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, readTimeout?: int, signatureConfiguration?: record, sslCertificate?: string, sslCertificateKeyId?: string, tenantIds?: list, url?: string}
]: any -> record<webhook: record<connectTimeout: int, data: record, description: string, eventsEnabled: record, global: bool, headers: record, httpAuthenticationPassword: string, httpAuthenticationUsername: string, id: string, insertInstant: int, lastUpdateInstant: int, readTimeout: int, signatureConfiguration: record<signingKeyId: string, enabled: bool>, sslCertificate: string, sslCertificateKeyId: string, tenantIds: list<string>, url: string>, webhooks: table<connectTimeout: int, data: record, description: string, eventsEnabled: record, global: bool, headers: record, httpAuthenticationPassword: string, httpAuthenticationUsername: string, id: string, insertInstant: int, lastUpdateInstant: int, readTimeout: int, signatureConfiguration: record, sslCertificate: string, sslCertificateKeyId: string, tenantIds: list, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/webhook/($webhookId)")
  let body = {webhook: $webhook} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes the webhook for the given Id.
#
# DELETE /api/webhook/{webhookId}
# operationId: deleteWebhookWithId
export def "webhook delete" [
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<fieldErrors: table<code: string, data: record, message: string>, generalErrors: table<code: string, data: record, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/webhook/($webhookId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patches the webhook with the given Id.
#
# PATCH /api/webhook/{webhookId}
# operationId: patchWebhookWithId
# --webhook shape: {connectTimeout?: int, data?: record, description?: string, eventsEnabled?: record, global?: bool, headers?: record, httpAuthenticationPassword?: string, httpAuthenticationUsername?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, readTimeout?: int, signatureConfiguration?: record, sslCertificate?: string, sslCertificateKeyId?: string, tenantIds?: list, url?: string}
export def "webhook patch" [
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --webhook: record # A server where events are sent. This includes user action events and any other events sent by FusionAuth. — shape: {connectTimeout?: int, data?: record, description?: string, eventsEnabled?: record, global?: bool, headers?: record, httpAuthenticationPassword?: string, httpAuthenticationUsername?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, readTimeout?: int, signatureConfiguration?: record, sslCertificate?: string, sslCertificateKeyId?: string, tenantIds?: list, url?: string}
]: any -> record<webhook: record<connectTimeout: int, data: record, description: string, eventsEnabled: record, global: bool, headers: record, httpAuthenticationPassword: string, httpAuthenticationUsername: string, id: string, insertInstant: int, lastUpdateInstant: int, readTimeout: int, signatureConfiguration: record<signingKeyId: string, enabled: bool>, sslCertificate: string, sslCertificateKeyId: string, tenantIds: list<string>, url: string>, webhooks: table<connectTimeout: int, data: record, description: string, eventsEnabled: record, global: bool, headers: record, httpAuthenticationPassword: string, httpAuthenticationUsername: string, id: string, insertInstant: int, lastUpdateInstant: int, readTimeout: int, signatureConfiguration: record, sslCertificate: string, sslCertificateKeyId: string, tenantIds: list, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/webhook/($webhookId)")
  let body = {webhook: $webhook} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieves the webhook for the given Id. If you pass in null for the Id, this will return all the webhooks.
#
# GET /api/webhook/{webhookId}
# operationId: retrieveWebhookWithId
export def "webhook retrieveWebhookWithId" [
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<webhook: record<connectTimeout: int, data: record, description: string, eventsEnabled: record, global: bool, headers: record, httpAuthenticationPassword: string, httpAuthenticationUsername: string, id: string, insertInstant: int, lastUpdateInstant: int, readTimeout: int, signatureConfiguration: record<signingKeyId: string, enabled: bool>, sslCertificate: string, sslCertificateKeyId: string, tenantIds: list<string>, url: string>, webhooks: table<connectTimeout: int, data: record, description: string, eventsEnabled: record, global: bool, headers: record, httpAuthenticationPassword: string, httpAuthenticationUsername: string, id: string, insertInstant: int, lastUpdateInstant: int, readTimeout: int, signatureConfiguration: record, sslCertificate: string, sslCertificateKeyId: string, tenantIds: list, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/webhook/($webhookId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates the webhook with the given Id.
#
# PUT /api/webhook/{webhookId}
# operationId: updateWebhookWithId
# --webhook shape: {connectTimeout?: int, data?: record, description?: string, eventsEnabled?: record, global?: bool, headers?: record, httpAuthenticationPassword?: string, httpAuthenticationUsername?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, readTimeout?: int, signatureConfiguration?: record, sslCertificate?: string, sslCertificateKeyId?: string, tenantIds?: list, url?: string}
export def "webhook updateWebhookWithId" [
  webhookId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --webhook: record # A server where events are sent. This includes user action events and any other events sent by FusionAuth. — shape: {connectTimeout?: int, data?: record, description?: string, eventsEnabled?: record, global?: bool, headers?: record, httpAuthenticationPassword?: string, httpAuthenticationUsername?: string, id?: string, insertInstant?: int, lastUpdateInstant?: int, readTimeout?: int, signatureConfiguration?: record, sslCertificate?: string, sslCertificateKeyId?: string, tenantIds?: list, url?: string}
]: any -> record<webhook: record<connectTimeout: int, data: record, description: string, eventsEnabled: record, global: bool, headers: record, httpAuthenticationPassword: string, httpAuthenticationUsername: string, id: string, insertInstant: int, lastUpdateInstant: int, readTimeout: int, signatureConfiguration: record<signingKeyId: string, enabled: bool>, sslCertificate: string, sslCertificateKeyId: string, tenantIds: list<string>, url: string>, webhooks: table<connectTimeout: int, data: record, description: string, eventsEnabled: record, global: bool, headers: record, httpAuthenticationPassword: string, httpAuthenticationUsername: string, id: string, insertInstant: int, lastUpdateInstant: int, readTimeout: int, signatureConfiguration: record, sslCertificate: string, sslCertificateKeyId: string, tenantIds: list, url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/webhook/($webhookId)")
  let body = {webhook: $webhook} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Approve a device grant. OR Approve a device grant.
#
# POST /oauth2/device/approve
# operationId: createDeviceApprove
export def "oauth2-device-approve createDeviceApprove" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<deviceGrantStatus: string, deviceInfo: record<description: string, lastAccessedAddress: string, lastAccessedInstant: int, name: string, type: string>, identityProviderLink: record<data: record, displayName: string, identityProviderId: string, identityProviderName: string, identityProviderType: string, identityProviderUserId: string, insertInstant: int, lastLoginInstant: int, tenantId: string, token: string, userId: string>, tenantId: string, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/device/approve")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a user_code that is part of an in-progress Device Authorization Grant.  This API is useful if you want to build your own login workflow to complete a device grant.  This request will require an API key. OR Retrieve a user_code that is part of an in-progress Device Authorization Grant.  This API is useful if you want to build your own login workflow to complete a device grant.
#
# GET /oauth2/device/user-code
# operationId: retrieveDeviceUserCode
export def "oauth2-device-user-code retrieveDeviceUserCode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/device/user-code")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a user_code that is part of an in-progress Device Authorization Grant.  This API is useful if you want to build your own login workflow to complete a device grant. OR Retrieve a user_code that is part of an in-progress Device Authorization Grant.  This API is useful if you want to build your own login workflow to complete a device grant.  This request will require an API key.
#
# POST /oauth2/device/user-code
# operationId: createDeviceUserCode
export def "oauth2-device-user-code createDeviceUserCode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/device/user-code")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Validates the end-user provided user_code from the user-interaction of the Device Authorization Grant. If you build your own activation form you should validate the user provided code prior to beginning the Authorization grant. OR Validates the end-user provided user_code from the user-interaction of the Device Authorization Grant. If you build your own activation form you should validate the user provided code prior to beginning the Authorization grant.
#
# GET /oauth2/device/validate
# operationId: retrieveDeviceValidate
export def "oauth2-device-validate retrieveDeviceValidate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --user-code: string # The end-user verification code.
  --client-id: string # The client Id.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_code" $user_code "scalar") (serialize-qp "client_id" $client_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/oauth2/device/validate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start the Device Authorization flow using a request body OR Start the Device Authorization flow using form-encoded parameters
#
# POST /oauth2/device_authorize
# operationId: createDevice_authorize
export def "oauth2-device-authorize authorize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<device_code: string, expires_in: int, interval: int, user_code: string, verification_uri: string, verification_uri_complete: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/device_authorize")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Inspect an access token issued as the result of the Client Credentials Grant. OR Inspect an access token issued as the result of the Client Credentials Grant. OR Inspect an access token issued as the result of the User based grant such as the Authorization Code Grant, Implicit Grant, the User Credentials Grant or the Refresh Grant. OR Inspect an access token issued as the result of the User based grant such as the Authorization Code Grant, Implicit Grant, the User Credentials Grant or the Refresh Grant.
#
# POST /oauth2/introspect
# operationId: createIntrospect
export def "oauth2-introspect createIntrospect" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/introspect")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Exchange User Credentials for a Token. If you will be using the Resource Owner Password Credential Grant, you will make a request to the Token endpoint to exchange the user’s email and password for an access token. OR Exchange User Credentials for a Token. If you will be using the Resource Owner Password Credential Grant, you will make a request to the Token endpoint to exchange the user’s email and password for an access token. OR Exchange a Refresh Token for an Access Token. If you will be using the Refresh Token Grant, you will make a request to the Token endpoint to exchange the user’s refresh token for an access token. OR Exchange a Refresh Token for an Access Token. If you will be using the Refresh Token Grant, you will make a request to the Token endpoint to exchange the user’s refresh token for an access token. OR Exchanges an OAuth authorization code for an access token. Makes a request to the Token endpoint to exchange the authorization code returned from the Authorize endpoint for an access token. OR Exchanges an OAuth authorization code and code_verifier for an access token. Makes a request to the Token endpoint to exchange the authorization code returned from the Authorize endpoint and a code_verifier for an access token. OR Exchanges an OAuth authorization code and code_verifier for an access token. Makes a request to the Token endpoint to exchange the authorization code returned from the Authorize endpoint and a code_verifier for an access token. OR Exchanges an OAuth authorization code for an access token. Makes a request to the Token endpoint to exchange the authorization code returned from the Authorize endpoint for an access token. OR Make a Client Credentials grant request to obtain an access token. OR Make a Client Credentials grant request to obtain an access token.
#
# POST /oauth2/token
# operationId: createToken
export def "oauth2-token createToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<expires_in: int, id_token: string, refresh_token: string, refresh_token_id: string, scope: string, access_token: string, token_type: string, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Call the UserInfo endpoint to retrieve User Claims from the access token issued by FusionAuth.
#
# GET /oauth2/userinfo
# operationId: retrieveUserInfoFromAccessTokenWithId
export def "oauth2-userinfo retrieveUserInfoFromAccessTokenWithId" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/userinfo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
