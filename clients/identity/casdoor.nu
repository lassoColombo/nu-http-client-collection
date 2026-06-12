# Auto-generated client for Casdoor RESTful API v1.503.0
# Source: https://raw.githubusercontent.com/casdoor/casdoor/master/swagger/swagger.json
# Auth: --token flag or $env.CASDOOR_RESTFUL_API_TOKEN

const BASE_URL = "https://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CASDOOR_RESTFUL_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://localhost" "http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def state-completer [] { ["PaymentStateCanceled = "Canceled"" "PaymentStateCreated = "Created"" "PaymentStateError = "Error"" "PaymentStatePaid = "Paid"" "PaymentStateTimeout = "Timeout""] }
def state-completer-1 [] { ["SubStateActive = "Active"" "SubStateError = "Error"" "SubStateExpired = "Expired"" "SubStatePending = "Pending"" "SubStateSuspended = "Suspended"" "SubStateUpcoming = "Upcoming""] }
def category-completer [] { ["TransactionCategoryPurchase = "Purchase"" "TransactionCategoryRecharge = "Recharge""] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "well-known-jwks RootControllerGetJwks" } } | get name | first)
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

# GET /.well-known/jwks
#
# operationId: RootController.GetJwks
export def "well-known-jwks RootControllerGetJwks" [
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
  let full_url = (build-url $base "/.well-known/jwks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Oidc Discovery
#
# GET /.well-known/openid-configuration
# operationId: RootController.GetOidcDiscovery
export def "well-known-openid-configuration RootControllerGetOidcDiscovery" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<authorization_endpoint: string, claims_supported: list<string>, device_authorization_endpoint: string, end_session_endpoint: string, grant_types_supported: list<string>, id_token_signing_alg_values_supported: list<string>, introspection_endpoint: string, issuer: string, jwks_uri: string, request_object_signing_alg_values_supported: list<string>, request_parameter_supported: bool, response_modes_supported: list<string>, response_types_supported: list<string>, scopes_supported: list<string>, subject_types_supported: list<string>, token_endpoint: string, userinfo_endpoint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/.well-known/openid-configuration")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /.well-known/webfinger
#
# operationId: RootController.GetWebFinger
export def "well-known-webfinger RootControllerGetWebFinger" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --resource: string # resource
]: nothing -> record<aliases: record, links: table<href: string, rel: string>, properties: record, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resource" $resource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/.well-known/webfinger" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /.well-known/{application}/jwks
#
# operationId: RootController.GetJwksByApplication
export def "well-known-jwks RootControllerGetJwksByApplication" [
  application: string
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
  let full_url = (build-url $base $"/.well-known/($application)/jwks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Oidc Discovery for specific application
#
# GET /.well-known/{application}/openid-configuration
# operationId: RootController.GetOidcDiscoveryByApplication
export def "well-known-openid-configuration RootControllerGetOidcDiscoveryByApplication" [
  application: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<authorization_endpoint: string, claims_supported: list<string>, device_authorization_endpoint: string, end_session_endpoint: string, grant_types_supported: list<string>, id_token_signing_alg_values_supported: list<string>, introspection_endpoint: string, issuer: string, jwks_uri: string, request_object_signing_alg_values_supported: list<string>, request_parameter_supported: bool, response_modes_supported: list<string>, response_types_supported: list<string>, scopes_supported: list<string>, subject_types_supported: list<string>, token_endpoint: string, userinfo_endpoint: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/.well-known/($application)/openid-configuration")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /.well-known/{application}/webfinger
#
# operationId: RootController.GetWebFingerByApplication
export def "well-known-webfinger RootControllerGetWebFingerByApplication" [
  application: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --resource: string # resource
]: nothing -> record<aliases: record, links: table<href: string, rel: string>, properties: record, subject: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "resource" $resource "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/.well-known/($application)/webfinger" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Login Error Counts
#
# POST /api/Callback
# operationId: ApiController.Callback
export def "callback ApiControllerCallback" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<address: string, aud: string, email: string, email_verified: bool, groups: list<string>, is_verified: bool, iss: string, name: string, permissions: list<string>, phone: string, picture: string, preferred_username: string, real_name: string, roles: list<string>, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/Callback")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# add adapter
#
# POST /api/add-adapter
# operationId: ApiController.AddAdapter
export def "add-adapter ApiControllerAddAdapter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createdTime: string
  --database: string
  --databaseType: string
  --host: string
  --name: string
  --owner: string
  --password: string
  --port: int # format: int64
  --table: string
  --type: string
  --useSameDb: oneof<nothing, bool>
  --user: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/add-adapter")
  let body = {createdTime: $createdTime, database: $database, databaseType: $databaseType, host: $host, name: $name, owner: $owner, password: $password, port: $port, table: $table, type: $type, useSameDb: $useSameDb, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# add an application
#
# POST /api/add-application
# operationId: ApiController.AddApplication
# --organizationObj shape: {accountItems?: list, accountMenu?: string, balanceCredit?: float, balanceCurrency?: string, countryCodes?: list, createdTime?: string, defaultApplication?: string, defaultAvatar?: string, defaultPassword?: string, disableSignin?: bool, displayName?: string, enableSoftDeletion?: bool, enableTour?: bool, favicon?: string, hasPrivilegeConsent?: bool, initScore?: int, ipRestriction?: string, ipWhitelist?: string, isProfilePublic?: bool, languages?: list, logo?: string, logoDark?: string, masterPassword?: string, masterVerificationCode?: string, mfaItems?: list, mfaRememberInHours?: int, name?: string, navItems?: list, orgBalance?: float, owner?: string, passwordExpireDays?: int, passwordObfuscatorKey?: string, passwordObfuscatorType?: string, passwordOptions?: list, passwordSalt?: string, passwordType?: string, tags?: list, themeData?: record, useEmailAsUsername?: bool, userBalance?: float, userNavItems?: list, userTypes?: list, websiteUrl?: string, widgetItems?: list}
# --providers item shape: {canSignIn?: bool, canSignUp?: bool, canUnlink?: bool, countryCodes?: list, name?: string, owner?: string, prompted?: bool, provider?: record, rule?: string, signupGroup?: string}
# --samlAttributes item shape: {name?: string, nameFormat?: string, value?: string}
# --signinItems item shape: {customCss?: string, isCustom?: bool, label?: string, name?: string, placeholder?: string, rule?: string, visible?: bool}
# --signinMethods item shape: {displayName?: string, name?: string, rule?: string}
# --signupItems item shape: {customCss?: string, label?: string, name?: string, options?: list, placeholder?: string, prompted?: bool, regex?: string, required?: bool, rule?: string, type?: string, visible?: bool}
# --themeData shape: {borderRadius?: int, colorPrimary?: string, isCompact?: bool, isEnabled?: bool, themeType?: string}
# --tokenAttributes item shape: {name?: string, type?: string, value?: string}
export def "add-application ApiControllerAddApplication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --affiliationUrl: string
  --cert: string
  --certPublicKey: string
  --clientId: string
  --clientSecret: string
  --codeResendTimeout: int # format: int64
  --cookieExpireInHours: int # format: int64
  --createdTime: string
  --defaultGroup: string
  --description: string
  --disableSamlAttributes: oneof<nothing, bool>
  --disableSignin: oneof<nothing, bool>
  --displayName: string
  --enableAutoSignin: oneof<nothing, bool>
  --enableCodeSignin: oneof<nothing, bool>
  --enableExclusiveSignin: oneof<nothing, bool>
  --enableLinkWithEmail: oneof<nothing, bool>
  --enablePassword: oneof<nothing, bool>
  --enableSamlAssertionSignature: oneof<nothing, bool>
  --enableSamlC14n10: oneof<nothing, bool>
  --enableSamlCompress: oneof<nothing, bool>
  --enableSamlPostBinding: oneof<nothing, bool>
  --enableSignUp: oneof<nothing, bool>
  --enableSigninSession: oneof<nothing, bool>
  --enableWebAuthn: oneof<nothing, bool>
  --expireInHours: float # format: double
  --failedSigninFrozenTime: int # format: int64
  --failedSigninLimit: int # format: int64
  --favicon: string
  --footerHtml: string
  --forcedRedirectOrigin: string
  --forgetUrl: string
  --formBackgroundUrl: string
  --formBackgroundUrlMobile: string
  --formCss: string
  --formCssMobile: string
  --formOffset: int # format: int64
  --formSideHtml: string
  --grantTypes: list
  --headerHtml: string
  --homepageUrl: string
  --ipRestriction: string
  --ipWhitelist: string
  --isShared: oneof<nothing, bool>
  --logo: string
  --name: string
  --order: int # format: int64
  --orgChoiceMode: string
  --organization: string
  --organizationObj: record # shape: {accountItems?: list, accountMenu?: string, balanceCredit?: float, balanceCurrency?: string, countryCodes?: list, createdTime?: string, defaultApplication?: string, defaultAvatar?: string, defaultPassword?: string, disableSignin?: bool, displayName?: string, enableSoftDeletion?: bool, enableTour?: bool, favicon?: string, hasPrivilegeConsent?: bool, initScore?: int, ipRestriction?: string, ipWhitelist?: string, isProfilePublic?: bool, languages?: list, logo?: string, logoDark?: string, masterPassword?: string, masterVerificationCode?: string, mfaItems?: list, mfaRememberInHours?: int, name?: string, navItems?: list, orgBalance?: float, owner?: string, passwordExpireDays?: int, passwordObfuscatorKey?: string, passwordObfuscatorType?: string, passwordOptions?: list, passwordSalt?: string, passwordType?: string, tags?: list, themeData?: record, useEmailAsUsername?: bool, userBalance?: float, userNavItems?: list, userTypes?: list, websiteUrl?: string, widgetItems?: list}
  --owner: string
  --providers: list # item shape: {canSignIn?: bool, canSignUp?: bool, canUnlink?: bool, countryCodes?: list, name?: string, owner?: string, prompted?: bool, provider?: record, rule?: string, signupGroup?: string}
  --redirectUris: list
  --refreshExpireInHours: float # format: double
  --samlAttributes: list # item shape: {name?: string, nameFormat?: string, value?: string}
  --samlHashAlgorithm: string
  --samlReplyUrl: string
  --signinHtml: string
  --signinItems: list # item shape: {customCss?: string, isCustom?: bool, label?: string, name?: string, placeholder?: string, rule?: string, visible?: bool}
  --signinMethods: list # item shape: {displayName?: string, name?: string, rule?: string}
  --signinUrl: string
  --signupHtml: string
  --signupItems: list # item shape: {customCss?: string, label?: string, name?: string, options?: list, placeholder?: string, prompted?: bool, regex?: string, required?: bool, rule?: string, type?: string, visible?: bool}
  --signupUrl: string
  --tags: list
  --termsOfUse: string
  --themeData: record # shape: {borderRadius?: int, colorPrimary?: string, isCompact?: bool, isEnabled?: bool, themeType?: string}
  --title: string
  --tokenAttributes: list # item shape: {name?: string, type?: string, value?: string}
  --tokenFields: list
  --tokenFormat: string
  --tokenSigningMethod: string
  --useEmailAsSamlNameId: oneof<nothing, bool>
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/add-application")
  let body = {affiliationUrl: $affiliationUrl, cert: $cert, certPublicKey: $certPublicKey, clientId: $clientId, clientSecret: $clientSecret, codeResendTimeout: $codeResendTimeout, cookieExpireInHours: $cookieExpireInHours, createdTime: $createdTime, defaultGroup: $defaultGroup, description: $description, disableSamlAttributes: $disableSamlAttributes, disableSignin: $disableSignin, displayName: $displayName, enableAutoSignin: $enableAutoSignin, enableCodeSignin: $enableCodeSignin, enableExclusiveSignin: $enableExclusiveSignin, enableLinkWithEmail: $enableLinkWithEmail, enablePassword: $enablePassword, enableSamlAssertionSignature: $enableSamlAssertionSignature, enableSamlC14n10: $enableSamlC14n10, enableSamlCompress: $enableSamlCompress, enableSamlPostBinding: $enableSamlPostBinding, enableSignUp: $enableSignUp, enableSigninSession: $enableSigninSession, enableWebAuthn: $enableWebAuthn, expireInHours: $expireInHours, failedSigninFrozenTime: $failedSigninFrozenTime, failedSigninLimit: $failedSigninLimit, favicon: $favicon, footerHtml: $footerHtml, forcedRedirectOrigin: $forcedRedirectOrigin, forgetUrl: $forgetUrl, formBackgroundUrl: $formBackgroundUrl, formBackgroundUrlMobile: $formBackgroundUrlMobile, formCss: $formCss, formCssMobile: $formCssMobile, formOffset: $formOffset, formSideHtml: $formSideHtml, grantTypes: $grantTypes, headerHtml: $headerHtml, homepageUrl: $homepageUrl, ipRestriction: $ipRestriction, ipWhitelist: $ipWhitelist, isShared: $isShared, logo: $logo, name: $name, order: $order, orgChoiceMode: $orgChoiceMode, organization: $organization, organizationObj: $organizationObj, owner: $owner, providers: $providers, redirectUris: $redirectUris, refreshExpireInHours: $refreshExpireInHours, samlAttributes: $samlAttributes, samlHashAlgorithm: $samlHashAlgorithm, samlReplyUrl: $samlReplyUrl, signinHtml: $signinHtml, signinItems: $signinItems, signinMethods: $signinMethods, signinUrl: $signinUrl, signupHtml: $signupHtml, signupItems: $signupItems, signupUrl: $signupUrl, tags: $tags, termsOfUse: $termsOfUse, themeData: $themeData, title: $title, tokenAttributes: $tokenAttributes, tokenFields: $tokenFields, tokenFormat: $tokenFormat, tokenSigningMethod: $tokenSigningMethod, useEmailAsSamlNameId: $useEmailAsSamlNameId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# add cert
#
# POST /api/add-cert
# operationId: ApiController.AddCert
export def "add-cert ApiControllerAddCert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bitSize: int # format: int64
  --certificate: string
  --createdTime: string
  --cryptoAlgorithm: string
  --displayName: string
  --expireInYears: int # format: int64
  --name: string
  --owner: string
  --privateKey: string
  --scope: string
  --type: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/add-cert")
  let body = {bitSize: $bitSize, certificate: $certificate, createdTime: $createdTime, cryptoAlgorithm: $cryptoAlgorithm, displayName: $displayName, expireInYears: $expireInYears, name: $name, owner: $owner, privateKey: $privateKey, scope: $scope, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# add enforcer
#
# POST /api/add-enforcer
# operationId: ApiController.AddEnforcer
export def "add-enforcer ApiControllerAddEnforcer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<adapter: string, createdTime: string, description: string, displayName: string, model: string, modelCfg: any, name: string, owner: string, updatedTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/add-enforcer")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# add form
#
# POST /api/add-form
# operationId: ApiController.AddForm
# --formItems item shape: {label?: string, name?: string, visible?: bool, width?: string}
export def "add-form ApiControllerAddForm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createdTime: string
  --displayName: string
  --formItems: list # item shape: {label?: string, name?: string, visible?: bool, width?: string}
  --name: string
  --owner: string
  --tag: string
  --type: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/add-form")
  let body = {createdTime: $createdTime, displayName: $displayName, formItems: $formItems, name: $name, owner: $owner, tag: $tag, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# add group
#
# POST /api/add-group
# operationId: ApiController.AddGroup
# --children item shape: {children?: list, contactEmail?: string, createdTime?: string, displayName?: string, haveChildren?: bool, isEnabled?: bool, isTopGroup?: bool, key?: string, manager?: string, name?: string, owner?: string, parentId?: string, parentName?: string, title?: string, type?: string, updatedTime?: string, users?: list}
export def "add-group ApiControllerAddGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --children: list # item shape: {children?: list, contactEmail?: string, createdTime?: string, displayName?: string, haveChildren?: bool, isEnabled?: bool, isTopGroup?: bool, key?: string, manager?: string, name?: string, owner?: string, parentId?: string, parentName?: string, title?: string, type?: string, updatedTime?: string, users?: list}
  --contactEmail: string
  --createdTime: string
  --displayName: string
  --haveChildren: oneof<nothing, bool>
  --isEnabled: oneof<nothing, bool>
  --isTopGroup: oneof<nothing, bool>
  --key: string
  --manager: string
  --name: string
  --owner: string
  --parentId: string
  --parentName: string
  --title: string
  --type: string
  --updatedTime: string
  --users: list
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/add-group")
  let body = {children: $children, contactEmail: $contactEmail, createdTime: $createdTime, displayName: $displayName, haveChildren: $haveChildren, isEnabled: $isEnabled, isTopGroup: $isTopGroup, key: $key, manager: $manager, name: $name, owner: $owner, parentId: $parentId, parentName: $parentName, title: $title, type: $type, updatedTime: $updatedTime, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# add invitation
#
# POST /api/add-invitation
# operationId: ApiController.AddInvitation
export def "add-invitation ApiControllerAddInvitation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --application: string
  --code: string
  --createdTime: string
  --defaultCode: string
  --displayName: string
  --email: string
  --isRegexp: oneof<nothing, bool>
  --name: string
  --owner: string
  --phone: string
  --quota: int # format: int64
  --signupGroup: string
  --state: string
  --updatedTime: string
  --usedCount: int # format: int64
  --username: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/add-invitation")
  let body = {application: $application, code: $code, createdTime: $createdTime, defaultCode: $defaultCode, displayName: $displayName, email: $email, isRegexp: $isRegexp, name: $name, owner: $owner, phone: $phone, quota: $quota, signupGroup: $signupGroup, state: $state, updatedTime: $updatedTime, usedCount: $usedCount, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# add ldap
#
# POST /api/add-ldap
# operationId: ApiController.AddLdap
export def "add-ldap ApiControllerAddLdap" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allowSelfSignedCert: oneof<nothing, bool>
  --autoSync: int # format: int64
  --baseDn: string
  --createdTime: string
  --customAttributes: any
  --defaultGroup: string
  --enableSsl: oneof<nothing, bool>
  --filter: string
  --filterFields: list
  --host: string
  --id: string
  --lastSync: string
  --owner: string
  --password: string
  --passwordType: string
  --port: int # format: int64
  --serverName: string
  --username: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/add-ldap")
  let body = {allowSelfSignedCert: $allowSelfSignedCert, autoSync: $autoSync, baseDn: $baseDn, createdTime: $createdTime, customAttributes: $customAttributes, defaultGroup: $defaultGroup, enableSsl: $enableSsl, filter: $filter, filterFields: $filterFields, host: $host, id: $id, lastSync: $lastSync, owner: $owner, password: $password, passwordType: $passwordType, port: $port, serverName: $serverName, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# add model
#
# POST /api/add-model
# operationId: ApiController.AddModel
export def "add-model ApiControllerAddModel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createdTime: string
  --description: string
  --displayName: string
  --modelText: string
  --name: string
  --owner: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/add-model")
  let body = {createdTime: $createdTime, description: $description, displayName: $displayName, modelText: $modelText, name: $name, owner: $owner} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# add order
#
# POST /api/add-order
# operationId: ApiController.AddOrder
# --productInfos item shape: {currency?: string, detail?: string, displayName?: string, image?: string, isRecharge?: bool, name?: string, owner?: string, planName?: string, price?: float, pricingName?: string, quantity?: int}
export def "add-order ApiControllerAddOrder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createdTime: string
  --currency: string
  --displayName: string
  --message: string
  --name: string
  --owner: string
  --payment: string
  --price: float # format: double
  --productInfos: list # item shape: {currency?: string, detail?: string, displayName?: string, image?: string, isRecharge?: bool, name?: string, owner?: string, planName?: string, price?: float, pricingName?: string, quantity?: int}
  --products: list
  --state: string
  --updateTime: string
  --user: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/add-order")
  let body = {createdTime: $createdTime, currency: $currency, displayName: $displayName, message: $message, name: $name, owner: $owner, payment: $payment, price: $price, productInfos: $productInfos, products: $products, state: $state, updateTime: $updateTime, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# add organization
#
# POST /api/add-organization
# operationId: ApiController.AddOrganization
# --accountItems item shape: {modifyRule?: string, name?: string, regex?: string, tab?: string, viewRule?: string, visible?: bool}
# --mfaItems item shape: {name?: string, rule?: string}
# --themeData shape: {borderRadius?: int, colorPrimary?: string, isCompact?: bool, isEnabled?: bool, themeType?: string}
export def "add-organization ApiControllerAddOrganization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountItems: list # item shape: {modifyRule?: string, name?: string, regex?: string, tab?: string, viewRule?: string, visible?: bool}
  --accountMenu: string
  --balanceCredit: float # format: double
  --balanceCurrency: string
  --countryCodes: list
  --createdTime: string
  --defaultApplication: string
  --defaultAvatar: string
  --defaultPassword: string
  --disableSignin: oneof<nothing, bool>
  --displayName: string
  --enableSoftDeletion: oneof<nothing, bool>
  --enableTour: oneof<nothing, bool>
  --favicon: string
  --hasPrivilegeConsent: oneof<nothing, bool>
  --initScore: int # format: int64
  --ipRestriction: string
  --ipWhitelist: string
  --isProfilePublic: oneof<nothing, bool>
  --languages: list
  --logo: string
  --logoDark: string
  --masterPassword: string
  --masterVerificationCode: string
  --mfaItems: list # item shape: {name?: string, rule?: string}
  --mfaRememberInHours: int # format: int64
  --name: string
  --navItems: list
  --orgBalance: float # format: double
  --owner: string
  --passwordExpireDays: int # format: int64
  --passwordObfuscatorKey: string
  --passwordObfuscatorType: string
  --passwordOptions: list
  --passwordSalt: string
  --passwordType: string
  --tags: list
  --themeData: record # shape: {borderRadius?: int, colorPrimary?: string, isCompact?: bool, isEnabled?: bool, themeType?: string}
  --useEmailAsUsername: oneof<nothing, bool>
  --userBalance: float # format: double
  --userNavItems: list
  --userTypes: list
  --websiteUrl: string
  --widgetItems: list
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/add-organization")
  let body = {accountItems: $accountItems, accountMenu: $accountMenu, balanceCredit: $balanceCredit, balanceCurrency: $balanceCurrency, countryCodes: $countryCodes, createdTime: $createdTime, defaultApplication: $defaultApplication, defaultAvatar: $defaultAvatar, defaultPassword: $defaultPassword, disableSignin: $disableSignin, displayName: $displayName, enableSoftDeletion: $enableSoftDeletion, enableTour: $enableTour, favicon: $favicon, hasPrivilegeConsent: $hasPrivilegeConsent, initScore: $initScore, ipRestriction: $ipRestriction, ipWhitelist: $ipWhitelist, isProfilePublic: $isProfilePublic, languages: $languages, logo: $logo, logoDark: $logoDark, masterPassword: $masterPassword, masterVerificationCode: $masterVerificationCode, mfaItems: $mfaItems, mfaRememberInHours: $mfaRememberInHours, name: $name, navItems: $navItems, orgBalance: $orgBalance, owner: $owner, passwordExpireDays: $passwordExpireDays, passwordObfuscatorKey: $passwordObfuscatorKey, passwordObfuscatorType: $passwordObfuscatorType, passwordOptions: $passwordOptions, passwordSalt: $passwordSalt, passwordType: $passwordType, tags: $tags, themeData: $themeData, useEmailAsUsername: $useEmailAsUsername, userBalance: $userBalance, userNavItems: $userNavItems, userTypes: $userTypes, websiteUrl: $websiteUrl, widgetItems: $widgetItems} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# add payment
#
# POST /api/add-payment
# operationId: ApiController.AddPayment
# --orderObj shape: {createdTime?: string, currency?: string, displayName?: string, message?: string, name?: string, owner?: string, payment?: string, price?: float, productInfos?: list, products?: list, state?: string, updateTime?: string, user?: string}
export def "add-payment ApiControllerAddPayment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createdTime: string
  --currency: string
  --detail: string
  --displayName: string
  --invoiceRemark: string
  --invoiceTaxId: string
  --invoiceTitle: string
  --invoiceType: string
  --invoiceUrl: string
  --message: string
  --name: string
  --order: string
  --orderObj: record # shape: {createdTime?: string, currency?: string, displayName?: string, message?: string, name?: string, owner?: string, payment?: string, price?: float, productInfos?: list, products?: list, state?: string, updateTime?: string, user?: string}
  --outOrderId: string
  --owner: string
  --payUrl: string
  --personEmail: string
  --personIdCard: string
  --personName: string
  --personPhone: string
  --price: float # format: double
  --products: list
  --productsDisplayName: string
  --provider: string
  --state: string@state-completer # e.g. Paid
  --successUrl: string
  --type: string
  --user: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/add-payment")
  let body = {createdTime: $createdTime, currency: $currency, detail: $detail, displayName: $displayName, invoiceRemark: $invoiceRemark, invoiceTaxId: $invoiceTaxId, invoiceTitle: $invoiceTitle, invoiceType: $invoiceType, invoiceUrl: $invoiceUrl, message: $message, name: $name, order: $order, orderObj: $orderObj, outOrderId: $outOrderId, owner: $owner, payUrl: $payUrl, personEmail: $personEmail, personIdCard: $personIdCard, personName: $personName, personPhone: $personPhone, price: $price, products: $products, productsDisplayName: $productsDisplayName, provider: $provider, state: $state, successUrl: $successUrl, type: $type, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# add permission
#
# POST /api/add-permission
# operationId: ApiController.AddPermission
export def "add-permission ApiControllerAddPermission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --actions: list
  --adapter: string
  --approveTime: string
  --approver: string
  --createdTime: string
  --description: string
  --displayName: string
  --domains: list
  --effect: string
  --groups: list
  --isEnabled: oneof<nothing, bool>
  --model: string
  --name: string
  --owner: string
  --resourceType: string
  --resources: list
  --roles: list
  --state: string
  --submitter: string
  --users: list
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/add-permission")
  let body = {actions: $actions, adapter: $adapter, approveTime: $approveTime, approver: $approver, createdTime: $createdTime, description: $description, displayName: $displayName, domains: $domains, effect: $effect, groups: $groups, isEnabled: $isEnabled, model: $model, name: $name, owner: $owner, resourceType: $resourceType, resources: $resources, roles: $roles, state: $state, submitter: $submitter, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# add plan
#
# POST /api/add-plan
# operationId: ApiController.AddPlan
export def "add-plan ApiControllerAddPlan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createdTime: string
  --currency: string
  --description: string
  --displayName: string
  --isEnabled: oneof<nothing, bool>
  --name: string
  --options: list
  --owner: string
  --paymentProviders: list
  --period: string
  --price: float # format: double
  --product: string
  --role: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/add-plan")
  let body = {createdTime: $createdTime, currency: $currency, description: $description, displayName: $displayName, isEnabled: $isEnabled, name: $name, options: $options, owner: $owner, paymentProviders: $paymentProviders, period: $period, price: $price, product: $product, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# add policy
#
# POST /api/add-policy
# operationId: ApiController.AddPolicy
export def "add-policy ApiControllerAddPolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name )  of enforcer
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/add-policy" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# add pricing
#
# POST /api/add-pricing
# operationId: ApiController.AddPricing
export def "add-pricing ApiControllerAddPricing" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --application: string
  --createdTime: string
  --description: string
  --displayName: string
  --isEnabled: oneof<nothing, bool>
  --name: string
  --owner: string
  --plans: list
  --trialDuration: int # format: int64
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/add-pricing")
  let body = {application: $application, createdTime: $createdTime, description: $description, displayName: $displayName, isEnabled: $isEnabled, name: $name, owner: $owner, plans: $plans, trialDuration: $trialDuration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# add product
#
# POST /api/add-product
# operationId: ApiController.AddProduct
# --providerObjs item shape: {appId?: string, bucket?: string, category?: string, cert?: string, clientId?: string, clientId2?: string, clientSecret?: string, clientSecret2?: string, content?: string, createdTime?: string, customAuthUrl?: string, customLogo?: string, customTokenUrl?: string, customUserInfoUrl?: string, disableSsl?: bool, displayName?: string, domain?: string, emailRegex?: string, enablePkce?: bool, enableProxy?: bool, enableSignAuthnRequest?: bool, endpoint?: string, host?: string, httpHeaders?: any, idP?: string, intranetEndpoint?: string, issuerUrl?: string, metadata?: string, method?: string, name?: string, owner?: string, pathPrefix?: string, port?: int, providerUrl?: string, receiver?: string, regionId?: string, scopes?: string, signName?: string, subType?: string, templateCode?: string, title?: string, type?: string, userMapping?: any}
export def "add-product ApiControllerAddProduct" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createdTime: string
  --currency: string
  --description: string
  --detail: string
  --disableCustomRecharge: oneof<nothing, bool>
  --displayName: string
  --image: string
  --isRecharge: oneof<nothing, bool>
  --name: string
  --owner: string
  --price: float # format: double
  --providerObjs: list # item shape: {appId?: string, bucket?: string, category?: string, cert?: string, clientId?: string, clientId2?: string, clientSecret?: string, clientSecret2?: string, content?: string, createdTime?: string, customAuthUrl?: string, customLogo?: string, customTokenUrl?: string, customUserInfoUrl?: string, disableSsl?: bool, displayName?: string, domain?: string, emailRegex?: string, enablePkce?: bool, enableProxy?: bool, enableSignAuthnRequest?: bool, endpoint?: string, host?: string, httpHeaders?: any, idP?: string, intranetEndpoint?: string, issuerUrl?: string, metadata?: string, method?: string, name?: string, owner?: string, pathPrefix?: string, port?: int, providerUrl?: string, receiver?: string, regionId?: string, scopes?: string, signName?: string, subType?: string, templateCode?: string, title?: string, type?: string, userMapping?: any}
  --providers: list
  --quantity: int # format: int64
  --rechargeOptions: list
  --sold: int # format: int64
  --state: string
  --successUrl: string
  --tag: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/add-product")
  let body = {createdTime: $createdTime, currency: $currency, description: $description, detail: $detail, disableCustomRecharge: $disableCustomRecharge, displayName: $displayName, image: $image, isRecharge: $isRecharge, name: $name, owner: $owner, price: $price, providerObjs: $providerObjs, providers: $providers, quantity: $quantity, rechargeOptions: $rechargeOptions, sold: $sold, state: $state, successUrl: $successUrl, tag: $tag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# add provider
#
# POST /api/add-provider
# operationId: ApiController.AddProvider
export def "add-provider ApiControllerAddProvider" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --appId: string
  --bucket: string
  --category: string
  --cert: string
  --clientId: string
  --clientId2: string
  --clientSecret: string
  --clientSecret2: string
  --content: string
  --createdTime: string
  --customAuthUrl: string
  --customLogo: string
  --customTokenUrl: string
  --customUserInfoUrl: string
  --disableSsl: oneof<nothing, bool>
  --displayName: string
  --domain: string
  --emailRegex: string
  --enablePkce: oneof<nothing, bool>
  --enableProxy: oneof<nothing, bool>
  --enableSignAuthnRequest: oneof<nothing, bool>
  --endpoint: string
  --host: string
  --httpHeaders: any
  --idP: string
  --intranetEndpoint: string
  --issuerUrl: string
  --metadata: string
  --method: string
  --name: string
  --owner: string
  --pathPrefix: string
  --port: int # format: int64
  --providerUrl: string
  --receiver: string
  --regionId: string
  --scopes: string
  --signName: string
  --subType: string
  --templateCode: string
  --title: string
  --type: string
  --userMapping: any
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/add-provider")
  let body = {appId: $appId, bucket: $bucket, category: $category, cert: $cert, clientId: $clientId, clientId2: $clientId2, clientSecret: $clientSecret, clientSecret2: $clientSecret2, content: $content, createdTime: $createdTime, customAuthUrl: $customAuthUrl, customLogo: $customLogo, customTokenUrl: $customTokenUrl, customUserInfoUrl: $customUserInfoUrl, disableSsl: $disableSsl, displayName: $displayName, domain: $domain, emailRegex: $emailRegex, enablePkce: $enablePkce, enableProxy: $enableProxy, enableSignAuthnRequest: $enableSignAuthnRequest, endpoint: $endpoint, host: $host, httpHeaders: $httpHeaders, idP: $idP, intranetEndpoint: $intranetEndpoint, issuerUrl: $issuerUrl, metadata: $metadata, method: $method, name: $name, owner: $owner, pathPrefix: $pathPrefix, port: $port, providerUrl: $providerUrl, receiver: $receiver, regionId: $regionId, scopes: $scopes, signName: $signName, subType: $subType, templateCode: $templateCode, title: $title, type: $type, userMapping: $userMapping} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# add a record
#
# POST /api/add-record
# operationId: ApiController.AddRecord
export def "add-record ApiControllerAddRecord" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/add-record")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /api/add-resource
#
# operationId: ApiController.AddResource
export def "add-resource ApiControllerAddResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --application: string
  --createdTime: string
  --description: string
  --fileFormat: string
  --fileName: string
  --fileSize: int # format: int64
  --fileType: string
  --name: string
  --owner: string
  --parent: string
  --provider: string
  --tag: string
  --body-url: string
  --user: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/add-resource")
  let body = {application: $application, createdTime: $createdTime, description: $description, fileFormat: $fileFormat, fileName: $fileName, fileSize: $fileSize, fileType: $fileType, name: $name, owner: $owner, parent: $parent, provider: $provider, tag: $tag, url: $body_url, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# add role
#
# POST /api/add-role
# operationId: ApiController.AddRole
export def "add-role ApiControllerAddRole" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createdTime: string
  --description: string
  --displayName: string
  --domains: list
  --groups: list
  --isEnabled: oneof<nothing, bool>
  --name: string
  --owner: string
  --roles: list
  --users: list
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/add-role")
  let body = {createdTime: $createdTime, description: $description, displayName: $displayName, domains: $domains, groups: $groups, isEnabled: $isEnabled, name: $name, owner: $owner, roles: $roles, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add session for one user in one application. If there are other existing sessions, join the session into the list.
#
# POST /api/add-session
# operationId: ApiController.AddSession
export def "add-session ApiControllerAddSession" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ExclusiveSignin: oneof<nothing, bool>
  --application: string
  --createdTime: string
  --name: string
  --owner: string
  --sessionId: list
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/add-session")
  let body = {ExclusiveSignin: $ExclusiveSignin, application: $application, createdTime: $createdTime, name: $name, owner: $owner, sessionId: $sessionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# add subscription
#
# POST /api/add-subscription
# operationId: ApiController.AddSubscription
export def "add-subscription ApiControllerAddSubscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createdTime: string
  --description: string
  --displayName: string
  --endTime: string
  --name: string
  --owner: string
  --payment: string
  --period: string
  --plan: string
  --pricing: string
  --startTime: string
  --state: string@state-completer-1 # e.g. Pending
  --user: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/add-subscription")
  let body = {createdTime: $createdTime, description: $description, displayName: $displayName, endTime: $endTime, name: $name, owner: $owner, payment: $payment, period: $period, plan: $plan, pricing: $pricing, startTime: $startTime, state: $state, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# add syncer
#
# POST /api/add-syncer
# operationId: ApiController.AddSyncer
# --tableColumns item shape: {casdoorName?: string, isHashed?: bool, isKey?: bool, name?: string, type?: string, values?: list}
export def "add-syncer ApiControllerAddSyncer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --affiliationTable: string
  --avatarBaseUrl: string
  --cert: string
  --createdTime: string
  --database: string
  --databaseType: string
  --errorText: string
  --host: string
  --isEnabled: oneof<nothing, bool>
  --isReadOnly: oneof<nothing, bool>
  --name: string
  --organization: string
  --owner: string
  --password: string
  --port: int # format: int64
  --sshHost: string
  --sshPassword: string
  --sshPort: int # format: int64
  --sshType: string
  --sshUser: string
  --sslMode: string
  --syncInterval: int # format: int64
  --table: string
  --tableColumns: list # item shape: {casdoorName?: string, isHashed?: bool, isKey?: bool, name?: string, type?: string, values?: list}
  --type: string
  --user: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/add-syncer")
  let body = {affiliationTable: $affiliationTable, avatarBaseUrl: $avatarBaseUrl, cert: $cert, createdTime: $createdTime, database: $database, databaseType: $databaseType, errorText: $errorText, host: $host, isEnabled: $isEnabled, isReadOnly: $isReadOnly, name: $name, organization: $organization, owner: $owner, password: $password, port: $port, sshHost: $sshHost, sshPassword: $sshPassword, sshPort: $sshPort, sshType: $sshType, sshUser: $sshUser, sslMode: $sslMode, syncInterval: $syncInterval, table: $table, tableColumns: $tableColumns, type: $type, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# add ticket
#
# POST /api/add-ticket
# operationId: ApiController.AddTicket
# --messages item shape: {author?: string, isAdmin?: bool, text?: string, timestamp?: string}
export def "add-ticket ApiControllerAddTicket" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --content: string
  --createdTime: string
  --displayName: string
  --messages: list # item shape: {author?: string, isAdmin?: bool, text?: string, timestamp?: string}
  --name: string
  --owner: string
  --state: string
  --title: string
  --updatedTime: string
  --user: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/add-ticket")
  let body = {content: $content, createdTime: $createdTime, displayName: $displayName, messages: $messages, name: $name, owner: $owner, state: $state, title: $title, updatedTime: $updatedTime, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# add a message to a ticket
#
# POST /api/add-ticket-message
# operationId: ApiController.AddTicketMessage
export def "add-ticket-message ApiControllerAddTicketMessage" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the ticket
  --author: string
  --isAdmin: oneof<nothing, bool>
  --text: string
  --timestamp: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/add-ticket-message" $qp)
  let body = {author: $author, isAdmin: $isAdmin, text: $text, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# add token
#
# POST /api/add-token
# operationId: ApiController.AddToken
export def "add-token ApiControllerAddToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accessToken: string
  --accessTokenHash: string
  --application: string
  --code: string
  --codeChallenge: string
  --codeExpireIn: int # format: int64
  --codeIsUsed: oneof<nothing, bool>
  --createdTime: string
  --expiresIn: int # format: int64
  --name: string
  --organization: string
  --owner: string
  --refreshToken: string
  --refreshTokenHash: string
  --scope: string
  --tokenType: string
  --user: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/add-token")
  let body = {accessToken: $accessToken, accessTokenHash: $accessTokenHash, application: $application, code: $code, codeChallenge: $codeChallenge, codeExpireIn: $codeExpireIn, codeIsUsed: $codeIsUsed, createdTime: $createdTime, expiresIn: $expiresIn, name: $name, organization: $organization, owner: $owner, refreshToken: $refreshToken, refreshTokenHash: $refreshTokenHash, scope: $scope, tokenType: $tokenType, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# add transaction
#
# POST /api/add-transaction
# operationId: ApiController.AddTransaction
export def "add-transaction ApiControllerAddTransaction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dryRun: string # Dry run mode: set to 'true' or '1' to validate without committing
  --amount: float # format: double
  --application: string
  --category: string@category-completer # e.g. Purchase
  --createdTime: string
  --currency: string
  --displayName: string
  --domain: string
  --name: string
  --owner: string
  --payment: string
  --provider: string
  --state: string
  --subtype: string
  --tag: string
  --type: string
  --user: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "dryRun" $dryRun "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/add-transaction" $qp)
  let body = {amount: $amount, application: $application, category: $category, createdTime: $createdTime, currency: $currency, displayName: $displayName, domain: $domain, name: $name, owner: $owner, payment: $payment, provider: $provider, state: $state, subtype: $subtype, tag: $tag, type: $type, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# add user
#
# POST /api/add-user
# operationId: ApiController.AddUser
# --addresses item shape: {city?: string, line1?: string, line2?: string, region?: string, state?: string, tag?: string, zipCode?: string}
# --cart item shape: {currency?: string, detail?: string, displayName?: string, image?: string, isRecharge?: bool, name?: string, owner?: string, planName?: string, price?: float, pricingName?: string, quantity?: int}
# --faceIds item shape: {ImageUrl?: string, faceIdData?: list, name?: string}
# --managedAccounts item shape: {application?: string, password?: string, signinUrl?: string, username?: string}
# --mfaAccounts item shape: {accountName?: string, issuer?: string, origin?: string, secretKey?: string}
# --mfaItems item shape: {name?: string, rule?: string}
# --multiFactorAuths item shape: {countryCode?: string, enabled?: bool, isPreferred?: bool, mfaRememberInHours?: int, mfaType?: string, recoveryCodes?: list, secret?: string, url?: string}
# --permissions item shape: {actions?: list, adapter?: string, approveTime?: string, approver?: string, createdTime?: string, description?: string, displayName?: string, domains?: list, effect?: string, groups?: list, isEnabled?: bool, model?: string, name?: string, owner?: string, resourceType?: string, resources?: list, roles?: list, state?: string, submitter?: string, users?: list}
# --roles item shape: {createdTime?: string, description?: string, displayName?: string, domains?: list, groups?: list, isEnabled?: bool, name?: string, owner?: string, roles?: list, users?: list}
export def "add-user ApiControllerAddUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accessKey: string
  --accessSecret: string
  --accessToken: string
  --address: list
  --addresses: list # item shape: {city?: string, line1?: string, line2?: string, region?: string, state?: string, tag?: string, zipCode?: string}
  --adfs: string
  --affiliation: string
  --alipay: string
  --amazon: string
  --apple: string
  --auth0: string
  --avatar: string
  --avatarType: string
  --azuread: string
  --azureadb2c: string
  --baidu: string
  --balance: float # format: double
  --balanceCredit: float # format: double
  --balanceCurrency: string
  --battlenet: string
  --bilibili: string
  --bio: string
  --birthday: string
  --bitbucket: string
  --box: string
  --cart: list # item shape: {currency?: string, detail?: string, displayName?: string, image?: string, isRecharge?: bool, name?: string, owner?: string, planName?: string, price?: float, pricingName?: string, quantity?: int}
  --casdoor: string
  --cloudfoundry: string
  --countryCode: string
  --createdIp: string
  --createdTime: string
  --currency: string
  --custom: string
  --custom10: string
  --custom2: string
  --custom3: string
  --custom4: string
  --custom5: string
  --custom6: string
  --custom7: string
  --custom8: string
  --custom9: string
  --dailymotion: string
  --deezer: string
  --deletedTime: string
  --digitalocean: string
  --dingtalk: string
  --discord: string
  --displayName: string
  --douyin: string
  --dropbox: string
  --education: string
  --email: string
  --emailVerified: oneof<nothing, bool>
  --eveonline: string
  --externalId: string
  --faceIds: list # item shape: {ImageUrl?: string, faceIdData?: list, name?: string}
  --facebook: string
  --firstName: string
  --fitbit: string
  --gender: string
  --gitea: string
  --gitee: string
  --github: string
  --gitlab: string
  --google: string
  --groups: list
  --hash: string
  --heroku: string
  --homepage: string
  --id: string
  --idCard: string
  --idCardType: string
  --influxcloud: string
  --infoflow: string
  --instagram: string
  --intercom: string
  --invitation: string
  --invitationCode: string
  --ipWhitelist: string
  --isAdmin: oneof<nothing, bool>
  --isDefaultAvatar: oneof<nothing, bool>
  --isDeleted: oneof<nothing, bool>
  --isForbidden: oneof<nothing, bool>
  --isOnline: oneof<nothing, bool>
  --isVerified: oneof<nothing, bool>
  --kakao: string
  --karma: int # format: int64
  --kwai: string
  --language: string
  --lark: string
  --lastChangePasswordTime: string
  --lastName: string
  --lastSigninIp: string
  --lastSigninTime: string
  --lastSigninWrongTime: string
  --lastfm: string
  --ldap: string
  --line: string
  --linkedin: string
  --location: string
  --mailru: string
  --managedAccounts: list # item shape: {application?: string, password?: string, signinUrl?: string, username?: string}
  --meetup: string
  --metamask: string
  --mfaAccounts: list # item shape: {accountName?: string, issuer?: string, origin?: string, secretKey?: string}
  --mfaEmailEnabled: oneof<nothing, bool>
  --mfaItems: list # item shape: {name?: string, rule?: string}
  --mfaPhoneEnabled: oneof<nothing, bool>
  --mfaPushEnabled: oneof<nothing, bool>
  --mfaPushProvider: string
  --mfaPushReceiver: string
  --mfaRadiusEnabled: oneof<nothing, bool>
  --mfaRadiusProvider: string
  --mfaRadiusUsername: string
  --mfaRememberDeadline: string
  --microsoftonline: string
  --multiFactorAuths: list # item shape: {countryCode?: string, enabled?: bool, isPreferred?: bool, mfaRememberInHours?: int, mfaType?: string, recoveryCodes?: list, secret?: string, url?: string}
  --name: string
  --naver: string
  --needUpdatePassword: oneof<nothing, bool>
  --nextcloud: string
  --okta: string
  --onedrive: string
  --originalRefreshToken: string
  --originalToken: string
  --oura: string
  --owner: string
  --password: string
  --passwordSalt: string
  --passwordType: string
  --patreon: string
  --paypal: string
  --permanentAvatar: string
  --permissions: list # item shape: {actions?: list, adapter?: string, approveTime?: string, approver?: string, createdTime?: string, description?: string, displayName?: string, domains?: list, effect?: string, groups?: list, isEnabled?: bool, model?: string, name?: string, owner?: string, resourceType?: string, resources?: list, roles?: list, state?: string, submitter?: string, users?: list}
  --phone: string
  --preHash: string
  --preferredMfaType: string
  --properties: any
  --qq: string
  --ranking: int # format: int64
  --realName: string
  --recoveryCodes: list
  --region: string
  --registerSource: string
  --registerType: string
  --roles: list # item shape: {createdTime?: string, description?: string, displayName?: string, domains?: list, groups?: list, isEnabled?: bool, name?: string, owner?: string, roles?: list, users?: list}
  --salesforce: string
  --score: int # format: int64
  --shopify: string
  --signinWrongTimes: int # format: int64
  --signupApplication: string
  --slack: string
  --soundcloud: string
  --spotify: string
  --steam: string
  --strava: string
  --stripe: string
  --tag: string
  --tiktok: string
  --title: string
  --totpSecret: string
  --tumblr: string
  --twitch: string
  --twitter: string
  --type: string
  --typetalk: string
  --uber: string
  --updatedTime: string
  --vk: string
  --web3onboard: string
  --webauthnCredentials: list
  --wechat: string
  --wecom: string
  --weibo: string
  --wepay: string
  --xero: string
  --yahoo: string
  --yammer: string
  --yandex: string
  --zoom: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/add-user")
  let body = {accessKey: $accessKey, accessSecret: $accessSecret, accessToken: $accessToken, address: $address, addresses: $addresses, adfs: $adfs, affiliation: $affiliation, alipay: $alipay, amazon: $amazon, apple: $apple, auth0: $auth0, avatar: $avatar, avatarType: $avatarType, azuread: $azuread, azureadb2c: $azureadb2c, baidu: $baidu, balance: $balance, balanceCredit: $balanceCredit, balanceCurrency: $balanceCurrency, battlenet: $battlenet, bilibili: $bilibili, bio: $bio, birthday: $birthday, bitbucket: $bitbucket, box: $box, cart: $cart, casdoor: $casdoor, cloudfoundry: $cloudfoundry, countryCode: $countryCode, createdIp: $createdIp, createdTime: $createdTime, currency: $currency, custom: $custom, custom10: $custom10, custom2: $custom2, custom3: $custom3, custom4: $custom4, custom5: $custom5, custom6: $custom6, custom7: $custom7, custom8: $custom8, custom9: $custom9, dailymotion: $dailymotion, deezer: $deezer, deletedTime: $deletedTime, digitalocean: $digitalocean, dingtalk: $dingtalk, discord: $discord, displayName: $displayName, douyin: $douyin, dropbox: $dropbox, education: $education, email: $email, emailVerified: $emailVerified, eveonline: $eveonline, externalId: $externalId, faceIds: $faceIds, facebook: $facebook, firstName: $firstName, fitbit: $fitbit, gender: $gender, gitea: $gitea, gitee: $gitee, github: $github, gitlab: $gitlab, google: $google, groups: $groups, hash: $hash, heroku: $heroku, homepage: $homepage, id: $id, idCard: $idCard, idCardType: $idCardType, influxcloud: $influxcloud, infoflow: $infoflow, instagram: $instagram, intercom: $intercom, invitation: $invitation, invitationCode: $invitationCode, ipWhitelist: $ipWhitelist, isAdmin: $isAdmin, isDefaultAvatar: $isDefaultAvatar, isDeleted: $isDeleted, isForbidden: $isForbidden, isOnline: $isOnline, isVerified: $isVerified, kakao: $kakao, karma: $karma, kwai: $kwai, language: $language, lark: $lark, lastChangePasswordTime: $lastChangePasswordTime, lastName: $lastName, lastSigninIp: $lastSigninIp, lastSigninTime: $lastSigninTime, lastSigninWrongTime: $lastSigninWrongTime, lastfm: $lastfm, ldap: $ldap, line: $line, linkedin: $linkedin, location: $location, mailru: $mailru, managedAccounts: $managedAccounts, meetup: $meetup, metamask: $metamask, mfaAccounts: $mfaAccounts, mfaEmailEnabled: $mfaEmailEnabled, mfaItems: $mfaItems, mfaPhoneEnabled: $mfaPhoneEnabled, mfaPushEnabled: $mfaPushEnabled, mfaPushProvider: $mfaPushProvider, mfaPushReceiver: $mfaPushReceiver, mfaRadiusEnabled: $mfaRadiusEnabled, mfaRadiusProvider: $mfaRadiusProvider, mfaRadiusUsername: $mfaRadiusUsername, mfaRememberDeadline: $mfaRememberDeadline, microsoftonline: $microsoftonline, multiFactorAuths: $multiFactorAuths, name: $name, naver: $naver, needUpdatePassword: $needUpdatePassword, nextcloud: $nextcloud, okta: $okta, onedrive: $onedrive, originalRefreshToken: $originalRefreshToken, originalToken: $originalToken, oura: $oura, owner: $owner, password: $password, passwordSalt: $passwordSalt, passwordType: $passwordType, patreon: $patreon, paypal: $paypal, permanentAvatar: $permanentAvatar, permissions: $permissions, phone: $phone, preHash: $preHash, preferredMfaType: $preferredMfaType, properties: $properties, qq: $qq, ranking: $ranking, realName: $realName, recoveryCodes: $recoveryCodes, region: $region, registerSource: $registerSource, registerType: $registerType, roles: $roles, salesforce: $salesforce, score: $score, shopify: $shopify, signinWrongTimes: $signinWrongTimes, signupApplication: $signupApplication, slack: $slack, soundcloud: $soundcloud, spotify: $spotify, steam: $steam, strava: $strava, stripe: $stripe, tag: $tag, tiktok: $tiktok, title: $title, totpSecret: $totpSecret, tumblr: $tumblr, twitch: $twitch, twitter: $twitter, type: $type, typetalk: $typetalk, uber: $uber, updatedTime: $updatedTime, vk: $vk, web3onboard: $web3onboard, webauthnCredentials: $webauthnCredentials, wechat: $wechat, wecom: $wecom, weibo: $weibo, wepay: $wepay, xero: $xero, yahoo: $yahoo, yammer: $yammer, yandex: $yandex, zoom: $zoom} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /api/add-user-keys
#
# operationId: ApiController.AddUserKeys
export def "add-user-keys ApiControllerAddUserKeys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<address: string, aud: string, email: string, email_verified: bool, groups: list<string>, is_verified: bool, iss: string, name: string, permissions: list<string>, phone: string, picture: string, preferred_username: string, real_name: string, roles: list<string>, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/add-user-keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# add webhook
#
# POST /api/add-webhook
# operationId: ApiController.AddWebhook
# --headers item shape: {name?: string, value?: string}
export def "add-webhook ApiControllerAddWebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contentType: string
  --createdTime: string
  --events: list
  --headers: list # item shape: {name?: string, value?: string}
  --isEnabled: oneof<nothing, bool>
  --isUserExtended: oneof<nothing, bool>
  --method: string
  --name: string
  --objectFields: list
  --organization: string
  --owner: string
  --singleOrgOnly: oneof<nothing, bool>
  --tokenFields: list
  --body-url: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/add-webhook")
  let body = {contentType: $contentType, createdTime: $createdTime, events: $events, headers: $headers, isEnabled: $isEnabled, isUserExtended: $isUserExtended, method: $method, name: $name, objectFields: $objectFields, organization: $organization, owner: $owner, singleOrgOnly: $singleOrgOnly, tokenFields: $tokenFields, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Call Casbin BatchEnforce API
#
# POST /api/batch-enforce
# operationId: ApiController.BatchEnforce
export def "batch-enforce ApiControllerBatchEnforce" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --permissionId: string # permission id
  --modelId: string # model id
  --owner: string # owner
  --body: record
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "permissionId" $permissionId "scalar") (serialize-qp "modelId" $modelId "scalar") (serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/batch-enforce" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# cancel an order
#
# POST /api/cancel-order
# operationId: ApiController.CancelOrder
export def "cancel-order ApiControllerCancelOrder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the order
]: nothing -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/cancel-order" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/check-user-password
#
# operationId: ApiController.CheckUserPassword
export def "check-user-password ApiControllerCheckUserPassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<address: string, aud: string, email: string, email_verified: bool, groups: list<string>, is_verified: bool, iss: string, name: string, permissions: list<string>, phone: string, picture: string, preferred_username: string, real_name: string, roles: list<string>, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/check-user-password")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# buy product using the deprecated compatibility endpoint, prefer place-order plus pay-order for new integrations
#
# POST /api/buy-product
# DEPRECATED
# operationId: ApiController.BuyProduct
@deprecated
export def "buy-product ApiControllerBuyProduct" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the product
  --providerName: string # The name of the provider
  --pricingName: string # The name of the pricing (for subscription)
  --planName: string # The name of the plan (for subscription)
  --userName: string # The username to buy product for (admin only)
  --paymentEnv: string # The payment environment
  --customPrice: float # Custom price for recharge products
]: nothing -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "providerName" $providerName "scalar") (serialize-qp "pricingName" $pricingName "scalar") (serialize-qp "planName" $planName "scalar") (serialize-qp "userName" $userName "scalar") (serialize-qp "paymentEnv" $paymentEnv "scalar") (serialize-qp "customPrice" $customPrice "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/buy-product" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# delete adapter
#
# POST /api/delete-adapter
# operationId: ApiController.DeleteAdapter
export def "delete-adapter ApiControllerDeleteAdapter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createdTime: string
  --database: string
  --databaseType: string
  --host: string
  --name: string
  --owner: string
  --password: string
  --port: int # format: int64
  --table: string
  --type: string
  --useSameDb: oneof<nothing, bool>
  --user: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/delete-adapter")
  let body = {createdTime: $createdTime, database: $database, databaseType: $databaseType, host: $host, name: $name, owner: $owner, password: $password, port: $port, table: $table, type: $type, useSameDb: $useSameDb, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# delete an application
#
# POST /api/delete-application
# operationId: ApiController.DeleteApplication
# --organizationObj shape: {accountItems?: list, accountMenu?: string, balanceCredit?: float, balanceCurrency?: string, countryCodes?: list, createdTime?: string, defaultApplication?: string, defaultAvatar?: string, defaultPassword?: string, disableSignin?: bool, displayName?: string, enableSoftDeletion?: bool, enableTour?: bool, favicon?: string, hasPrivilegeConsent?: bool, initScore?: int, ipRestriction?: string, ipWhitelist?: string, isProfilePublic?: bool, languages?: list, logo?: string, logoDark?: string, masterPassword?: string, masterVerificationCode?: string, mfaItems?: list, mfaRememberInHours?: int, name?: string, navItems?: list, orgBalance?: float, owner?: string, passwordExpireDays?: int, passwordObfuscatorKey?: string, passwordObfuscatorType?: string, passwordOptions?: list, passwordSalt?: string, passwordType?: string, tags?: list, themeData?: record, useEmailAsUsername?: bool, userBalance?: float, userNavItems?: list, userTypes?: list, websiteUrl?: string, widgetItems?: list}
# --providers item shape: {canSignIn?: bool, canSignUp?: bool, canUnlink?: bool, countryCodes?: list, name?: string, owner?: string, prompted?: bool, provider?: record, rule?: string, signupGroup?: string}
# --samlAttributes item shape: {name?: string, nameFormat?: string, value?: string}
# --signinItems item shape: {customCss?: string, isCustom?: bool, label?: string, name?: string, placeholder?: string, rule?: string, visible?: bool}
# --signinMethods item shape: {displayName?: string, name?: string, rule?: string}
# --signupItems item shape: {customCss?: string, label?: string, name?: string, options?: list, placeholder?: string, prompted?: bool, regex?: string, required?: bool, rule?: string, type?: string, visible?: bool}
# --themeData shape: {borderRadius?: int, colorPrimary?: string, isCompact?: bool, isEnabled?: bool, themeType?: string}
# --tokenAttributes item shape: {name?: string, type?: string, value?: string}
export def "delete-application ApiControllerDeleteApplication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --affiliationUrl: string
  --cert: string
  --certPublicKey: string
  --clientId: string
  --clientSecret: string
  --codeResendTimeout: int # format: int64
  --cookieExpireInHours: int # format: int64
  --createdTime: string
  --defaultGroup: string
  --description: string
  --disableSamlAttributes: oneof<nothing, bool>
  --disableSignin: oneof<nothing, bool>
  --displayName: string
  --enableAutoSignin: oneof<nothing, bool>
  --enableCodeSignin: oneof<nothing, bool>
  --enableExclusiveSignin: oneof<nothing, bool>
  --enableLinkWithEmail: oneof<nothing, bool>
  --enablePassword: oneof<nothing, bool>
  --enableSamlAssertionSignature: oneof<nothing, bool>
  --enableSamlC14n10: oneof<nothing, bool>
  --enableSamlCompress: oneof<nothing, bool>
  --enableSamlPostBinding: oneof<nothing, bool>
  --enableSignUp: oneof<nothing, bool>
  --enableSigninSession: oneof<nothing, bool>
  --enableWebAuthn: oneof<nothing, bool>
  --expireInHours: float # format: double
  --failedSigninFrozenTime: int # format: int64
  --failedSigninLimit: int # format: int64
  --favicon: string
  --footerHtml: string
  --forcedRedirectOrigin: string
  --forgetUrl: string
  --formBackgroundUrl: string
  --formBackgroundUrlMobile: string
  --formCss: string
  --formCssMobile: string
  --formOffset: int # format: int64
  --formSideHtml: string
  --grantTypes: list
  --headerHtml: string
  --homepageUrl: string
  --ipRestriction: string
  --ipWhitelist: string
  --isShared: oneof<nothing, bool>
  --logo: string
  --name: string
  --order: int # format: int64
  --orgChoiceMode: string
  --organization: string
  --organizationObj: record # shape: {accountItems?: list, accountMenu?: string, balanceCredit?: float, balanceCurrency?: string, countryCodes?: list, createdTime?: string, defaultApplication?: string, defaultAvatar?: string, defaultPassword?: string, disableSignin?: bool, displayName?: string, enableSoftDeletion?: bool, enableTour?: bool, favicon?: string, hasPrivilegeConsent?: bool, initScore?: int, ipRestriction?: string, ipWhitelist?: string, isProfilePublic?: bool, languages?: list, logo?: string, logoDark?: string, masterPassword?: string, masterVerificationCode?: string, mfaItems?: list, mfaRememberInHours?: int, name?: string, navItems?: list, orgBalance?: float, owner?: string, passwordExpireDays?: int, passwordObfuscatorKey?: string, passwordObfuscatorType?: string, passwordOptions?: list, passwordSalt?: string, passwordType?: string, tags?: list, themeData?: record, useEmailAsUsername?: bool, userBalance?: float, userNavItems?: list, userTypes?: list, websiteUrl?: string, widgetItems?: list}
  --owner: string
  --providers: list # item shape: {canSignIn?: bool, canSignUp?: bool, canUnlink?: bool, countryCodes?: list, name?: string, owner?: string, prompted?: bool, provider?: record, rule?: string, signupGroup?: string}
  --redirectUris: list
  --refreshExpireInHours: float # format: double
  --samlAttributes: list # item shape: {name?: string, nameFormat?: string, value?: string}
  --samlHashAlgorithm: string
  --samlReplyUrl: string
  --signinHtml: string
  --signinItems: list # item shape: {customCss?: string, isCustom?: bool, label?: string, name?: string, placeholder?: string, rule?: string, visible?: bool}
  --signinMethods: list # item shape: {displayName?: string, name?: string, rule?: string}
  --signinUrl: string
  --signupHtml: string
  --signupItems: list # item shape: {customCss?: string, label?: string, name?: string, options?: list, placeholder?: string, prompted?: bool, regex?: string, required?: bool, rule?: string, type?: string, visible?: bool}
  --signupUrl: string
  --tags: list
  --termsOfUse: string
  --themeData: record # shape: {borderRadius?: int, colorPrimary?: string, isCompact?: bool, isEnabled?: bool, themeType?: string}
  --title: string
  --tokenAttributes: list # item shape: {name?: string, type?: string, value?: string}
  --tokenFields: list
  --tokenFormat: string
  --tokenSigningMethod: string
  --useEmailAsSamlNameId: oneof<nothing, bool>
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/delete-application")
  let body = {affiliationUrl: $affiliationUrl, cert: $cert, certPublicKey: $certPublicKey, clientId: $clientId, clientSecret: $clientSecret, codeResendTimeout: $codeResendTimeout, cookieExpireInHours: $cookieExpireInHours, createdTime: $createdTime, defaultGroup: $defaultGroup, description: $description, disableSamlAttributes: $disableSamlAttributes, disableSignin: $disableSignin, displayName: $displayName, enableAutoSignin: $enableAutoSignin, enableCodeSignin: $enableCodeSignin, enableExclusiveSignin: $enableExclusiveSignin, enableLinkWithEmail: $enableLinkWithEmail, enablePassword: $enablePassword, enableSamlAssertionSignature: $enableSamlAssertionSignature, enableSamlC14n10: $enableSamlC14n10, enableSamlCompress: $enableSamlCompress, enableSamlPostBinding: $enableSamlPostBinding, enableSignUp: $enableSignUp, enableSigninSession: $enableSigninSession, enableWebAuthn: $enableWebAuthn, expireInHours: $expireInHours, failedSigninFrozenTime: $failedSigninFrozenTime, failedSigninLimit: $failedSigninLimit, favicon: $favicon, footerHtml: $footerHtml, forcedRedirectOrigin: $forcedRedirectOrigin, forgetUrl: $forgetUrl, formBackgroundUrl: $formBackgroundUrl, formBackgroundUrlMobile: $formBackgroundUrlMobile, formCss: $formCss, formCssMobile: $formCssMobile, formOffset: $formOffset, formSideHtml: $formSideHtml, grantTypes: $grantTypes, headerHtml: $headerHtml, homepageUrl: $homepageUrl, ipRestriction: $ipRestriction, ipWhitelist: $ipWhitelist, isShared: $isShared, logo: $logo, name: $name, order: $order, orgChoiceMode: $orgChoiceMode, organization: $organization, organizationObj: $organizationObj, owner: $owner, providers: $providers, redirectUris: $redirectUris, refreshExpireInHours: $refreshExpireInHours, samlAttributes: $samlAttributes, samlHashAlgorithm: $samlHashAlgorithm, samlReplyUrl: $samlReplyUrl, signinHtml: $signinHtml, signinItems: $signinItems, signinMethods: $signinMethods, signinUrl: $signinUrl, signupHtml: $signupHtml, signupItems: $signupItems, signupUrl: $signupUrl, tags: $tags, termsOfUse: $termsOfUse, themeData: $themeData, title: $title, tokenAttributes: $tokenAttributes, tokenFields: $tokenFields, tokenFormat: $tokenFormat, tokenSigningMethod: $tokenSigningMethod, useEmailAsSamlNameId: $useEmailAsSamlNameId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# delete cert
#
# POST /api/delete-cert
# operationId: ApiController.DeleteCert
export def "delete-cert ApiControllerDeleteCert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --bitSize: int # format: int64
  --certificate: string
  --createdTime: string
  --cryptoAlgorithm: string
  --displayName: string
  --expireInYears: int # format: int64
  --name: string
  --owner: string
  --privateKey: string
  --scope: string
  --type: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/delete-cert")
  let body = {bitSize: $bitSize, certificate: $certificate, createdTime: $createdTime, cryptoAlgorithm: $cryptoAlgorithm, displayName: $displayName, expireInYears: $expireInYears, name: $name, owner: $owner, privateKey: $privateKey, scope: $scope, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# delete enforcer
#
# POST /api/delete-enforcer
# operationId: ApiController.DeleteEnforcer
export def "delete-enforcer ApiControllerDeleteEnforcer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --adapter: string
  --createdTime: string
  --description: string
  --displayName: string
  --model: string
  --modelCfg: any
  --name: string
  --owner: string
  --updatedTime: string
]: any -> record<adapter: string, createdTime: string, description: string, displayName: string, model: string, modelCfg: any, name: string, owner: string, updatedTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/delete-enforcer")
  let body = {adapter: $adapter, createdTime: $createdTime, description: $description, displayName: $displayName, model: $model, modelCfg: $modelCfg, name: $name, owner: $owner, updatedTime: $updatedTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# delete form
#
# POST /api/delete-form
# operationId: ApiController.DeleteForm
# --formItems item shape: {label?: string, name?: string, visible?: bool, width?: string}
export def "delete-form ApiControllerDeleteForm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createdTime: string
  --displayName: string
  --formItems: list # item shape: {label?: string, name?: string, visible?: bool, width?: string}
  --name: string
  --owner: string
  --tag: string
  --type: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/delete-form")
  let body = {createdTime: $createdTime, displayName: $displayName, formItems: $formItems, name: $name, owner: $owner, tag: $tag, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# delete group
#
# POST /api/delete-group
# operationId: ApiController.DeleteGroup
# --children item shape: {children?: list, contactEmail?: string, createdTime?: string, displayName?: string, haveChildren?: bool, isEnabled?: bool, isTopGroup?: bool, key?: string, manager?: string, name?: string, owner?: string, parentId?: string, parentName?: string, title?: string, type?: string, updatedTime?: string, users?: list}
export def "delete-group ApiControllerDeleteGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --children: list # item shape: {children?: list, contactEmail?: string, createdTime?: string, displayName?: string, haveChildren?: bool, isEnabled?: bool, isTopGroup?: bool, key?: string, manager?: string, name?: string, owner?: string, parentId?: string, parentName?: string, title?: string, type?: string, updatedTime?: string, users?: list}
  --contactEmail: string
  --createdTime: string
  --displayName: string
  --haveChildren: oneof<nothing, bool>
  --isEnabled: oneof<nothing, bool>
  --isTopGroup: oneof<nothing, bool>
  --key: string
  --manager: string
  --name: string
  --owner: string
  --parentId: string
  --parentName: string
  --title: string
  --type: string
  --updatedTime: string
  --users: list
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/delete-group")
  let body = {children: $children, contactEmail: $contactEmail, createdTime: $createdTime, displayName: $displayName, haveChildren: $haveChildren, isEnabled: $isEnabled, isTopGroup: $isTopGroup, key: $key, manager: $manager, name: $name, owner: $owner, parentId: $parentId, parentName: $parentName, title: $title, type: $type, updatedTime: $updatedTime, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# delete invitation
#
# POST /api/delete-invitation
# operationId: ApiController.DeleteInvitation
export def "delete-invitation ApiControllerDeleteInvitation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --application: string
  --code: string
  --createdTime: string
  --defaultCode: string
  --displayName: string
  --email: string
  --isRegexp: oneof<nothing, bool>
  --name: string
  --owner: string
  --phone: string
  --quota: int # format: int64
  --signupGroup: string
  --state: string
  --updatedTime: string
  --usedCount: int # format: int64
  --username: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/delete-invitation")
  let body = {application: $application, code: $code, createdTime: $createdTime, defaultCode: $defaultCode, displayName: $displayName, email: $email, isRegexp: $isRegexp, name: $name, owner: $owner, phone: $phone, quota: $quota, signupGroup: $signupGroup, state: $state, updatedTime: $updatedTime, usedCount: $usedCount, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# delete ldap
#
# POST /api/delete-ldap
# operationId: ApiController.DeleteLdap
export def "delete-ldap ApiControllerDeleteLdap" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allowSelfSignedCert: oneof<nothing, bool>
  --autoSync: int # format: int64
  --baseDn: string
  --createdTime: string
  --customAttributes: any
  --defaultGroup: string
  --enableSsl: oneof<nothing, bool>
  --filter: string
  --filterFields: list
  --host: string
  --id: string
  --lastSync: string
  --owner: string
  --password: string
  --passwordType: string
  --port: int # format: int64
  --serverName: string
  --username: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/delete-ldap")
  let body = {allowSelfSignedCert: $allowSelfSignedCert, autoSync: $autoSync, baseDn: $baseDn, createdTime: $createdTime, customAttributes: $customAttributes, defaultGroup: $defaultGroup, enableSsl: $enableSsl, filter: $filter, filterFields: $filterFields, host: $host, id: $id, lastSync: $lastSync, owner: $owner, password: $password, passwordType: $passwordType, port: $port, serverName: $serverName, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# : Delete MFA
#
# POST /api/delete-mfa/
# operationId: ApiController.DeleteMfa
export def "delete-mfa ApiControllerDeleteMfa" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/delete-mfa/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# delete model
#
# POST /api/delete-model
# operationId: ApiController.DeleteModel
export def "delete-model ApiControllerDeleteModel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createdTime: string
  --description: string
  --displayName: string
  --modelText: string
  --name: string
  --owner: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/delete-model")
  let body = {createdTime: $createdTime, description: $description, displayName: $displayName, modelText: $modelText, name: $name, owner: $owner} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# delete order
#
# POST /api/delete-order
# operationId: ApiController.DeleteOrder
# --productInfos item shape: {currency?: string, detail?: string, displayName?: string, image?: string, isRecharge?: bool, name?: string, owner?: string, planName?: string, price?: float, pricingName?: string, quantity?: int}
export def "delete-order ApiControllerDeleteOrder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createdTime: string
  --currency: string
  --displayName: string
  --message: string
  --name: string
  --owner: string
  --payment: string
  --price: float # format: double
  --productInfos: list # item shape: {currency?: string, detail?: string, displayName?: string, image?: string, isRecharge?: bool, name?: string, owner?: string, planName?: string, price?: float, pricingName?: string, quantity?: int}
  --products: list
  --state: string
  --updateTime: string
  --user: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/delete-order")
  let body = {createdTime: $createdTime, currency: $currency, displayName: $displayName, message: $message, name: $name, owner: $owner, payment: $payment, price: $price, productInfos: $productInfos, products: $products, state: $state, updateTime: $updateTime, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# delete organization
#
# POST /api/delete-organization
# operationId: ApiController.DeleteOrganization
# --accountItems item shape: {modifyRule?: string, name?: string, regex?: string, tab?: string, viewRule?: string, visible?: bool}
# --mfaItems item shape: {name?: string, rule?: string}
# --themeData shape: {borderRadius?: int, colorPrimary?: string, isCompact?: bool, isEnabled?: bool, themeType?: string}
export def "delete-organization ApiControllerDeleteOrganization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountItems: list # item shape: {modifyRule?: string, name?: string, regex?: string, tab?: string, viewRule?: string, visible?: bool}
  --accountMenu: string
  --balanceCredit: float # format: double
  --balanceCurrency: string
  --countryCodes: list
  --createdTime: string
  --defaultApplication: string
  --defaultAvatar: string
  --defaultPassword: string
  --disableSignin: oneof<nothing, bool>
  --displayName: string
  --enableSoftDeletion: oneof<nothing, bool>
  --enableTour: oneof<nothing, bool>
  --favicon: string
  --hasPrivilegeConsent: oneof<nothing, bool>
  --initScore: int # format: int64
  --ipRestriction: string
  --ipWhitelist: string
  --isProfilePublic: oneof<nothing, bool>
  --languages: list
  --logo: string
  --logoDark: string
  --masterPassword: string
  --masterVerificationCode: string
  --mfaItems: list # item shape: {name?: string, rule?: string}
  --mfaRememberInHours: int # format: int64
  --name: string
  --navItems: list
  --orgBalance: float # format: double
  --owner: string
  --passwordExpireDays: int # format: int64
  --passwordObfuscatorKey: string
  --passwordObfuscatorType: string
  --passwordOptions: list
  --passwordSalt: string
  --passwordType: string
  --tags: list
  --themeData: record # shape: {borderRadius?: int, colorPrimary?: string, isCompact?: bool, isEnabled?: bool, themeType?: string}
  --useEmailAsUsername: oneof<nothing, bool>
  --userBalance: float # format: double
  --userNavItems: list
  --userTypes: list
  --websiteUrl: string
  --widgetItems: list
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/delete-organization")
  let body = {accountItems: $accountItems, accountMenu: $accountMenu, balanceCredit: $balanceCredit, balanceCurrency: $balanceCurrency, countryCodes: $countryCodes, createdTime: $createdTime, defaultApplication: $defaultApplication, defaultAvatar: $defaultAvatar, defaultPassword: $defaultPassword, disableSignin: $disableSignin, displayName: $displayName, enableSoftDeletion: $enableSoftDeletion, enableTour: $enableTour, favicon: $favicon, hasPrivilegeConsent: $hasPrivilegeConsent, initScore: $initScore, ipRestriction: $ipRestriction, ipWhitelist: $ipWhitelist, isProfilePublic: $isProfilePublic, languages: $languages, logo: $logo, logoDark: $logoDark, masterPassword: $masterPassword, masterVerificationCode: $masterVerificationCode, mfaItems: $mfaItems, mfaRememberInHours: $mfaRememberInHours, name: $name, navItems: $navItems, orgBalance: $orgBalance, owner: $owner, passwordExpireDays: $passwordExpireDays, passwordObfuscatorKey: $passwordObfuscatorKey, passwordObfuscatorType: $passwordObfuscatorType, passwordOptions: $passwordOptions, passwordSalt: $passwordSalt, passwordType: $passwordType, tags: $tags, themeData: $themeData, useEmailAsUsername: $useEmailAsUsername, userBalance: $userBalance, userNavItems: $userNavItems, userTypes: $userTypes, websiteUrl: $websiteUrl, widgetItems: $widgetItems} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# delete payment
#
# POST /api/delete-payment
# operationId: ApiController.DeletePayment
# --orderObj shape: {createdTime?: string, currency?: string, displayName?: string, message?: string, name?: string, owner?: string, payment?: string, price?: float, productInfos?: list, products?: list, state?: string, updateTime?: string, user?: string}
export def "delete-payment ApiControllerDeletePayment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createdTime: string
  --currency: string
  --detail: string
  --displayName: string
  --invoiceRemark: string
  --invoiceTaxId: string
  --invoiceTitle: string
  --invoiceType: string
  --invoiceUrl: string
  --message: string
  --name: string
  --order: string
  --orderObj: record # shape: {createdTime?: string, currency?: string, displayName?: string, message?: string, name?: string, owner?: string, payment?: string, price?: float, productInfos?: list, products?: list, state?: string, updateTime?: string, user?: string}
  --outOrderId: string
  --owner: string
  --payUrl: string
  --personEmail: string
  --personIdCard: string
  --personName: string
  --personPhone: string
  --price: float # format: double
  --products: list
  --productsDisplayName: string
  --provider: string
  --state: string@state-completer # e.g. Paid
  --successUrl: string
  --type: string
  --user: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/delete-payment")
  let body = {createdTime: $createdTime, currency: $currency, detail: $detail, displayName: $displayName, invoiceRemark: $invoiceRemark, invoiceTaxId: $invoiceTaxId, invoiceTitle: $invoiceTitle, invoiceType: $invoiceType, invoiceUrl: $invoiceUrl, message: $message, name: $name, order: $order, orderObj: $orderObj, outOrderId: $outOrderId, owner: $owner, payUrl: $payUrl, personEmail: $personEmail, personIdCard: $personIdCard, personName: $personName, personPhone: $personPhone, price: $price, products: $products, productsDisplayName: $productsDisplayName, provider: $provider, state: $state, successUrl: $successUrl, type: $type, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# delete permission
#
# POST /api/delete-permission
# operationId: ApiController.DeletePermission
export def "delete-permission ApiControllerDeletePermission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --actions: list
  --adapter: string
  --approveTime: string
  --approver: string
  --createdTime: string
  --description: string
  --displayName: string
  --domains: list
  --effect: string
  --groups: list
  --isEnabled: oneof<nothing, bool>
  --model: string
  --name: string
  --owner: string
  --resourceType: string
  --resources: list
  --roles: list
  --state: string
  --submitter: string
  --users: list
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/delete-permission")
  let body = {actions: $actions, adapter: $adapter, approveTime: $approveTime, approver: $approver, createdTime: $createdTime, description: $description, displayName: $displayName, domains: $domains, effect: $effect, groups: $groups, isEnabled: $isEnabled, model: $model, name: $name, owner: $owner, resourceType: $resourceType, resources: $resources, roles: $roles, state: $state, submitter: $submitter, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# delete plan
#
# POST /api/delete-plan
# operationId: ApiController.DeletePlan
export def "delete-plan ApiControllerDeletePlan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createdTime: string
  --currency: string
  --description: string
  --displayName: string
  --isEnabled: oneof<nothing, bool>
  --name: string
  --options: list
  --owner: string
  --paymentProviders: list
  --period: string
  --price: float # format: double
  --product: string
  --role: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/delete-plan")
  let body = {createdTime: $createdTime, currency: $currency, description: $description, displayName: $displayName, isEnabled: $isEnabled, name: $name, options: $options, owner: $owner, paymentProviders: $paymentProviders, period: $period, price: $price, product: $product, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# delete pricing
#
# POST /api/delete-pricing
# operationId: ApiController.DeletePricing
export def "delete-pricing ApiControllerDeletePricing" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --application: string
  --createdTime: string
  --description: string
  --displayName: string
  --isEnabled: oneof<nothing, bool>
  --name: string
  --owner: string
  --plans: list
  --trialDuration: int # format: int64
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/delete-pricing")
  let body = {application: $application, createdTime: $createdTime, description: $description, displayName: $displayName, isEnabled: $isEnabled, name: $name, owner: $owner, plans: $plans, trialDuration: $trialDuration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# delete product
#
# POST /api/delete-product
# operationId: ApiController.DeleteProduct
# --providerObjs item shape: {appId?: string, bucket?: string, category?: string, cert?: string, clientId?: string, clientId2?: string, clientSecret?: string, clientSecret2?: string, content?: string, createdTime?: string, customAuthUrl?: string, customLogo?: string, customTokenUrl?: string, customUserInfoUrl?: string, disableSsl?: bool, displayName?: string, domain?: string, emailRegex?: string, enablePkce?: bool, enableProxy?: bool, enableSignAuthnRequest?: bool, endpoint?: string, host?: string, httpHeaders?: any, idP?: string, intranetEndpoint?: string, issuerUrl?: string, metadata?: string, method?: string, name?: string, owner?: string, pathPrefix?: string, port?: int, providerUrl?: string, receiver?: string, regionId?: string, scopes?: string, signName?: string, subType?: string, templateCode?: string, title?: string, type?: string, userMapping?: any}
export def "delete-product ApiControllerDeleteProduct" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createdTime: string
  --currency: string
  --description: string
  --detail: string
  --disableCustomRecharge: oneof<nothing, bool>
  --displayName: string
  --image: string
  --isRecharge: oneof<nothing, bool>
  --name: string
  --owner: string
  --price: float # format: double
  --providerObjs: list # item shape: {appId?: string, bucket?: string, category?: string, cert?: string, clientId?: string, clientId2?: string, clientSecret?: string, clientSecret2?: string, content?: string, createdTime?: string, customAuthUrl?: string, customLogo?: string, customTokenUrl?: string, customUserInfoUrl?: string, disableSsl?: bool, displayName?: string, domain?: string, emailRegex?: string, enablePkce?: bool, enableProxy?: bool, enableSignAuthnRequest?: bool, endpoint?: string, host?: string, httpHeaders?: any, idP?: string, intranetEndpoint?: string, issuerUrl?: string, metadata?: string, method?: string, name?: string, owner?: string, pathPrefix?: string, port?: int, providerUrl?: string, receiver?: string, regionId?: string, scopes?: string, signName?: string, subType?: string, templateCode?: string, title?: string, type?: string, userMapping?: any}
  --providers: list
  --quantity: int # format: int64
  --rechargeOptions: list
  --sold: int # format: int64
  --state: string
  --successUrl: string
  --tag: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/delete-product")
  let body = {createdTime: $createdTime, currency: $currency, description: $description, detail: $detail, disableCustomRecharge: $disableCustomRecharge, displayName: $displayName, image: $image, isRecharge: $isRecharge, name: $name, owner: $owner, price: $price, providerObjs: $providerObjs, providers: $providers, quantity: $quantity, rechargeOptions: $rechargeOptions, sold: $sold, state: $state, successUrl: $successUrl, tag: $tag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# delete provider
#
# POST /api/delete-provider
# operationId: ApiController.DeleteProvider
export def "delete-provider ApiControllerDeleteProvider" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --appId: string
  --bucket: string
  --category: string
  --cert: string
  --clientId: string
  --clientId2: string
  --clientSecret: string
  --clientSecret2: string
  --content: string
  --createdTime: string
  --customAuthUrl: string
  --customLogo: string
  --customTokenUrl: string
  --customUserInfoUrl: string
  --disableSsl: oneof<nothing, bool>
  --displayName: string
  --domain: string
  --emailRegex: string
  --enablePkce: oneof<nothing, bool>
  --enableProxy: oneof<nothing, bool>
  --enableSignAuthnRequest: oneof<nothing, bool>
  --endpoint: string
  --host: string
  --httpHeaders: any
  --idP: string
  --intranetEndpoint: string
  --issuerUrl: string
  --metadata: string
  --method: string
  --name: string
  --owner: string
  --pathPrefix: string
  --port: int # format: int64
  --providerUrl: string
  --receiver: string
  --regionId: string
  --scopes: string
  --signName: string
  --subType: string
  --templateCode: string
  --title: string
  --type: string
  --userMapping: any
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/delete-provider")
  let body = {appId: $appId, bucket: $bucket, category: $category, cert: $cert, clientId: $clientId, clientId2: $clientId2, clientSecret: $clientSecret, clientSecret2: $clientSecret2, content: $content, createdTime: $createdTime, customAuthUrl: $customAuthUrl, customLogo: $customLogo, customTokenUrl: $customTokenUrl, customUserInfoUrl: $customUserInfoUrl, disableSsl: $disableSsl, displayName: $displayName, domain: $domain, emailRegex: $emailRegex, enablePkce: $enablePkce, enableProxy: $enableProxy, enableSignAuthnRequest: $enableSignAuthnRequest, endpoint: $endpoint, host: $host, httpHeaders: $httpHeaders, idP: $idP, intranetEndpoint: $intranetEndpoint, issuerUrl: $issuerUrl, metadata: $metadata, method: $method, name: $name, owner: $owner, pathPrefix: $pathPrefix, port: $port, providerUrl: $providerUrl, receiver: $receiver, regionId: $regionId, scopes: $scopes, signName: $signName, subType: $subType, templateCode: $templateCode, title: $title, type: $type, userMapping: $userMapping} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /api/delete-resource
#
# operationId: ApiController.DeleteResource
export def "delete-resource ApiControllerDeleteResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --application: string
  --createdTime: string
  --description: string
  --fileFormat: string
  --fileName: string
  --fileSize: int # format: int64
  --fileType: string
  --name: string
  --owner: string
  --parent: string
  --provider: string
  --tag: string
  --body-url: string
  --user: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/delete-resource")
  let body = {application: $application, createdTime: $createdTime, description: $description, fileFormat: $fileFormat, fileName: $fileName, fileSize: $fileSize, fileType: $fileType, name: $name, owner: $owner, parent: $parent, provider: $provider, tag: $tag, url: $body_url, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# delete role
#
# POST /api/delete-role
# operationId: ApiController.DeleteRole
export def "delete-role ApiControllerDeleteRole" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createdTime: string
  --description: string
  --displayName: string
  --domains: list
  --groups: list
  --isEnabled: oneof<nothing, bool>
  --name: string
  --owner: string
  --roles: list
  --users: list
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/delete-role")
  let body = {createdTime: $createdTime, description: $description, displayName: $displayName, domains: $domains, groups: $groups, isEnabled: $isEnabled, name: $name, owner: $owner, roles: $roles, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete session for one user in one application.
#
# POST /api/delete-session
# operationId: ApiController.DeleteSession
export def "delete-session ApiControllerDeleteSession" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ExclusiveSignin: oneof<nothing, bool>
  --application: string
  --createdTime: string
  --name: string
  --owner: string
  --sessionId: list
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/delete-session")
  let body = {ExclusiveSignin: $ExclusiveSignin, application: $application, createdTime: $createdTime, name: $name, owner: $owner, sessionId: $sessionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# delete subscription
#
# POST /api/delete-subscription
# operationId: ApiController.DeleteSubscription
export def "delete-subscription ApiControllerDeleteSubscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createdTime: string
  --description: string
  --displayName: string
  --endTime: string
  --name: string
  --owner: string
  --payment: string
  --period: string
  --plan: string
  --pricing: string
  --startTime: string
  --state: string@state-completer-1 # e.g. Pending
  --user: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/delete-subscription")
  let body = {createdTime: $createdTime, description: $description, displayName: $displayName, endTime: $endTime, name: $name, owner: $owner, payment: $payment, period: $period, plan: $plan, pricing: $pricing, startTime: $startTime, state: $state, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# delete syncer
#
# POST /api/delete-syncer
# operationId: ApiController.DeleteSyncer
# --tableColumns item shape: {casdoorName?: string, isHashed?: bool, isKey?: bool, name?: string, type?: string, values?: list}
export def "delete-syncer ApiControllerDeleteSyncer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --affiliationTable: string
  --avatarBaseUrl: string
  --cert: string
  --createdTime: string
  --database: string
  --databaseType: string
  --errorText: string
  --host: string
  --isEnabled: oneof<nothing, bool>
  --isReadOnly: oneof<nothing, bool>
  --name: string
  --organization: string
  --owner: string
  --password: string
  --port: int # format: int64
  --sshHost: string
  --sshPassword: string
  --sshPort: int # format: int64
  --sshType: string
  --sshUser: string
  --sslMode: string
  --syncInterval: int # format: int64
  --table: string
  --tableColumns: list # item shape: {casdoorName?: string, isHashed?: bool, isKey?: bool, name?: string, type?: string, values?: list}
  --type: string
  --user: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/delete-syncer")
  let body = {affiliationTable: $affiliationTable, avatarBaseUrl: $avatarBaseUrl, cert: $cert, createdTime: $createdTime, database: $database, databaseType: $databaseType, errorText: $errorText, host: $host, isEnabled: $isEnabled, isReadOnly: $isReadOnly, name: $name, organization: $organization, owner: $owner, password: $password, port: $port, sshHost: $sshHost, sshPassword: $sshPassword, sshPort: $sshPort, sshType: $sshType, sshUser: $sshUser, sslMode: $sslMode, syncInterval: $syncInterval, table: $table, tableColumns: $tableColumns, type: $type, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# delete ticket
#
# POST /api/delete-ticket
# operationId: ApiController.DeleteTicket
# --messages item shape: {author?: string, isAdmin?: bool, text?: string, timestamp?: string}
export def "delete-ticket ApiControllerDeleteTicket" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --content: string
  --createdTime: string
  --displayName: string
  --messages: list # item shape: {author?: string, isAdmin?: bool, text?: string, timestamp?: string}
  --name: string
  --owner: string
  --state: string
  --title: string
  --updatedTime: string
  --user: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/delete-ticket")
  let body = {content: $content, createdTime: $createdTime, displayName: $displayName, messages: $messages, name: $name, owner: $owner, state: $state, title: $title, updatedTime: $updatedTime, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# delete token
#
# POST /api/delete-token
# operationId: ApiController.DeleteToken
export def "delete-token ApiControllerDeleteToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accessToken: string
  --accessTokenHash: string
  --application: string
  --code: string
  --codeChallenge: string
  --codeExpireIn: int # format: int64
  --codeIsUsed: oneof<nothing, bool>
  --createdTime: string
  --expiresIn: int # format: int64
  --name: string
  --organization: string
  --owner: string
  --refreshToken: string
  --refreshTokenHash: string
  --scope: string
  --tokenType: string
  --user: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/delete-token")
  let body = {accessToken: $accessToken, accessTokenHash: $accessTokenHash, application: $application, code: $code, codeChallenge: $codeChallenge, codeExpireIn: $codeExpireIn, codeIsUsed: $codeIsUsed, createdTime: $createdTime, expiresIn: $expiresIn, name: $name, organization: $organization, owner: $owner, refreshToken: $refreshToken, refreshTokenHash: $refreshTokenHash, scope: $scope, tokenType: $tokenType, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# delete transaction
#
# POST /api/delete-transaction
# operationId: ApiController.DeleteTransaction
export def "delete-transaction ApiControllerDeleteTransaction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --amount: float # format: double
  --application: string
  --category: string@category-completer # e.g. Purchase
  --createdTime: string
  --currency: string
  --displayName: string
  --domain: string
  --name: string
  --owner: string
  --payment: string
  --provider: string
  --state: string
  --subtype: string
  --tag: string
  --type: string
  --user: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/delete-transaction")
  let body = {amount: $amount, application: $application, category: $category, createdTime: $createdTime, currency: $currency, displayName: $displayName, domain: $domain, name: $name, owner: $owner, payment: $payment, provider: $provider, state: $state, subtype: $subtype, tag: $tag, type: $type, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# delete user
#
# POST /api/delete-user
# operationId: ApiController.DeleteUser
# --addresses item shape: {city?: string, line1?: string, line2?: string, region?: string, state?: string, tag?: string, zipCode?: string}
# --cart item shape: {currency?: string, detail?: string, displayName?: string, image?: string, isRecharge?: bool, name?: string, owner?: string, planName?: string, price?: float, pricingName?: string, quantity?: int}
# --faceIds item shape: {ImageUrl?: string, faceIdData?: list, name?: string}
# --managedAccounts item shape: {application?: string, password?: string, signinUrl?: string, username?: string}
# --mfaAccounts item shape: {accountName?: string, issuer?: string, origin?: string, secretKey?: string}
# --mfaItems item shape: {name?: string, rule?: string}
# --multiFactorAuths item shape: {countryCode?: string, enabled?: bool, isPreferred?: bool, mfaRememberInHours?: int, mfaType?: string, recoveryCodes?: list, secret?: string, url?: string}
# --permissions item shape: {actions?: list, adapter?: string, approveTime?: string, approver?: string, createdTime?: string, description?: string, displayName?: string, domains?: list, effect?: string, groups?: list, isEnabled?: bool, model?: string, name?: string, owner?: string, resourceType?: string, resources?: list, roles?: list, state?: string, submitter?: string, users?: list}
# --roles item shape: {createdTime?: string, description?: string, displayName?: string, domains?: list, groups?: list, isEnabled?: bool, name?: string, owner?: string, roles?: list, users?: list}
export def "delete-user ApiControllerDeleteUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accessKey: string
  --accessSecret: string
  --accessToken: string
  --address: list
  --addresses: list # item shape: {city?: string, line1?: string, line2?: string, region?: string, state?: string, tag?: string, zipCode?: string}
  --adfs: string
  --affiliation: string
  --alipay: string
  --amazon: string
  --apple: string
  --auth0: string
  --avatar: string
  --avatarType: string
  --azuread: string
  --azureadb2c: string
  --baidu: string
  --balance: float # format: double
  --balanceCredit: float # format: double
  --balanceCurrency: string
  --battlenet: string
  --bilibili: string
  --bio: string
  --birthday: string
  --bitbucket: string
  --box: string
  --cart: list # item shape: {currency?: string, detail?: string, displayName?: string, image?: string, isRecharge?: bool, name?: string, owner?: string, planName?: string, price?: float, pricingName?: string, quantity?: int}
  --casdoor: string
  --cloudfoundry: string
  --countryCode: string
  --createdIp: string
  --createdTime: string
  --currency: string
  --custom: string
  --custom10: string
  --custom2: string
  --custom3: string
  --custom4: string
  --custom5: string
  --custom6: string
  --custom7: string
  --custom8: string
  --custom9: string
  --dailymotion: string
  --deezer: string
  --deletedTime: string
  --digitalocean: string
  --dingtalk: string
  --discord: string
  --displayName: string
  --douyin: string
  --dropbox: string
  --education: string
  --email: string
  --emailVerified: oneof<nothing, bool>
  --eveonline: string
  --externalId: string
  --faceIds: list # item shape: {ImageUrl?: string, faceIdData?: list, name?: string}
  --facebook: string
  --firstName: string
  --fitbit: string
  --gender: string
  --gitea: string
  --gitee: string
  --github: string
  --gitlab: string
  --google: string
  --groups: list
  --hash: string
  --heroku: string
  --homepage: string
  --id: string
  --idCard: string
  --idCardType: string
  --influxcloud: string
  --infoflow: string
  --instagram: string
  --intercom: string
  --invitation: string
  --invitationCode: string
  --ipWhitelist: string
  --isAdmin: oneof<nothing, bool>
  --isDefaultAvatar: oneof<nothing, bool>
  --isDeleted: oneof<nothing, bool>
  --isForbidden: oneof<nothing, bool>
  --isOnline: oneof<nothing, bool>
  --isVerified: oneof<nothing, bool>
  --kakao: string
  --karma: int # format: int64
  --kwai: string
  --language: string
  --lark: string
  --lastChangePasswordTime: string
  --lastName: string
  --lastSigninIp: string
  --lastSigninTime: string
  --lastSigninWrongTime: string
  --lastfm: string
  --ldap: string
  --line: string
  --linkedin: string
  --location: string
  --mailru: string
  --managedAccounts: list # item shape: {application?: string, password?: string, signinUrl?: string, username?: string}
  --meetup: string
  --metamask: string
  --mfaAccounts: list # item shape: {accountName?: string, issuer?: string, origin?: string, secretKey?: string}
  --mfaEmailEnabled: oneof<nothing, bool>
  --mfaItems: list # item shape: {name?: string, rule?: string}
  --mfaPhoneEnabled: oneof<nothing, bool>
  --mfaPushEnabled: oneof<nothing, bool>
  --mfaPushProvider: string
  --mfaPushReceiver: string
  --mfaRadiusEnabled: oneof<nothing, bool>
  --mfaRadiusProvider: string
  --mfaRadiusUsername: string
  --mfaRememberDeadline: string
  --microsoftonline: string
  --multiFactorAuths: list # item shape: {countryCode?: string, enabled?: bool, isPreferred?: bool, mfaRememberInHours?: int, mfaType?: string, recoveryCodes?: list, secret?: string, url?: string}
  --name: string
  --naver: string
  --needUpdatePassword: oneof<nothing, bool>
  --nextcloud: string
  --okta: string
  --onedrive: string
  --originalRefreshToken: string
  --originalToken: string
  --oura: string
  --owner: string
  --password: string
  --passwordSalt: string
  --passwordType: string
  --patreon: string
  --paypal: string
  --permanentAvatar: string
  --permissions: list # item shape: {actions?: list, adapter?: string, approveTime?: string, approver?: string, createdTime?: string, description?: string, displayName?: string, domains?: list, effect?: string, groups?: list, isEnabled?: bool, model?: string, name?: string, owner?: string, resourceType?: string, resources?: list, roles?: list, state?: string, submitter?: string, users?: list}
  --phone: string
  --preHash: string
  --preferredMfaType: string
  --properties: any
  --qq: string
  --ranking: int # format: int64
  --realName: string
  --recoveryCodes: list
  --region: string
  --registerSource: string
  --registerType: string
  --roles: list # item shape: {createdTime?: string, description?: string, displayName?: string, domains?: list, groups?: list, isEnabled?: bool, name?: string, owner?: string, roles?: list, users?: list}
  --salesforce: string
  --score: int # format: int64
  --shopify: string
  --signinWrongTimes: int # format: int64
  --signupApplication: string
  --slack: string
  --soundcloud: string
  --spotify: string
  --steam: string
  --strava: string
  --stripe: string
  --tag: string
  --tiktok: string
  --title: string
  --totpSecret: string
  --tumblr: string
  --twitch: string
  --twitter: string
  --type: string
  --typetalk: string
  --uber: string
  --updatedTime: string
  --vk: string
  --web3onboard: string
  --webauthnCredentials: list
  --wechat: string
  --wecom: string
  --weibo: string
  --wepay: string
  --xero: string
  --yahoo: string
  --yammer: string
  --yandex: string
  --zoom: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/delete-user")
  let body = {accessKey: $accessKey, accessSecret: $accessSecret, accessToken: $accessToken, address: $address, addresses: $addresses, adfs: $adfs, affiliation: $affiliation, alipay: $alipay, amazon: $amazon, apple: $apple, auth0: $auth0, avatar: $avatar, avatarType: $avatarType, azuread: $azuread, azureadb2c: $azureadb2c, baidu: $baidu, balance: $balance, balanceCredit: $balanceCredit, balanceCurrency: $balanceCurrency, battlenet: $battlenet, bilibili: $bilibili, bio: $bio, birthday: $birthday, bitbucket: $bitbucket, box: $box, cart: $cart, casdoor: $casdoor, cloudfoundry: $cloudfoundry, countryCode: $countryCode, createdIp: $createdIp, createdTime: $createdTime, currency: $currency, custom: $custom, custom10: $custom10, custom2: $custom2, custom3: $custom3, custom4: $custom4, custom5: $custom5, custom6: $custom6, custom7: $custom7, custom8: $custom8, custom9: $custom9, dailymotion: $dailymotion, deezer: $deezer, deletedTime: $deletedTime, digitalocean: $digitalocean, dingtalk: $dingtalk, discord: $discord, displayName: $displayName, douyin: $douyin, dropbox: $dropbox, education: $education, email: $email, emailVerified: $emailVerified, eveonline: $eveonline, externalId: $externalId, faceIds: $faceIds, facebook: $facebook, firstName: $firstName, fitbit: $fitbit, gender: $gender, gitea: $gitea, gitee: $gitee, github: $github, gitlab: $gitlab, google: $google, groups: $groups, hash: $hash, heroku: $heroku, homepage: $homepage, id: $id, idCard: $idCard, idCardType: $idCardType, influxcloud: $influxcloud, infoflow: $infoflow, instagram: $instagram, intercom: $intercom, invitation: $invitation, invitationCode: $invitationCode, ipWhitelist: $ipWhitelist, isAdmin: $isAdmin, isDefaultAvatar: $isDefaultAvatar, isDeleted: $isDeleted, isForbidden: $isForbidden, isOnline: $isOnline, isVerified: $isVerified, kakao: $kakao, karma: $karma, kwai: $kwai, language: $language, lark: $lark, lastChangePasswordTime: $lastChangePasswordTime, lastName: $lastName, lastSigninIp: $lastSigninIp, lastSigninTime: $lastSigninTime, lastSigninWrongTime: $lastSigninWrongTime, lastfm: $lastfm, ldap: $ldap, line: $line, linkedin: $linkedin, location: $location, mailru: $mailru, managedAccounts: $managedAccounts, meetup: $meetup, metamask: $metamask, mfaAccounts: $mfaAccounts, mfaEmailEnabled: $mfaEmailEnabled, mfaItems: $mfaItems, mfaPhoneEnabled: $mfaPhoneEnabled, mfaPushEnabled: $mfaPushEnabled, mfaPushProvider: $mfaPushProvider, mfaPushReceiver: $mfaPushReceiver, mfaRadiusEnabled: $mfaRadiusEnabled, mfaRadiusProvider: $mfaRadiusProvider, mfaRadiusUsername: $mfaRadiusUsername, mfaRememberDeadline: $mfaRememberDeadline, microsoftonline: $microsoftonline, multiFactorAuths: $multiFactorAuths, name: $name, naver: $naver, needUpdatePassword: $needUpdatePassword, nextcloud: $nextcloud, okta: $okta, onedrive: $onedrive, originalRefreshToken: $originalRefreshToken, originalToken: $originalToken, oura: $oura, owner: $owner, password: $password, passwordSalt: $passwordSalt, passwordType: $passwordType, patreon: $patreon, paypal: $paypal, permanentAvatar: $permanentAvatar, permissions: $permissions, phone: $phone, preHash: $preHash, preferredMfaType: $preferredMfaType, properties: $properties, qq: $qq, ranking: $ranking, realName: $realName, recoveryCodes: $recoveryCodes, region: $region, registerSource: $registerSource, registerType: $registerType, roles: $roles, salesforce: $salesforce, score: $score, shopify: $shopify, signinWrongTimes: $signinWrongTimes, signupApplication: $signupApplication, slack: $slack, soundcloud: $soundcloud, spotify: $spotify, steam: $steam, strava: $strava, stripe: $stripe, tag: $tag, tiktok: $tiktok, title: $title, totpSecret: $totpSecret, tumblr: $tumblr, twitch: $twitch, twitter: $twitter, type: $type, typetalk: $typetalk, uber: $uber, updatedTime: $updatedTime, vk: $vk, web3onboard: $web3onboard, webauthnCredentials: $webauthnCredentials, wechat: $wechat, wecom: $wecom, weibo: $weibo, wepay: $wepay, xero: $xero, yahoo: $yahoo, yammer: $yammer, yandex: $yandex, zoom: $zoom} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# delete webhook
#
# POST /api/delete-webhook
# operationId: ApiController.DeleteWebhook
# --headers item shape: {name?: string, value?: string}
export def "delete-webhook ApiControllerDeleteWebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contentType: string
  --createdTime: string
  --events: list
  --headers: list # item shape: {name?: string, value?: string}
  --isEnabled: oneof<nothing, bool>
  --isUserExtended: oneof<nothing, bool>
  --method: string
  --name: string
  --objectFields: list
  --organization: string
  --owner: string
  --singleOrgOnly: oneof<nothing, bool>
  --tokenFields: list
  --body-url: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/delete-webhook")
  let body = {contentType: $contentType, createdTime: $createdTime, events: $events, headers: $headers, isEnabled: $isEnabled, isUserExtended: $isUserExtended, method: $method, name: $name, objectFields: $objectFields, organization: $organization, owner: $owner, singleOrgOnly: $singleOrgOnly, tokenFields: $tokenFields, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Endpoint for the device authorization flow
#
# POST /api/device-auth
# operationId: ApiController.DeviceAuth
export def "device-auth ApiControllerDeviceAuth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<device_code: string, expires_in: int, interval: int, user_code: string, verification_uri: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/device-auth")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Call Casbin Enforce API
#
# POST /api/enforce
# operationId: ApiController.Enforce
export def "enforce ApiControllerEnforce" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --permissionId: string # permission id
  --modelId: string # model id
  --resourceId: string # resource id
  --owner: string # owner
  --body: record
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "permissionId" $permissionId "scalar") (serialize-qp "modelId" $modelId "scalar") (serialize-qp "resourceId" $resourceId "scalar") (serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/enforce" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# clear impersonation info for current session
#
# POST /api/exit-impersonation-user
# operationId: ApiController.ExitImpersonateUser
export def "exit-impersonation-user ApiControllerExitImpersonateUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/exit-impersonation-user")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# FaceId Login Flow 1st stage
#
# GET /api/faceid-signin-begin
# operationId: ApiController.FaceIDSigninBegin
export def "faceid-signin-begin ApiControllerFaceIDSigninBegin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # owner
  --name: string # name
]: nothing -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/faceid-signin-begin" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get the details of the current account
#
# GET /api/get-account
# operationId: ApiController.GetAccount
export def "get-account ApiControllerGetAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/get-account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get adapter
#
# GET /api/get-adapter
# operationId: ApiController.GetAdapter
export def "get-adapter ApiControllerGetAdapter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the adapter
]: nothing -> record<createdTime: string, database: string, databaseType: string, host: string, name: string, owner: string, password: string, port: int, table: string, type: string, useSameDb: bool, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-adapter" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get adapters
#
# GET /api/get-adapters
# operationId: ApiController.GetAdapters
export def "get-adapters ApiControllerGetAdapters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # The owner of adapters
]: nothing -> table<createdTime: string, database: string, databaseType: string, host: string, name: string, owner: string, password: string, port: int, table: string, type: string, useSameDb: bool, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-adapters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all actions for a user (Casbin API)
#
# GET /api/get-all-actions
# operationId: ApiController.GetAllActions
export def "get-all-actions ApiControllerGetAllActions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userId: string # user id like built-in/admin
]: nothing -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $userId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-all-actions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all objects for a user (Casbin API)
#
# GET /api/get-all-objects
# operationId: ApiController.GetAllObjects
export def "get-all-objects ApiControllerGetAllObjects" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userId: string # user id like built-in/admin
]: nothing -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $userId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-all-objects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all roles for a user (Casbin API)
#
# GET /api/get-all-roles
# operationId: ApiController.GetAllRoles
export def "get-all-roles ApiControllerGetAllRoles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --userId: string # user id like built-in/admin
]: nothing -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userId" $userId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-all-roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get application login
#
# GET /api/get-app-login
# operationId: ApiController.GetApplicationLogin
export def "get-app-login ApiControllerGetApplicationLogin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clientId: string # client id
  --responseType: string # response type
  --redirectUri: string # redirect uri
  --scope: string # scope
  --state: string # state
]: nothing -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientId" $clientId "scalar") (serialize-qp "responseType" $responseType "scalar") (serialize-qp "redirectUri" $redirectUri "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-app-login" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get the detail of an application
#
# GET /api/get-application
# operationId: ApiController.GetApplication
export def "get-application ApiControllerGetApplication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the application.
]: nothing -> record<affiliationUrl: string, cert: string, certPublicKey: string, clientId: string, clientSecret: string, codeResendTimeout: int, cookieExpireInHours: int, createdTime: string, defaultGroup: string, description: string, disableSamlAttributes: bool, disableSignin: bool, displayName: string, enableAutoSignin: bool, enableCodeSignin: bool, enableExclusiveSignin: bool, enableLinkWithEmail: bool, enablePassword: bool, enableSamlAssertionSignature: bool, enableSamlC14n10: bool, enableSamlCompress: bool, enableSamlPostBinding: bool, enableSignUp: bool, enableSigninSession: bool, enableWebAuthn: bool, expireInHours: float, failedSigninFrozenTime: int, failedSigninLimit: int, favicon: string, footerHtml: string, forcedRedirectOrigin: string, forgetUrl: string, formBackgroundUrl: string, formBackgroundUrlMobile: string, formCss: string, formCssMobile: string, formOffset: int, formSideHtml: string, grantTypes: list<string>, headerHtml: string, homepageUrl: string, ipRestriction: string, ipWhitelist: string, isShared: bool, logo: string, name: string, order: int, orgChoiceMode: string, organization: string, organizationObj: record<accountItems: list<record>, accountMenu: string, balanceCredit: float, balanceCurrency: string, countryCodes: list<string>, createdTime: string, defaultApplication: string, defaultAvatar: string, defaultPassword: string, disableSignin: bool, displayName: string, enableSoftDeletion: bool, enableTour: bool, favicon: string, hasPrivilegeConsent: bool, initScore: int, ipRestriction: string, ipWhitelist: string, isProfilePublic: bool, languages: list<string>, logo: string, logoDark: string, masterPassword: string, masterVerificationCode: string, mfaItems: list<record>, mfaRememberInHours: int, name: string, navItems: list<string>, orgBalance: float, owner: string, passwordExpireDays: int, passwordObfuscatorKey: string, passwordObfuscatorType: string, passwordOptions: list<string>, passwordSalt: string, passwordType: string, tags: list<string>, themeData: record<borderRadius: int, colorPrimary: string, isCompact: bool, isEnabled: bool, themeType: string>, useEmailAsUsername: bool, userBalance: float, userNavItems: list<string>, userTypes: list<string>, websiteUrl: string, widgetItems: list<string>>, owner: string, providers: table<canSignIn: bool, canSignUp: bool, canUnlink: bool, countryCodes: list, name: string, owner: string, prompted: bool, provider: record, rule: string, signupGroup: string>, redirectUris: list<string>, refreshExpireInHours: float, samlAttributes: table<name: string, nameFormat: string, value: string>, samlHashAlgorithm: string, samlReplyUrl: string, signinHtml: string, signinItems: table<customCss: string, isCustom: bool, label: string, name: string, placeholder: string, rule: string, visible: bool>, signinMethods: table<displayName: string, name: string, rule: string>, signinUrl: string, signupHtml: string, signupItems: table<customCss: string, label: string, name: string, options: list, placeholder: string, prompted: bool, regex: string, required: bool, rule: string, type: string, visible: bool>, signupUrl: string, tags: list<string>, termsOfUse: string, themeData: record<borderRadius: int, colorPrimary: string, isCompact: bool, isEnabled: bool, themeType: string>, title: string, tokenAttributes: table<name: string, type: string, value: string>, tokenFields: list<string>, tokenFormat: string, tokenSigningMethod: string, useEmailAsSamlNameId: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-application" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get all applications
#
# GET /api/get-applications
# operationId: ApiController.GetApplications
export def "get-applications ApiControllerGetApplications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # The owner of applications.
]: nothing -> table<affiliationUrl: string, cert: string, certPublicKey: string, clientId: string, clientSecret: string, codeResendTimeout: int, cookieExpireInHours: int, createdTime: string, defaultGroup: string, description: string, disableSamlAttributes: bool, disableSignin: bool, displayName: string, enableAutoSignin: bool, enableCodeSignin: bool, enableExclusiveSignin: bool, enableLinkWithEmail: bool, enablePassword: bool, enableSamlAssertionSignature: bool, enableSamlC14n10: bool, enableSamlCompress: bool, enableSamlPostBinding: bool, enableSignUp: bool, enableSigninSession: bool, enableWebAuthn: bool, expireInHours: float, failedSigninFrozenTime: int, failedSigninLimit: int, favicon: string, footerHtml: string, forcedRedirectOrigin: string, forgetUrl: string, formBackgroundUrl: string, formBackgroundUrlMobile: string, formCss: string, formCssMobile: string, formOffset: int, formSideHtml: string, grantTypes: list<string>, headerHtml: string, homepageUrl: string, ipRestriction: string, ipWhitelist: string, isShared: bool, logo: string, name: string, order: int, orgChoiceMode: string, organization: string, organizationObj: record<accountItems: list, accountMenu: string, balanceCredit: float, balanceCurrency: string, countryCodes: list, createdTime: string, defaultApplication: string, defaultAvatar: string, defaultPassword: string, disableSignin: bool, displayName: string, enableSoftDeletion: bool, enableTour: bool, favicon: string, hasPrivilegeConsent: bool, initScore: int, ipRestriction: string, ipWhitelist: string, isProfilePublic: bool, languages: list, logo: string, logoDark: string, masterPassword: string, masterVerificationCode: string, mfaItems: list, mfaRememberInHours: int, name: string, navItems: list, orgBalance: float, owner: string, passwordExpireDays: int, passwordObfuscatorKey: string, passwordObfuscatorType: string, passwordOptions: list, passwordSalt: string, passwordType: string, tags: list, themeData: record, useEmailAsUsername: bool, userBalance: float, userNavItems: list, userTypes: list, websiteUrl: string, widgetItems: list>, owner: string, providers: list<record>, redirectUris: list<string>, refreshExpireInHours: float, samlAttributes: list<record>, samlHashAlgorithm: string, samlReplyUrl: string, signinHtml: string, signinItems: list<record>, signinMethods: list<record>, signinUrl: string, signupHtml: string, signupItems: list<record>, signupUrl: string, tags: list<string>, termsOfUse: string, themeData: record<borderRadius: int, colorPrimary: string, isCompact: bool, isEnabled: bool, themeType: string>, title: string, tokenAttributes: list<record>, tokenFields: list<string>, tokenFormat: string, tokenSigningMethod: string, useEmailAsSamlNameId: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-applications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/get-captcha
#
# operationId: ApiController.GetCaptcha
export def "get-captcha ApiControllerGetCaptcha" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<address: string, aud: string, email: string, email_verified: bool, groups: list<string>, is_verified: bool, iss: string, name: string, permissions: list<string>, phone: string, picture: string, preferred_username: string, real_name: string, roles: list<string>, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/get-captcha")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Login Error Counts
#
# GET /api/get-captcha-status
# operationId: ApiController.GetCaptchaStatus
export def "get-captcha-status ApiControllerGetCaptchaStatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of user
]: nothing -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-captcha-status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get cert
#
# GET /api/get-cert
# operationId: ApiController.GetCert
export def "get-cert ApiControllerGetCert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the cert
]: nothing -> record<bitSize: int, certificate: string, createdTime: string, cryptoAlgorithm: string, displayName: string, expireInYears: int, name: string, owner: string, privateKey: string, scope: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-cert" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get certs
#
# GET /api/get-certs
# operationId: ApiController.GetCerts
export def "get-certs ApiControllerGetCerts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # The owner of certs
]: nothing -> table<bitSize: int, certificate: string, createdTime: string, cryptoAlgorithm: string, displayName: string, expireInYears: int, name: string, owner: string, privateKey: string, scope: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-certs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get information of dashboard
#
# GET /api/get-dashboard
# operationId: ApiController.GetDashboard
export def "get-dashboard ApiControllerGetDashboard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/get-dashboard")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get default application
#
# GET /api/get-default-application
# operationId: ApiController.GetDefaultApplication
export def "get-default-application ApiControllerGetDefaultApplication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # organization id
]: nothing -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-default-application" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get email and phone by username
#
# GET /api/get-email-and-phone
# operationId: ApiController.GetEmailAndPhone
export def "get-email-and-phone ApiControllerGetEmailAndPhone" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  username: string # The username of the user
  organization: string # The organization of the user
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/get-email-and-phone")
  let body = {username: $username, organization: $organization} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# get enforcer
#
# GET /api/get-enforcer
# operationId: ApiController.GetEnforcer
export def "get-enforcer ApiControllerGetEnforcer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name )  of enforcer
]: nothing -> record<adapter: string, createdTime: string, description: string, displayName: string, model: string, modelCfg: any, name: string, owner: string, updatedTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-enforcer" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get enforcers
#
# GET /api/get-enforcers
# operationId: ApiController.GetEnforcers
export def "get-enforcers ApiControllerGetEnforcers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # The owner of enforcers
]: nothing -> table<adapter: string, createdTime: string, description: string, displayName: string, model: string, modelCfg: any, name: string, owner: string, updatedTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-enforcers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get filtered policies with support for multiple filters via POST body
#
# POST /api/get-filtered-policies
# operationId: ApiController.GetFilteredPolicies
export def "get-filtered-policies ApiControllerGetFilteredPolicies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name )  of enforcer
  --body: record
]: any -> list<record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-filtered-policies" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# get form
#
# GET /api/get-form
# operationId: ApiController.GetForm
export def "get-form ApiControllerGetForm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id (owner/name) of form
]: nothing -> record<createdTime: string, displayName: string, formItems: table<label: string, name: string, visible: bool, width: string>, name: string, owner: string, tag: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-form" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get forms
#
# GET /api/get-forms
# operationId: ApiController.GetForms
export def "get-forms ApiControllerGetForms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # The owner of form
]: nothing -> table<createdTime: string, displayName: string, formItems: list<record>, name: string, owner: string, tag: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-forms" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get global certs
#
# GET /api/get-global-certs
# operationId: ApiController.GetGlobalCerts
export def "get-global-certs ApiControllerGetGlobalCerts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<bitSize: int, certificate: string, createdTime: string, cryptoAlgorithm: string, displayName: string, expireInYears: int, name: string, owner: string, privateKey: string, scope: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/get-global-certs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get global forms
#
# GET /api/get-global-forms
# operationId: ApiController.GetGlobalForms
export def "get-global-forms ApiControllerGetGlobalForms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<createdTime: string, displayName: string, formItems: list<record>, name: string, owner: string, tag: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/get-global-forms")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get Global providers
#
# GET /api/get-global-providers
# operationId: ApiController.GetGlobalProviders
export def "get-global-providers ApiControllerGetGlobalProviders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<appId: string, bucket: string, category: string, cert: string, clientId: string, clientId2: string, clientSecret: string, clientSecret2: string, content: string, createdTime: string, customAuthUrl: string, customLogo: string, customTokenUrl: string, customUserInfoUrl: string, disableSsl: bool, displayName: string, domain: string, emailRegex: string, enablePkce: bool, enableProxy: bool, enableSignAuthnRequest: bool, endpoint: string, host: string, httpHeaders: any, idP: string, intranetEndpoint: string, issuerUrl: string, metadata: string, method: string, name: string, owner: string, pathPrefix: string, port: int, providerUrl: string, receiver: string, regionId: string, scopes: string, signName: string, subType: string, templateCode: string, title: string, type: string, userMapping: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/get-global-providers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get global users
#
# GET /api/get-global-users
# operationId: ApiController.GetGlobalUsers
export def "get-global-users ApiControllerGetGlobalUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<accessKey: string, accessSecret: string, accessToken: string, address: list<string>, addresses: list<record>, adfs: string, affiliation: string, alipay: string, amazon: string, apple: string, auth0: string, avatar: string, avatarType: string, azuread: string, azureadb2c: string, baidu: string, balance: float, balanceCredit: float, balanceCurrency: string, battlenet: string, bilibili: string, bio: string, birthday: string, bitbucket: string, box: string, cart: list<record>, casdoor: string, cloudfoundry: string, countryCode: string, createdIp: string, createdTime: string, currency: string, custom: string, custom10: string, custom2: string, custom3: string, custom4: string, custom5: string, custom6: string, custom7: string, custom8: string, custom9: string, dailymotion: string, deezer: string, deletedTime: string, digitalocean: string, dingtalk: string, discord: string, displayName: string, douyin: string, dropbox: string, education: string, email: string, emailVerified: bool, eveonline: string, externalId: string, faceIds: list<record>, facebook: string, firstName: string, fitbit: string, gender: string, gitea: string, gitee: string, github: string, gitlab: string, google: string, groups: list<string>, hash: string, heroku: string, homepage: string, id: string, idCard: string, idCardType: string, influxcloud: string, infoflow: string, instagram: string, intercom: string, invitation: string, invitationCode: string, ipWhitelist: string, isAdmin: bool, isDefaultAvatar: bool, isDeleted: bool, isForbidden: bool, isOnline: bool, isVerified: bool, kakao: string, karma: int, kwai: string, language: string, lark: string, lastChangePasswordTime: string, lastName: string, lastSigninIp: string, lastSigninTime: string, lastSigninWrongTime: string, lastfm: string, ldap: string, line: string, linkedin: string, location: string, mailru: string, managedAccounts: list<record>, meetup: string, metamask: string, mfaAccounts: list<record>, mfaEmailEnabled: bool, mfaItems: list<record>, mfaPhoneEnabled: bool, mfaPushEnabled: bool, mfaPushProvider: string, mfaPushReceiver: string, mfaRadiusEnabled: bool, mfaRadiusProvider: string, mfaRadiusUsername: string, mfaRememberDeadline: string, microsoftonline: string, multiFactorAuths: list<record>, name: string, naver: string, needUpdatePassword: bool, nextcloud: string, okta: string, onedrive: string, originalRefreshToken: string, originalToken: string, oura: string, owner: string, password: string, passwordSalt: string, passwordType: string, patreon: string, paypal: string, permanentAvatar: string, permissions: list<record>, phone: string, preHash: string, preferredMfaType: string, properties: any, qq: string, ranking: int, realName: string, recoveryCodes: list<string>, region: string, registerSource: string, registerType: string, roles: list<record>, salesforce: string, score: int, shopify: string, signinWrongTimes: int, signupApplication: string, slack: string, soundcloud: string, spotify: string, steam: string, strava: string, stripe: string, tag: string, tiktok: string, title: string, totpSecret: string, tumblr: string, twitch: string, twitter: string, type: string, typetalk: string, uber: string, updatedTime: string, vk: string, web3onboard: string, webauthnCredentials: list<record>, wechat: string, wecom: string, weibo: string, wepay: string, xero: string, yahoo: string, yammer: string, yandex: string, zoom: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/get-global-users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get group
#
# GET /api/get-group
# operationId: ApiController.GetGroup
export def "get-group ApiControllerGetGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the group
]: nothing -> record<children: list<any>, contactEmail: string, createdTime: string, displayName: string, haveChildren: bool, isEnabled: bool, isTopGroup: bool, key: string, manager: string, name: string, owner: string, parentId: string, parentName: string, title: string, type: string, updatedTime: string, users: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-group" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get groups
#
# GET /api/get-groups
# operationId: ApiController.GetGroups
export def "get-groups ApiControllerGetGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # The owner of groups
]: nothing -> table<children: list<any>, contactEmail: string, createdTime: string, displayName: string, haveChildren: bool, isEnabled: bool, isTopGroup: bool, key: string, manager: string, name: string, owner: string, parentId: string, parentName: string, title: string, type: string, updatedTime: string, users: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get invitation
#
# GET /api/get-invitation
# operationId: ApiController.GetInvitation
export def "get-invitation ApiControllerGetInvitation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the invitation
]: nothing -> record<application: string, code: string, createdTime: string, defaultCode: string, displayName: string, email: string, isRegexp: bool, name: string, owner: string, phone: string, quota: int, signupGroup: string, state: string, updatedTime: string, usedCount: int, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-invitation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get invitation code information
#
# GET /api/get-invitation-info
# operationId: ApiController.GetInvitationCodeInfo
export def "get-invitation-info ApiControllerGetInvitationCodeInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --code: string # Invitation code
]: nothing -> record<application: string, code: string, createdTime: string, defaultCode: string, displayName: string, email: string, isRegexp: bool, name: string, owner: string, phone: string, quota: int, signupGroup: string, state: string, updatedTime: string, usedCount: int, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "code" $code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-invitation-info" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get invitations
#
# GET /api/get-invitations
# operationId: ApiController.GetInvitations
export def "get-invitations ApiControllerGetInvitations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # The owner of invitations
]: nothing -> table<application: string, code: string, createdTime: string, defaultCode: string, displayName: string, email: string, isRegexp: bool, name: string, owner: string, phone: string, quota: int, signupGroup: string, state: string, updatedTime: string, usedCount: int, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-invitations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get ldap
#
# GET /api/get-ldap
# operationId: ApiController.GetLdap
export def "get-ldap ApiControllerGetLdap" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # id
]: nothing -> record<allowSelfSignedCert: bool, autoSync: int, baseDn: string, createdTime: string, customAttributes: any, defaultGroup: string, enableSsl: bool, filter: string, filterFields: list<string>, host: string, id: string, lastSync: string, owner: string, password: string, passwordType: string, port: int, serverName: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-ldap" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get ldap users
#
# GET /api/get-ldap-users
# operationId: ApiController.GetLdapser
export def "get-ldap-users ApiControllerGetLdapser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<existUuids: list<string>, users: table<EmailAddress: string, Mail: string, MobileTelephoneNumber: string, PostalAddress: string, RegisteredAddress: string, TelephoneNumber: string, address: string, attributes: any, cn: string, country: string, countryName: string, displayName: string, email: string, gidNumber: string, groupId: string, memberOf: string, mobile: string, uid: string, uidNumber: string, userPrincipalName: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/get-ldap-users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get ldaps
#
# GET /api/get-ldaps
# operationId: ApiController.GetLdaps
export def "get-ldaps ApiControllerGetLdaps" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # owner
]: nothing -> table<allowSelfSignedCert: bool, autoSync: int, baseDn: string, createdTime: string, customAttributes: any, defaultGroup: string, enableSsl: bool, filter: string, filterFields: list<string>, host: string, id: string, lastSync: string, owner: string, password: string, passwordType: string, port: int, serverName: string, username: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-ldaps" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get model
#
# GET /api/get-model
# operationId: ApiController.GetModel
export def "get-model ApiControllerGetModel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the model
]: nothing -> record<createdTime: string, description: string, displayName: string, modelText: string, name: string, owner: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-model" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get models
#
# GET /api/get-models
# operationId: ApiController.GetModels
export def "get-models ApiControllerGetModels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # The owner of models
]: nothing -> table<createdTime: string, description: string, displayName: string, modelText: string, name: string, owner: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-models" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get order
#
# GET /api/get-order
# operationId: ApiController.GetOrder
export def "get-order ApiControllerGetOrder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the order
]: nothing -> record<createdTime: string, currency: string, displayName: string, message: string, name: string, owner: string, payment: string, price: float, productInfos: table<currency: string, detail: string, displayName: string, image: string, isRecharge: bool, name: string, owner: string, planName: string, price: float, pricingName: string, quantity: int>, products: list<string>, state: string, updateTime: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-order" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get orders
#
# GET /api/get-orders
# operationId: ApiController.GetOrders
export def "get-orders ApiControllerGetOrders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # The owner of orders
]: nothing -> table<createdTime: string, currency: string, displayName: string, message: string, name: string, owner: string, payment: string, price: float, productInfos: list<record>, products: list<string>, state: string, updateTime: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-orders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get organization
#
# GET /api/get-organization
# operationId: ApiController.GetOrganization
export def "get-organization ApiControllerGetOrganization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # organization id
]: nothing -> record<accountItems: table<modifyRule: string, name: string, regex: string, tab: string, viewRule: string, visible: bool>, accountMenu: string, balanceCredit: float, balanceCurrency: string, countryCodes: list<string>, createdTime: string, defaultApplication: string, defaultAvatar: string, defaultPassword: string, disableSignin: bool, displayName: string, enableSoftDeletion: bool, enableTour: bool, favicon: string, hasPrivilegeConsent: bool, initScore: int, ipRestriction: string, ipWhitelist: string, isProfilePublic: bool, languages: list<string>, logo: string, logoDark: string, masterPassword: string, masterVerificationCode: string, mfaItems: table<name: string, rule: string>, mfaRememberInHours: int, name: string, navItems: list<string>, orgBalance: float, owner: string, passwordExpireDays: int, passwordObfuscatorKey: string, passwordObfuscatorType: string, passwordOptions: list<string>, passwordSalt: string, passwordType: string, tags: list<string>, themeData: record<borderRadius: int, colorPrimary: string, isCompact: bool, isEnabled: bool, themeType: string>, useEmailAsUsername: bool, userBalance: float, userNavItems: list<string>, userTypes: list<string>, websiteUrl: string, widgetItems: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-organization" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get the detail of the organization's application
#
# GET /api/get-organization-applications
# operationId: ApiController.GetOrganizationApplications
export def "get-organization-applications ApiControllerGetOrganizationApplications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organization: string # The organization name
]: nothing -> table<affiliationUrl: string, cert: string, certPublicKey: string, clientId: string, clientSecret: string, codeResendTimeout: int, cookieExpireInHours: int, createdTime: string, defaultGroup: string, description: string, disableSamlAttributes: bool, disableSignin: bool, displayName: string, enableAutoSignin: bool, enableCodeSignin: bool, enableExclusiveSignin: bool, enableLinkWithEmail: bool, enablePassword: bool, enableSamlAssertionSignature: bool, enableSamlC14n10: bool, enableSamlCompress: bool, enableSamlPostBinding: bool, enableSignUp: bool, enableSigninSession: bool, enableWebAuthn: bool, expireInHours: float, failedSigninFrozenTime: int, failedSigninLimit: int, favicon: string, footerHtml: string, forcedRedirectOrigin: string, forgetUrl: string, formBackgroundUrl: string, formBackgroundUrlMobile: string, formCss: string, formCssMobile: string, formOffset: int, formSideHtml: string, grantTypes: list<string>, headerHtml: string, homepageUrl: string, ipRestriction: string, ipWhitelist: string, isShared: bool, logo: string, name: string, order: int, orgChoiceMode: string, organization: string, organizationObj: record<accountItems: list, accountMenu: string, balanceCredit: float, balanceCurrency: string, countryCodes: list, createdTime: string, defaultApplication: string, defaultAvatar: string, defaultPassword: string, disableSignin: bool, displayName: string, enableSoftDeletion: bool, enableTour: bool, favicon: string, hasPrivilegeConsent: bool, initScore: int, ipRestriction: string, ipWhitelist: string, isProfilePublic: bool, languages: list, logo: string, logoDark: string, masterPassword: string, masterVerificationCode: string, mfaItems: list, mfaRememberInHours: int, name: string, navItems: list, orgBalance: float, owner: string, passwordExpireDays: int, passwordObfuscatorKey: string, passwordObfuscatorType: string, passwordOptions: list, passwordSalt: string, passwordType: string, tags: list, themeData: record, useEmailAsUsername: bool, userBalance: float, userNavItems: list, userTypes: list, websiteUrl: string, widgetItems: list>, owner: string, providers: list<record>, redirectUris: list<string>, refreshExpireInHours: float, samlAttributes: list<record>, samlHashAlgorithm: string, samlReplyUrl: string, signinHtml: string, signinItems: list<record>, signinMethods: list<record>, signinUrl: string, signupHtml: string, signupItems: list<record>, signupUrl: string, tags: list<string>, termsOfUse: string, themeData: record<borderRadius: int, colorPrimary: string, isCompact: bool, isEnabled: bool, themeType: string>, title: string, tokenAttributes: list<record>, tokenFields: list<string>, tokenFormat: string, tokenSigningMethod: string, useEmailAsSamlNameId: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organization" $organization "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-organization-applications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get all organization name and displayName
#
# GET /api/get-organization-names
# operationId: ApiController.GetOrganizationNames
export def "get-organization-names ApiControllerGetOrganizationNames" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # owner
]: nothing -> table<accountItems: list<record>, accountMenu: string, balanceCredit: float, balanceCurrency: string, countryCodes: list<string>, createdTime: string, defaultApplication: string, defaultAvatar: string, defaultPassword: string, disableSignin: bool, displayName: string, enableSoftDeletion: bool, enableTour: bool, favicon: string, hasPrivilegeConsent: bool, initScore: int, ipRestriction: string, ipWhitelist: string, isProfilePublic: bool, languages: list<string>, logo: string, logoDark: string, masterPassword: string, masterVerificationCode: string, mfaItems: list<record>, mfaRememberInHours: int, name: string, navItems: list<string>, orgBalance: float, owner: string, passwordExpireDays: int, passwordObfuscatorKey: string, passwordObfuscatorType: string, passwordOptions: list<string>, passwordSalt: string, passwordType: string, tags: list<string>, themeData: record<borderRadius: int, colorPrimary: string, isCompact: bool, isEnabled: bool, themeType: string>, useEmailAsUsername: bool, userBalance: float, userNavItems: list<string>, userTypes: list<string>, websiteUrl: string, widgetItems: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-organization-names" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get organizations
#
# GET /api/get-organizations
# operationId: ApiController.GetOrganizations
export def "get-organizations ApiControllerGetOrganizations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # owner
]: nothing -> table<accountItems: list<record>, accountMenu: string, balanceCredit: float, balanceCurrency: string, countryCodes: list<string>, createdTime: string, defaultApplication: string, defaultAvatar: string, defaultPassword: string, disableSignin: bool, displayName: string, enableSoftDeletion: bool, enableTour: bool, favicon: string, hasPrivilegeConsent: bool, initScore: int, ipRestriction: string, ipWhitelist: string, isProfilePublic: bool, languages: list<string>, logo: string, logoDark: string, masterPassword: string, masterVerificationCode: string, mfaItems: list<record>, mfaRememberInHours: int, name: string, navItems: list<string>, orgBalance: float, owner: string, passwordExpireDays: int, passwordObfuscatorKey: string, passwordObfuscatorType: string, passwordOptions: list<string>, passwordSalt: string, passwordType: string, tags: list<string>, themeData: record<borderRadius: int, colorPrimary: string, isCompact: bool, isEnabled: bool, themeType: string>, useEmailAsUsername: bool, userBalance: float, userNavItems: list<string>, userTypes: list<string>, websiteUrl: string, widgetItems: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-organizations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get payment
#
# GET /api/get-payment
# operationId: ApiController.GetVerification
export def "get-payment ApiControllerGetVerification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the payment
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-payment" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get payments
#
# GET /api/get-payments
# operationId: ApiController.GetVerifications
export def "get-payments ApiControllerGetVerifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # The owner of payments
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-payments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get permission
#
# GET /api/get-permission
# operationId: ApiController.GetPermission
export def "get-permission ApiControllerGetPermission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the permission
]: nothing -> record<actions: list<string>, adapter: string, approveTime: string, approver: string, createdTime: string, description: string, displayName: string, domains: list<string>, effect: string, groups: list<string>, isEnabled: bool, model: string, name: string, owner: string, resourceType: string, resources: list<string>, roles: list<string>, state: string, submitter: string, users: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-permission" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get permissions
#
# GET /api/get-permissions
# operationId: ApiController.GetPermissions
export def "get-permissions ApiControllerGetPermissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # The owner of permissions
]: nothing -> table<actions: list<string>, adapter: string, approveTime: string, approver: string, createdTime: string, description: string, displayName: string, domains: list<string>, effect: string, groups: list<string>, isEnabled: bool, model: string, name: string, owner: string, resourceType: string, resources: list<string>, roles: list<string>, state: string, submitter: string, users: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-permissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get permissions by role
#
# GET /api/get-permissions-by-role
# operationId: ApiController.GetPermissionsByRole
export def "get-permissions-by-role ApiControllerGetPermissionsByRole" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the role
]: nothing -> table<actions: list<string>, adapter: string, approveTime: string, approver: string, createdTime: string, description: string, displayName: string, domains: list<string>, effect: string, groups: list<string>, isEnabled: bool, model: string, name: string, owner: string, resourceType: string, resources: list<string>, roles: list<string>, state: string, submitter: string, users: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-permissions-by-role" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get permissions by submitter
#
# GET /api/get-permissions-by-submitter
# operationId: ApiController.GetPermissionsBySubmitter
export def "get-permissions-by-submitter ApiControllerGetPermissionsBySubmitter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<actions: list<string>, adapter: string, approveTime: string, approver: string, createdTime: string, description: string, displayName: string, domains: list<string>, effect: string, groups: list<string>, isEnabled: bool, model: string, name: string, owner: string, resourceType: string, resources: list<string>, roles: list<string>, state: string, submitter: string, users: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/get-permissions-by-submitter")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get plan
#
# GET /api/get-plan
# operationId: ApiController.GetPlan
export def "get-plan ApiControllerGetPlan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the plan
  --includeOption: oneof<nothing, bool> # Should include plan's option
]: nothing -> record<createdTime: string, currency: string, description: string, displayName: string, isEnabled: bool, name: string, options: list<string>, owner: string, paymentProviders: list<string>, period: string, price: float, product: string, role: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "includeOption" $includeOption "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-plan" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get plans
#
# GET /api/get-plans
# operationId: ApiController.GetPlans
export def "get-plans ApiControllerGetPlans" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # The owner of plans
]: nothing -> table<createdTime: string, currency: string, description: string, displayName: string, isEnabled: bool, name: string, options: list<string>, owner: string, paymentProviders: list<string>, period: string, price: float, product: string, role: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-plans" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get policies
#
# GET /api/get-policies
# operationId: ApiController.GetPolicies
export def "get-policies ApiControllerGetPolicies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name )  of enforcer
  --adapterId: string # The adapter id
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "adapterId" $adapterId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-policies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get pricing
#
# GET /api/get-pricing
# operationId: ApiController.GetPricing
export def "get-pricing ApiControllerGetPricing" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the pricing
]: nothing -> record<application: string, createdTime: string, description: string, displayName: string, isEnabled: bool, name: string, owner: string, plans: list<string>, trialDuration: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-pricing" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get pricings
#
# GET /api/get-pricings
# operationId: ApiController.GetPricings
export def "get-pricings ApiControllerGetPricings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # The owner of pricings
]: nothing -> table<application: string, createdTime: string, description: string, displayName: string, isEnabled: bool, name: string, owner: string, plans: list<string>, trialDuration: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-pricings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get product
#
# GET /api/get-product
# operationId: ApiController.GetProduct
export def "get-product ApiControllerGetProduct" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the product
]: nothing -> record<createdTime: string, currency: string, description: string, detail: string, disableCustomRecharge: bool, displayName: string, image: string, isRecharge: bool, name: string, owner: string, price: float, providerObjs: table<appId: string, bucket: string, category: string, cert: string, clientId: string, clientId2: string, clientSecret: string, clientSecret2: string, content: string, createdTime: string, customAuthUrl: string, customLogo: string, customTokenUrl: string, customUserInfoUrl: string, disableSsl: bool, displayName: string, domain: string, emailRegex: string, enablePkce: bool, enableProxy: bool, enableSignAuthnRequest: bool, endpoint: string, host: string, httpHeaders: any, idP: string, intranetEndpoint: string, issuerUrl: string, metadata: string, method: string, name: string, owner: string, pathPrefix: string, port: int, providerUrl: string, receiver: string, regionId: string, scopes: string, signName: string, subType: string, templateCode: string, title: string, type: string, userMapping: any>, providers: list<string>, quantity: int, rechargeOptions: list<float>, sold: int, state: string, successUrl: string, tag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-product" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get products
#
# GET /api/get-products
# operationId: ApiController.GetProducts
export def "get-products ApiControllerGetProducts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # The owner of products
]: nothing -> table<createdTime: string, currency: string, description: string, detail: string, disableCustomRecharge: bool, displayName: string, image: string, isRecharge: bool, name: string, owner: string, price: float, providerObjs: list<record>, providers: list<string>, quantity: int, rechargeOptions: list<float>, sold: int, state: string, successUrl: string, tag: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-products" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get Prometheus Info
#
# GET /api/get-prometheus-info
# operationId: ApiController.GetPrometheusInfo
export def "get-prometheus-info ApiControllerGetPrometheusInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<apiLatency: table<count: int, latency: string, method: string, name: string>, apiThroughput: table<method: string, name: string, throughput: float>, totalThroughput: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/get-prometheus-info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get provider
#
# GET /api/get-provider
# operationId: ApiController.GetProvider
export def "get-provider ApiControllerGetProvider" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the provider
]: nothing -> record<appId: string, bucket: string, category: string, cert: string, clientId: string, clientId2: string, clientSecret: string, clientSecret2: string, content: string, createdTime: string, customAuthUrl: string, customLogo: string, customTokenUrl: string, customUserInfoUrl: string, disableSsl: bool, displayName: string, domain: string, emailRegex: string, enablePkce: bool, enableProxy: bool, enableSignAuthnRequest: bool, endpoint: string, host: string, httpHeaders: any, idP: string, intranetEndpoint: string, issuerUrl: string, metadata: string, method: string, name: string, owner: string, pathPrefix: string, port: int, providerUrl: string, receiver: string, regionId: string, scopes: string, signName: string, subType: string, templateCode: string, title: string, type: string, userMapping: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-provider" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get providers
#
# GET /api/get-providers
# operationId: ApiController.GetProviders
export def "get-providers ApiControllerGetProviders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # The owner of providers
]: nothing -> table<appId: string, bucket: string, category: string, cert: string, clientId: string, clientId2: string, clientSecret: string, clientSecret2: string, content: string, createdTime: string, customAuthUrl: string, customLogo: string, customTokenUrl: string, customUserInfoUrl: string, disableSsl: bool, displayName: string, domain: string, emailRegex: string, enablePkce: bool, enableProxy: bool, enableSignAuthnRequest: bool, endpoint: string, host: string, httpHeaders: any, idP: string, intranetEndpoint: string, issuerUrl: string, metadata: string, method: string, name: string, owner: string, pathPrefix: string, port: int, providerUrl: string, receiver: string, regionId: string, scopes: string, signName: string, subType: string, templateCode: string, title: string, type: string, userMapping: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-providers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/get-qrcode
#
# operationId: ApiController.GetWechatQRCode
export def "get-qrcode ApiControllerGetWechatQRCode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of provider
]: nothing -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-qrcode" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get all records
#
# GET /api/get-records
# operationId: ApiController.GetRecords
export def "get-records ApiControllerGetRecords" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --pageSize: string # The size of each page
  --p: string # The number of the page
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "p" $p "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-records" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get records by filter
#
# POST /api/get-records-filter
# operationId: ApiController.GetRecordsByFilter
export def "get-records-filter ApiControllerGetRecordsByFilter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/get-records-filter")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# get resource
#
# GET /api/get-resource
# operationId: ApiController.GetResource
export def "get-resource ApiControllerGetResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of resource
]: nothing -> record<application: string, createdTime: string, description: string, fileFormat: string, fileName: string, fileSize: int, fileType: string, name: string, owner: string, parent: string, provider: string, tag: string, url: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-resource" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get resources
#
# GET /api/get-resources
# operationId: ApiController.GetResources
export def "get-resources ApiControllerGetResources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # Owner
  --user: string # User
  --pageSize: int # Page Size
  --p: int # Page Number
  --field: string # Field
  --value: string # Value
  --sortField: string # Sort Field
  --sortOrder: string # Sort Order
]: nothing -> table<application: string, createdTime: string, description: string, fileFormat: string, fileName: string, fileSize: int, fileType: string, name: string, owner: string, parent: string, provider: string, tag: string, url: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "p" $p "scalar") (serialize-qp "field" $field "scalar") (serialize-qp "value" $value "scalar") (serialize-qp "sortField" $sortField "scalar") (serialize-qp "sortOrder" $sortOrder "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-resources" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get role
#
# GET /api/get-role
# operationId: ApiController.GetRole
export def "get-role ApiControllerGetRole" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the role
]: nothing -> record<createdTime: string, description: string, displayName: string, domains: list<string>, groups: list<string>, isEnabled: bool, name: string, owner: string, roles: list<string>, users: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-role" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get roles
#
# GET /api/get-roles
# operationId: ApiController.GetRoles
export def "get-roles ApiControllerGetRoles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # The owner of roles
]: nothing -> table<createdTime: string, description: string, displayName: string, domains: list<string>, groups: list<string>, isEnabled: bool, name: string, owner: string, roles: list<string>, users: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get session for one user in one application.
#
# GET /api/get-session
# operationId: ApiController.GetSingleSession
export def "get-session ApiControllerGetSingleSession" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sessionPkId: string # The session ID in format: organization/user/application (e.g., built-in/admin/app-built-in)
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sessionPkId" $sessionPkId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-session" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get organization user sessions.
#
# GET /api/get-sessions
# operationId: ApiController.GetSessions
export def "get-sessions ApiControllerGetSessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # The organization name
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-sessions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/get-sorted-users
#
# operationId: ApiController.GetSortedUsers
export def "get-sorted-users ApiControllerGetSortedUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # The owner of users
  --sorter: string # The DB column name to sort by, e.g., created_time
  --limit: string # The count of users to return, e.g., 25
]: nothing -> table<accessKey: string, accessSecret: string, accessToken: string, address: list<string>, addresses: list<record>, adfs: string, affiliation: string, alipay: string, amazon: string, apple: string, auth0: string, avatar: string, avatarType: string, azuread: string, azureadb2c: string, baidu: string, balance: float, balanceCredit: float, balanceCurrency: string, battlenet: string, bilibili: string, bio: string, birthday: string, bitbucket: string, box: string, cart: list<record>, casdoor: string, cloudfoundry: string, countryCode: string, createdIp: string, createdTime: string, currency: string, custom: string, custom10: string, custom2: string, custom3: string, custom4: string, custom5: string, custom6: string, custom7: string, custom8: string, custom9: string, dailymotion: string, deezer: string, deletedTime: string, digitalocean: string, dingtalk: string, discord: string, displayName: string, douyin: string, dropbox: string, education: string, email: string, emailVerified: bool, eveonline: string, externalId: string, faceIds: list<record>, facebook: string, firstName: string, fitbit: string, gender: string, gitea: string, gitee: string, github: string, gitlab: string, google: string, groups: list<string>, hash: string, heroku: string, homepage: string, id: string, idCard: string, idCardType: string, influxcloud: string, infoflow: string, instagram: string, intercom: string, invitation: string, invitationCode: string, ipWhitelist: string, isAdmin: bool, isDefaultAvatar: bool, isDeleted: bool, isForbidden: bool, isOnline: bool, isVerified: bool, kakao: string, karma: int, kwai: string, language: string, lark: string, lastChangePasswordTime: string, lastName: string, lastSigninIp: string, lastSigninTime: string, lastSigninWrongTime: string, lastfm: string, ldap: string, line: string, linkedin: string, location: string, mailru: string, managedAccounts: list<record>, meetup: string, metamask: string, mfaAccounts: list<record>, mfaEmailEnabled: bool, mfaItems: list<record>, mfaPhoneEnabled: bool, mfaPushEnabled: bool, mfaPushProvider: string, mfaPushReceiver: string, mfaRadiusEnabled: bool, mfaRadiusProvider: string, mfaRadiusUsername: string, mfaRememberDeadline: string, microsoftonline: string, multiFactorAuths: list<record>, name: string, naver: string, needUpdatePassword: bool, nextcloud: string, okta: string, onedrive: string, originalRefreshToken: string, originalToken: string, oura: string, owner: string, password: string, passwordSalt: string, passwordType: string, patreon: string, paypal: string, permanentAvatar: string, permissions: list<record>, phone: string, preHash: string, preferredMfaType: string, properties: any, qq: string, ranking: int, realName: string, recoveryCodes: list<string>, region: string, registerSource: string, registerType: string, roles: list<record>, salesforce: string, score: int, shopify: string, signinWrongTimes: int, signupApplication: string, slack: string, soundcloud: string, spotify: string, steam: string, strava: string, stripe: string, tag: string, tiktok: string, title: string, totpSecret: string, tumblr: string, twitch: string, twitter: string, type: string, typetalk: string, uber: string, updatedTime: string, vk: string, web3onboard: string, webauthnCredentials: list<record>, wechat: string, wecom: string, weibo: string, wepay: string, xero: string, yahoo: string, yammer: string, yandex: string, zoom: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar") (serialize-qp "sorter" $sorter "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-sorted-users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get subscription
#
# GET /api/get-subscription
# operationId: ApiController.GetSubscription
export def "get-subscription ApiControllerGetSubscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the subscription
]: nothing -> record<createdTime: string, description: string, displayName: string, endTime: string, name: string, owner: string, payment: string, period: string, plan: string, pricing: string, startTime: string, state: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-subscription" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get subscriptions
#
# GET /api/get-subscriptions
# operationId: ApiController.GetSubscriptions
export def "get-subscriptions ApiControllerGetSubscriptions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # The owner of subscriptions
]: nothing -> table<createdTime: string, description: string, displayName: string, endTime: string, name: string, owner: string, payment: string, period: string, plan: string, pricing: string, startTime: string, state: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get syncer
#
# GET /api/get-syncer
# operationId: ApiController.GetSyncer
export def "get-syncer ApiControllerGetSyncer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the syncer
]: nothing -> record<affiliationTable: string, avatarBaseUrl: string, cert: string, createdTime: string, database: string, databaseType: string, errorText: string, host: string, isEnabled: bool, isReadOnly: bool, name: string, organization: string, owner: string, password: string, port: int, sshHost: string, sshPassword: string, sshPort: int, sshType: string, sshUser: string, sslMode: string, syncInterval: int, table: string, tableColumns: table<casdoorName: string, isHashed: bool, isKey: bool, name: string, type: string, values: list>, type: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-syncer" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get syncers
#
# GET /api/get-syncers
# operationId: ApiController.GetSyncers
export def "get-syncers ApiControllerGetSyncers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # The owner of syncers
]: nothing -> table<affiliationTable: string, avatarBaseUrl: string, cert: string, createdTime: string, database: string, databaseType: string, errorText: string, host: string, isEnabled: bool, isReadOnly: bool, name: string, organization: string, owner: string, password: string, port: int, sshHost: string, sshPassword: string, sshPort: int, sshType: string, sshUser: string, sslMode: string, syncInterval: int, table: string, tableColumns: list<record>, type: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-syncers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get system info like CPU and memory usage
#
# GET /api/get-system-info
# operationId: ApiController.GetSystemInfo
export def "get-system-info ApiControllerGetSystemInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<cpuUsage: list<float>, memoryTotal: int, memoryUsed: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/get-system-info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get ticket
#
# GET /api/get-ticket
# operationId: ApiController.GetTicket
export def "get-ticket ApiControllerGetTicket" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the ticket
]: nothing -> record<content: string, createdTime: string, displayName: string, messages: table<author: string, isAdmin: bool, text: string, timestamp: string>, name: string, owner: string, state: string, title: string, updatedTime: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-ticket" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get tickets
#
# GET /api/get-tickets
# operationId: ApiController.GetTickets
export def "get-tickets ApiControllerGetTickets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # The owner of tickets
]: nothing -> table<content: string, createdTime: string, displayName: string, messages: list<record>, name: string, owner: string, state: string, title: string, updatedTime: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-tickets" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get token
#
# GET /api/get-token
# operationId: ApiController.GetToken
export def "get-token ApiControllerGetToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The token ID in format: organization/token-name (e.g., built-in/token-123456)
]: nothing -> record<accessToken: string, accessTokenHash: string, application: string, code: string, codeChallenge: string, codeExpireIn: int, codeIsUsed: bool, createdTime: string, expiresIn: int, name: string, organization: string, owner: string, refreshToken: string, refreshTokenHash: string, scope: string, tokenType: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-token" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get tokens
#
# GET /api/get-tokens
# operationId: ApiController.GetTokens
export def "get-tokens ApiControllerGetTokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # The organization name (e.g., built-in)
  --pageSize: string # The size of each page
  --p: string # The number of the page
]: nothing -> table<accessToken: string, accessTokenHash: string, application: string, code: string, codeChallenge: string, codeExpireIn: int, codeIsUsed: bool, createdTime: string, expiresIn: int, name: string, organization: string, owner: string, refreshToken: string, refreshTokenHash: string, scope: string, tokenType: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "p" $p "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-tokens" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get transaction
#
# GET /api/get-transaction
# operationId: ApiController.GetTransaction
export def "get-transaction ApiControllerGetTransaction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the transaction
]: nothing -> record<amount: float, application: string, category: string, createdTime: string, currency: string, displayName: string, domain: string, name: string, owner: string, payment: string, provider: string, state: string, subtype: string, tag: string, type: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-transaction" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get transactions
#
# GET /api/get-transactions
# operationId: ApiController.GetTransactions
export def "get-transactions ApiControllerGetTransactions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # The owner of transactions
]: nothing -> table<amount: float, application: string, category: string, createdTime: string, currency: string, displayName: string, domain: string, name: string, owner: string, payment: string, provider: string, state: string, subtype: string, tag: string, type: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-transactions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get user
#
# GET /api/get-user
# operationId: ApiController.GetUser
export def "get-user ApiControllerGetUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the user
  --owner: string # The owner of the user
  --email: string # The email of the user
  --phone: string # The phone of the user
  --userId: string # The userId of the user
]: nothing -> record<accessKey: string, accessSecret: string, accessToken: string, address: list<string>, addresses: table<city: string, line1: string, line2: string, region: string, state: string, tag: string, zipCode: string>, adfs: string, affiliation: string, alipay: string, amazon: string, apple: string, auth0: string, avatar: string, avatarType: string, azuread: string, azureadb2c: string, baidu: string, balance: float, balanceCredit: float, balanceCurrency: string, battlenet: string, bilibili: string, bio: string, birthday: string, bitbucket: string, box: string, cart: table<currency: string, detail: string, displayName: string, image: string, isRecharge: bool, name: string, owner: string, planName: string, price: float, pricingName: string, quantity: int>, casdoor: string, cloudfoundry: string, countryCode: string, createdIp: string, createdTime: string, currency: string, custom: string, custom10: string, custom2: string, custom3: string, custom4: string, custom5: string, custom6: string, custom7: string, custom8: string, custom9: string, dailymotion: string, deezer: string, deletedTime: string, digitalocean: string, dingtalk: string, discord: string, displayName: string, douyin: string, dropbox: string, education: string, email: string, emailVerified: bool, eveonline: string, externalId: string, faceIds: table<ImageUrl: string, faceIdData: list, name: string>, facebook: string, firstName: string, fitbit: string, gender: string, gitea: string, gitee: string, github: string, gitlab: string, google: string, groups: list<string>, hash: string, heroku: string, homepage: string, id: string, idCard: string, idCardType: string, influxcloud: string, infoflow: string, instagram: string, intercom: string, invitation: string, invitationCode: string, ipWhitelist: string, isAdmin: bool, isDefaultAvatar: bool, isDeleted: bool, isForbidden: bool, isOnline: bool, isVerified: bool, kakao: string, karma: int, kwai: string, language: string, lark: string, lastChangePasswordTime: string, lastName: string, lastSigninIp: string, lastSigninTime: string, lastSigninWrongTime: string, lastfm: string, ldap: string, line: string, linkedin: string, location: string, mailru: string, managedAccounts: table<application: string, password: string, signinUrl: string, username: string>, meetup: string, metamask: string, mfaAccounts: table<accountName: string, issuer: string, origin: string, secretKey: string>, mfaEmailEnabled: bool, mfaItems: table<name: string, rule: string>, mfaPhoneEnabled: bool, mfaPushEnabled: bool, mfaPushProvider: string, mfaPushReceiver: string, mfaRadiusEnabled: bool, mfaRadiusProvider: string, mfaRadiusUsername: string, mfaRememberDeadline: string, microsoftonline: string, multiFactorAuths: table<countryCode: string, enabled: bool, isPreferred: bool, mfaRememberInHours: int, mfaType: string, recoveryCodes: list, secret: string, url: string>, name: string, naver: string, needUpdatePassword: bool, nextcloud: string, okta: string, onedrive: string, originalRefreshToken: string, originalToken: string, oura: string, owner: string, password: string, passwordSalt: string, passwordType: string, patreon: string, paypal: string, permanentAvatar: string, permissions: table<actions: list, adapter: string, approveTime: string, approver: string, createdTime: string, description: string, displayName: string, domains: list, effect: string, groups: list, isEnabled: bool, model: string, name: string, owner: string, resourceType: string, resources: list, roles: list, state: string, submitter: string, users: list>, phone: string, preHash: string, preferredMfaType: string, properties: any, qq: string, ranking: int, realName: string, recoveryCodes: list<string>, region: string, registerSource: string, registerType: string, roles: table<createdTime: string, description: string, displayName: string, domains: list, groups: list, isEnabled: bool, name: string, owner: string, roles: list, users: list>, salesforce: string, score: int, shopify: string, signinWrongTimes: int, signupApplication: string, slack: string, soundcloud: string, spotify: string, steam: string, strava: string, stripe: string, tag: string, tiktok: string, title: string, totpSecret: string, tumblr: string, twitch: string, twitter: string, type: string, typetalk: string, uber: string, updatedTime: string, vk: string, web3onboard: string, webauthnCredentials: list<record>, wechat: string, wecom: string, weibo: string, wepay: string, xero: string, yahoo: string, yammer: string, yandex: string, zoom: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "owner" $owner "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "phone" $phone "scalar") (serialize-qp "userId" $userId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-user" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get the detail of the user's application
#
# GET /api/get-user-application
# operationId: ApiController.GetUserApplication
export def "get-user-application ApiControllerGetUserApplication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the user
]: nothing -> record<affiliationUrl: string, cert: string, certPublicKey: string, clientId: string, clientSecret: string, codeResendTimeout: int, cookieExpireInHours: int, createdTime: string, defaultGroup: string, description: string, disableSamlAttributes: bool, disableSignin: bool, displayName: string, enableAutoSignin: bool, enableCodeSignin: bool, enableExclusiveSignin: bool, enableLinkWithEmail: bool, enablePassword: bool, enableSamlAssertionSignature: bool, enableSamlC14n10: bool, enableSamlCompress: bool, enableSamlPostBinding: bool, enableSignUp: bool, enableSigninSession: bool, enableWebAuthn: bool, expireInHours: float, failedSigninFrozenTime: int, failedSigninLimit: int, favicon: string, footerHtml: string, forcedRedirectOrigin: string, forgetUrl: string, formBackgroundUrl: string, formBackgroundUrlMobile: string, formCss: string, formCssMobile: string, formOffset: int, formSideHtml: string, grantTypes: list<string>, headerHtml: string, homepageUrl: string, ipRestriction: string, ipWhitelist: string, isShared: bool, logo: string, name: string, order: int, orgChoiceMode: string, organization: string, organizationObj: record<accountItems: list<record>, accountMenu: string, balanceCredit: float, balanceCurrency: string, countryCodes: list<string>, createdTime: string, defaultApplication: string, defaultAvatar: string, defaultPassword: string, disableSignin: bool, displayName: string, enableSoftDeletion: bool, enableTour: bool, favicon: string, hasPrivilegeConsent: bool, initScore: int, ipRestriction: string, ipWhitelist: string, isProfilePublic: bool, languages: list<string>, logo: string, logoDark: string, masterPassword: string, masterVerificationCode: string, mfaItems: list<record>, mfaRememberInHours: int, name: string, navItems: list<string>, orgBalance: float, owner: string, passwordExpireDays: int, passwordObfuscatorKey: string, passwordObfuscatorType: string, passwordOptions: list<string>, passwordSalt: string, passwordType: string, tags: list<string>, themeData: record<borderRadius: int, colorPrimary: string, isCompact: bool, isEnabled: bool, themeType: string>, useEmailAsUsername: bool, userBalance: float, userNavItems: list<string>, userTypes: list<string>, websiteUrl: string, widgetItems: list<string>>, owner: string, providers: table<canSignIn: bool, canSignUp: bool, canUnlink: bool, countryCodes: list, name: string, owner: string, prompted: bool, provider: record, rule: string, signupGroup: string>, redirectUris: list<string>, refreshExpireInHours: float, samlAttributes: table<name: string, nameFormat: string, value: string>, samlHashAlgorithm: string, samlReplyUrl: string, signinHtml: string, signinItems: table<customCss: string, isCustom: bool, label: string, name: string, placeholder: string, rule: string, visible: bool>, signinMethods: table<displayName: string, name: string, rule: string>, signinUrl: string, signupHtml: string, signupItems: table<customCss: string, label: string, name: string, options: list, placeholder: string, prompted: bool, regex: string, required: bool, rule: string, type: string, visible: bool>, signupUrl: string, tags: list<string>, termsOfUse: string, themeData: record<borderRadius: int, colorPrimary: string, isCompact: bool, isEnabled: bool, themeType: string>, title: string, tokenAttributes: table<name: string, type: string, value: string>, tokenFields: list<string>, tokenFormat: string, tokenSigningMethod: string, useEmailAsSamlNameId: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-user-application" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/get-user-count
#
# operationId: ApiController.GetUserCount
export def "get-user-count ApiControllerGetUserCount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # The owner of users
  --isOnline: string # The filter for query, 1 for online, 0 for offline, empty string for all users
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar") (serialize-qp "isOnline" $isOnline "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-user-count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get orders for a user
#
# GET /api/get-user-orders
# operationId: ApiController.GetUserOrders
export def "get-user-orders ApiControllerGetUserOrders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # The owner of orders
  --user: string # The username of the user
]: nothing -> table<createdTime: string, currency: string, displayName: string, message: string, name: string, owner: string, payment: string, price: float, productInfos: list<record>, products: list<string>, state: string, updateTime: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar") (serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-user-orders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get payments for a user
#
# GET /api/get-user-payments
# operationId: ApiController.GetUserVerifications
export def "get-user-payments ApiControllerGetUserVerifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # The owner of payments
  --organization: string # The organization of the user
  --user: string # The username of the user
]: nothing -> list<record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar") (serialize-qp "organization" $organization "scalar") (serialize-qp "user" $user "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-user-payments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/get-users
#
# operationId: ApiController.GetUsers
export def "get-users ApiControllerGetUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # The owner of users
]: nothing -> table<accessKey: string, accessSecret: string, accessToken: string, address: list<string>, addresses: list<record>, adfs: string, affiliation: string, alipay: string, amazon: string, apple: string, auth0: string, avatar: string, avatarType: string, azuread: string, azureadb2c: string, baidu: string, balance: float, balanceCredit: float, balanceCurrency: string, battlenet: string, bilibili: string, bio: string, birthday: string, bitbucket: string, box: string, cart: list<record>, casdoor: string, cloudfoundry: string, countryCode: string, createdIp: string, createdTime: string, currency: string, custom: string, custom10: string, custom2: string, custom3: string, custom4: string, custom5: string, custom6: string, custom7: string, custom8: string, custom9: string, dailymotion: string, deezer: string, deletedTime: string, digitalocean: string, dingtalk: string, discord: string, displayName: string, douyin: string, dropbox: string, education: string, email: string, emailVerified: bool, eveonline: string, externalId: string, faceIds: list<record>, facebook: string, firstName: string, fitbit: string, gender: string, gitea: string, gitee: string, github: string, gitlab: string, google: string, groups: list<string>, hash: string, heroku: string, homepage: string, id: string, idCard: string, idCardType: string, influxcloud: string, infoflow: string, instagram: string, intercom: string, invitation: string, invitationCode: string, ipWhitelist: string, isAdmin: bool, isDefaultAvatar: bool, isDeleted: bool, isForbidden: bool, isOnline: bool, isVerified: bool, kakao: string, karma: int, kwai: string, language: string, lark: string, lastChangePasswordTime: string, lastName: string, lastSigninIp: string, lastSigninTime: string, lastSigninWrongTime: string, lastfm: string, ldap: string, line: string, linkedin: string, location: string, mailru: string, managedAccounts: list<record>, meetup: string, metamask: string, mfaAccounts: list<record>, mfaEmailEnabled: bool, mfaItems: list<record>, mfaPhoneEnabled: bool, mfaPushEnabled: bool, mfaPushProvider: string, mfaPushReceiver: string, mfaRadiusEnabled: bool, mfaRadiusProvider: string, mfaRadiusUsername: string, mfaRememberDeadline: string, microsoftonline: string, multiFactorAuths: list<record>, name: string, naver: string, needUpdatePassword: bool, nextcloud: string, okta: string, onedrive: string, originalRefreshToken: string, originalToken: string, oura: string, owner: string, password: string, passwordSalt: string, passwordType: string, patreon: string, paypal: string, permanentAvatar: string, permissions: list<record>, phone: string, preHash: string, preferredMfaType: string, properties: any, qq: string, ranking: int, realName: string, recoveryCodes: list<string>, region: string, registerSource: string, registerType: string, roles: list<record>, salesforce: string, score: int, shopify: string, signinWrongTimes: int, signupApplication: string, slack: string, soundcloud: string, spotify: string, steam: string, strava: string, stripe: string, tag: string, tiktok: string, title: string, totpSecret: string, tumblr: string, twitch: string, twitter: string, type: string, typetalk: string, uber: string, updatedTime: string, vk: string, web3onboard: string, webauthnCredentials: list<record>, wechat: string, wecom: string, weibo: string, wepay: string, xero: string, yahoo: string, yammer: string, yandex: string, zoom: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get version info like Casdoor release version and commit ID
#
# GET /api/get-version-info
# operationId: ApiController.GetVersionInfo
export def "get-version-info ApiControllerGetVersionInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<commitId: string, commitOffset: int, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/get-version-info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get webhook
#
# GET /api/get-webhook
# operationId: ApiController.GetWebhook
export def "get-webhook ApiControllerGetWebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the webhook (default: built-in/admin)
]: nothing -> record<contentType: string, createdTime: string, events: list<string>, headers: table<name: string, value: string>, isEnabled: bool, isUserExtended: bool, method: string, name: string, objectFields: list<string>, organization: string, owner: string, singleOrgOnly: bool, tokenFields: list<string>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-webhook" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /api/get-webhook-event
#
# operationId: ApiController.GetWebhookEventType
export def "get-webhook-event ApiControllerGetWebhookEventType" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ticket: string # The eventId of QRCode
]: nothing -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ticket" $ticket "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-webhook-event" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get webhooks
#
# GET /api/get-webhooks
# operationId: ApiController.GetWebhooks
export def "get-webhooks ApiControllerGetWebhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # The owner of webhooks (default: built-in/admin)
]: nothing -> table<contentType: string, createdTime: string, events: list<string>, headers: list<record>, isEnabled: bool, isUserExtended: bool, method: string, name: string, objectFields: list<string>, organization: string, owner: string, singleOrgOnly: bool, tokenFields: list<string>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/get-webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# check if the system is live
#
# GET /api/health
# operationId: ApiController.Health
export def "health ApiControllerHealth" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/health")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# set impersonation user for current admin session
#
# POST /api/impersonation-user
# operationId: ApiController.ImpersonateUser
export def "impersonation-user ApiControllerImpersonateUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  username: string # The username to impersonate (owner/name)
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/impersonation-user")
  let body = {username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# invoice payment
#
# POST /api/invoice-payment
# operationId: ApiController.InvoicePayment
export def "invoice-payment ApiControllerInvoicePayment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the payment
]: nothing -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/invoice-payment" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check if there are other different sessions for one user in one application.
#
# GET /api/is-session-duplicated
# operationId: ApiController.IsSessionDuplicated
export def "is-session-duplicated ApiControllerIsSessionDuplicated" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sessionPkId: string # The session ID in format: organization/user/application (e.g., built-in/admin/app-built-in)
  --sessionId: string # The specific session ID to check
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sessionPkId" $sessionPkId "scalar") (serialize-qp "sessionId" $sessionId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/is-session-duplicated" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# login
#
# POST /api/login
# operationId: ApiController.Login
export def "login ApiControllerLogin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clientId: string # clientId
  --responseType: string # responseType
  --redirectUri: string # redirectUri
  --scope: string # scope
  --state: string # state
  --nonce: string # nonce
  --code-challenge-method: string # code_challenge_method
  --code-challenge: string # code_challenge
  --body: record
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientId" $clientId "scalar") (serialize-qp "responseType" $responseType "scalar") (serialize-qp "redirectUri" $redirectUri "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "nonce" $nonce "scalar") (serialize-qp "code_challenge_method" $code_challenge_method "scalar") (serialize-qp "code_challenge" $code_challenge "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/login" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# get OAuth access token
#
# POST /api/login/oauth/access_token
# operationId: ApiController.GetOAuthToken
export def "login-oauth-access-token ApiControllerGetOAuthToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --grant-type: string # OAuth grant type
  --client-id: string # OAuth client id
  --client-secret: string # OAuth client secret
  --code: string # OAuth code
]: nothing -> record<access_token: string, expires_in: int, id_token: string, refresh_token: string, scope: string, token_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "grant_type" $grant_type "scalar") (serialize-qp "client_id" $client_id "scalar") (serialize-qp "client_secret" $client_secret "scalar") (serialize-qp "code" $code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/login/oauth/access_token" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# The introspection endpoint is an OAuth 2.0 endpoint that takes a
#
# POST /api/login/oauth/introspect
# operationId: ApiController.IntrospectToken
export def "login-oauth-introspect ApiControllerIntrospectToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string # access_token's value or refresh_token's value
  token_type_hint: string # the token type access_token or refresh_token
]: any -> record<active: bool, aud: list<string>, client_id: string, exp: int, iat: int, iss: string, jti: string, nbf: int, scope: string, sub: string, token_type: string, username: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/login/oauth/introspect")
  let body = {token: $body_token, token_type_hint: $token_type_hint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# refresh OAuth access token
#
# POST /api/login/oauth/refresh_token
# operationId: ApiController.RefreshToken
export def "login-oauth-refresh-token ApiControllerRefreshToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --grant-type: string # OAuth grant type
  --refresh-token: string # OAuth refresh token
  --scope: string # OAuth scope
  --client-id: string # OAuth client id
  --client-secret: string # OAuth client secret
]: nothing -> record<access_token: string, expires_in: int, id_token: string, refresh_token: string, scope: string, token_type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "grant_type" $grant_type "scalar") (serialize-qp "refresh_token" $refresh_token "scalar") (serialize-qp "scope" $scope "scalar") (serialize-qp "client_id" $client_id "scalar") (serialize-qp "client_secret" $client_secret "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/login/oauth/refresh_token" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# logout the current user
#
# POST /api/logout
# operationId: ApiController.Logout
export def "logout ApiControllerLogout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id-token-hint: string # id_token_hint
  --post-logout-redirect-uri: string # post_logout_redirect_uri
  --state: string # state
]: nothing -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id_token_hint" $id_token_hint "scalar") (serialize-qp "post_logout_redirect_uri" $post_logout_redirect_uri "scalar") (serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/logout" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# get Prometheus metrics
#
# GET /api/metrics
# operationId: ApiController.GetMetrics
export def "metrics ApiControllerGetMetrics" [
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
  let full_url = (build-url $base "/api/metrics")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# enable totp
#
# POST /api/mfa/setup/enable
# operationId: ApiController.MfaSetupEnable
export def "mfa-setup-enable ApiControllerMfaSetupEnable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/mfa/setup/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# setup MFA
#
# POST /api/mfa/setup/initiate
# operationId: ApiController.MfaSetupInitiate
export def "mfa-setup-initiate ApiControllerMfaSetupInitiate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/mfa/setup/initiate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# setup verify totp
#
# POST /api/mfa/setup/verify
# operationId: ApiController.MfaSetupVerify
export def "mfa-setup-verify ApiControllerMfaSetupVerify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/mfa/setup/verify")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# notify payment
#
# POST /api/notify-payment
# operationId: ApiController.NotifyPayment
# --orderObj shape: {createdTime?: string, currency?: string, displayName?: string, message?: string, name?: string, owner?: string, payment?: string, price?: float, productInfos?: list, products?: list, state?: string, updateTime?: string, user?: string}
export def "notify-payment ApiControllerNotifyPayment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createdTime: string
  --currency: string
  --detail: string
  --displayName: string
  --invoiceRemark: string
  --invoiceTaxId: string
  --invoiceTitle: string
  --invoiceType: string
  --invoiceUrl: string
  --message: string
  --name: string
  --order: string
  --orderObj: record # shape: {createdTime?: string, currency?: string, displayName?: string, message?: string, name?: string, owner?: string, payment?: string, price?: float, productInfos?: list, products?: list, state?: string, updateTime?: string, user?: string}
  --outOrderId: string
  --owner: string
  --payUrl: string
  --personEmail: string
  --personIdCard: string
  --personName: string
  --personPhone: string
  --price: float # format: double
  --products: list
  --productsDisplayName: string
  --provider: string
  --state: string@state-completer # e.g. Paid
  --successUrl: string
  --type: string
  --user: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/notify-payment")
  let body = {createdTime: $createdTime, currency: $currency, detail: $detail, displayName: $displayName, invoiceRemark: $invoiceRemark, invoiceTaxId: $invoiceTaxId, invoiceTitle: $invoiceTitle, invoiceType: $invoiceType, invoiceUrl: $invoiceUrl, message: $message, name: $name, order: $order, orderObj: $orderObj, outOrderId: $outOrderId, owner: $owner, payUrl: $payUrl, personEmail: $personEmail, personIdCard: $personIdCard, personName: $personName, personPhone: $personPhone, price: $price, products: $products, productsDisplayName: $productsDisplayName, provider: $provider, state: $state, successUrl: $successUrl, type: $type, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# pay an existing order
#
# POST /api/pay-order
# operationId: ApiController.PayOrder
export def "pay-order ApiControllerPayOrder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the order
  --providerName: string # The name of the provider
]: nothing -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "providerName" $providerName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/pay-order" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# place an order for a product
#
# POST /api/place-order
# operationId: ApiController.PlaceOrder
export def "place-order ApiControllerPlaceOrder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --productId: string # The id ( owner/name ) of the product
  --pricingName: string # The name of the pricing (for subscription)
  --planName: string # The name of the plan (for subscription)
  --customPrice: float # Custom price for recharge products
  --userName: string # The username to place order for (admin only)
]: nothing -> record<createdTime: string, currency: string, displayName: string, message: string, name: string, owner: string, payment: string, price: float, productInfos: table<currency: string, detail: string, displayName: string, image: string, isRecharge: bool, name: string, owner: string, planName: string, price: float, pricingName: string, quantity: int>, products: list<string>, state: string, updateTime: string, user: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "productId" $productId "scalar") (serialize-qp "pricingName" $pricingName "scalar") (serialize-qp "planName" $planName "scalar") (serialize-qp "customPrice" $customPrice "scalar") (serialize-qp "userName" $userName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/place-order" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Refresh all CLI engines
#
# POST /api/refresh-engines
# operationId: ApiController.RefreshEngines
export def "refresh-engines ApiControllerRefreshEngines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --m: string # Hash for request validation
  --t: string # Timestamp for request validation
]: nothing -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "m" $m "scalar") (serialize-qp "t" $t "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/refresh-engines" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# remove policy
#
# POST /api/remove-policy
# operationId: ApiController.RemovePolicy
export def "remove-policy ApiControllerRemovePolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name )  of enforcer
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/remove-policy" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /api/reset-email-or-phone
#
# operationId: ApiController.ResetEmailOrPhone
export def "reset-email-or-phone ApiControllerResetEmailOrPhone" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<address: string, aud: string, email: string, email_verified: bool, groups: list<string>, is_verified: bool, iss: string, name: string, permissions: list<string>, phone: string, picture: string, preferred_username: string, real_name: string, roles: list<string>, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/reset-email-or-phone")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Call Casbin CLI commands
#
# GET /api/run-casbin-command
# operationId: ApiController.RunCasbinCommand
export def "run-casbin-command ApiControllerRunCasbinCommand" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/run-casbin-command")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# run syncer
#
# GET /api/run-syncer
# operationId: ApiController.RunSyncer
# --tableColumns item shape: {casdoorName?: string, isHashed?: bool, isKey?: bool, name?: string, type?: string, values?: list}
export def "run-syncer ApiControllerRunSyncer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --affiliationTable: string
  --avatarBaseUrl: string
  --cert: string
  --createdTime: string
  --database: string
  --databaseType: string
  --errorText: string
  --host: string
  --isEnabled: oneof<nothing, bool>
  --isReadOnly: oneof<nothing, bool>
  --name: string
  --organization: string
  --owner: string
  --password: string
  --port: int # format: int64
  --sshHost: string
  --sshPassword: string
  --sshPort: int # format: int64
  --sshType: string
  --sshUser: string
  --sslMode: string
  --syncInterval: int # format: int64
  --table: string
  --tableColumns: list # item shape: {casdoorName?: string, isHashed?: bool, isKey?: bool, name?: string, type?: string, values?: list}
  --type: string
  --user: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/run-syncer")
  let body = {affiliationTable: $affiliationTable, avatarBaseUrl: $avatarBaseUrl, cert: $cert, createdTime: $createdTime, database: $database, databaseType: $databaseType, errorText: $errorText, host: $host, isEnabled: $isEnabled, isReadOnly: $isReadOnly, name: $name, organization: $organization, owner: $owner, password: $password, port: $port, sshHost: $sshHost, sshPassword: $sshPassword, sshPort: $sshPort, sshType: $sshType, sshUser: $sshUser, sslMode: $sslMode, syncInterval: $syncInterval, table: $table, tableColumns: $tableColumns, type: $type, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# This API is not for Casdoor frontend to call, it is for Casdoor SDKs.
#
# POST /api/send-email
# operationId: ApiController.SendEmail
# --providerObject shape: {appId?: string, bucket?: string, category?: string, cert?: string, clientId?: string, clientId2?: string, clientSecret?: string, clientSecret2?: string, content?: string, createdTime?: string, customAuthUrl?: string, customLogo?: string, customTokenUrl?: string, customUserInfoUrl?: string, disableSsl?: bool, displayName?: string, domain?: string, emailRegex?: string, enablePkce?: bool, enableProxy?: bool, enableSignAuthnRequest?: bool, endpoint?: string, host?: string, httpHeaders?: any, idP?: string, intranetEndpoint?: string, issuerUrl?: string, metadata?: string, method?: string, name?: string, owner?: string, pathPrefix?: string, port?: int, providerUrl?: string, receiver?: string, regionId?: string, scopes?: string, signName?: string, subType?: string, templateCode?: string, title?: string, type?: string, userMapping?: any}
export def "send-email ApiControllerSendEmail" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clientId: string # The clientId of the application
  --clientSecret: string # The clientSecret of the application
  --content: string
  --provider: string
  --providerObject: record # shape: {appId?: string, bucket?: string, category?: string, cert?: string, clientId?: string, clientId2?: string, clientSecret?: string, clientSecret2?: string, content?: string, createdTime?: string, customAuthUrl?: string, customLogo?: string, customTokenUrl?: string, customUserInfoUrl?: string, disableSsl?: bool, displayName?: string, domain?: string, emailRegex?: string, enablePkce?: bool, enableProxy?: bool, enableSignAuthnRequest?: bool, endpoint?: string, host?: string, httpHeaders?: any, idP?: string, intranetEndpoint?: string, issuerUrl?: string, metadata?: string, method?: string, name?: string, owner?: string, pathPrefix?: string, port?: int, providerUrl?: string, receiver?: string, regionId?: string, scopes?: string, signName?: string, subType?: string, templateCode?: string, title?: string, type?: string, userMapping?: any}
  --receivers: list
  --sender: string
  --title: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientId" $clientId "scalar") (serialize-qp "clientSecret" $clientSecret "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/send-email" $qp)
  let body = {content: $content, provider: $provider, providerObject: $providerObject, receivers: $receivers, sender: $sender, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# verify invitation
#
# POST /api/send-invitation
# operationId: ApiController.VerifyInvitation
export def "send-invitation ApiControllerVerifyInvitation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the invitation
  --body: record
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/send-invitation" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# This API is not for Casdoor frontend to call, it is for Casdoor SDKs.
#
# POST /api/send-notification
# operationId: ApiController.SendNotification
export def "send-notification ApiControllerSendNotification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --content: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/send-notification")
  let body = {content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# This API is not for Casdoor frontend to call, it is for Casdoor SDKs.
#
# POST /api/send-sms
# operationId: ApiController.SendSms
export def "send-sms ApiControllerSendSms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --clientId: string # The clientId of the application
  --clientSecret: string # The clientSecret of the application
  --content: string
  --organizationId: string
  --receivers: list
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "clientId" $clientId "scalar") (serialize-qp "clientSecret" $clientSecret "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/send-sms" $qp)
  let body = {content: $content, organizationId: $organizationId, receivers: $receivers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /api/send-verification-code
#
# operationId: ApiController.SendVerificationCode
export def "send-verification-code ApiControllerSendVerificationCode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<address: string, aud: string, email: string, email_verified: bool, groups: list<string>, is_verified: bool, iss: string, name: string, permissions: list<string>, phone: string, picture: string, preferred_username: string, real_name: string, roles: list<string>, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/send-verification-code")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# set password
#
# POST /api/set-password
# operationId: ApiController.SetPassword
export def "set-password ApiControllerSetPassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  userOwner: string # The owner of the user
  userName: string # The name of the user
  oldPassword: string # The old password of the user
  newPassword: string # The new password of the user
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/set-password")
  let body = {userOwner: $userOwner, userName: $userName, oldPassword: $oldPassword, newPassword: $newPassword} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# : Set specific Mfa Preferred
#
# POST /api/set-preferred-mfa
# operationId: ApiController.SetPreferredMfa
export def "set-preferred-mfa ApiControllerSetPreferredMfa" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/set-preferred-mfa")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# sign up a new user
#
# POST /api/signup
# operationId: ApiController.Signup
export def "signup ApiControllerSignup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  username: string # The username to sign up
  password: string # The password
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/signup")
  let body = {username: $username, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# logout the current user from all applications or current session only
#
# GET /api/sso-logout
# operationId: ApiController.SsoLogout
export def "sso-logout ApiControllerSsoLogout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --logoutAll: string # Whether to logout from all sessions. Accepted values: 'true', '1', or empty (default: true). Any other value means false.
]: nothing -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "logoutAll" $logoutAll "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/sso-logout" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# logout the current user from all applications or current session only
#
# POST /api/sso-logout
# operationId: ApiController.SsoLogout
export def "sso-logout ApiControllerSsoLogout-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --logoutAll: string # Whether to logout from all sessions. Accepted values: 'true', '1', or empty (default: true). Any other value means false.
]: nothing -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "logoutAll" $logoutAll "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/sso-logout" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# sync ldap users
#
# POST /api/sync-ldap-users
# operationId: ApiController.SyncLdapUsers
export def "sync-ldap-users ApiControllerSyncLdapUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # id
]: nothing -> record<exist: table<EmailAddress: string, Mail: string, MobileTelephoneNumber: string, PostalAddress: string, RegisteredAddress: string, TelephoneNumber: string, address: string, attributes: any, cn: string, country: string, countryName: string, displayName: string, email: string, gidNumber: string, groupId: string, memberOf: string, mobile: string, uid: string, uidNumber: string, userPrincipalName: string, uuid: string>, failed: table<EmailAddress: string, Mail: string, MobileTelephoneNumber: string, PostalAddress: string, RegisteredAddress: string, TelephoneNumber: string, address: string, attributes: any, cn: string, country: string, countryName: string, displayName: string, email: string, gidNumber: string, groupId: string, memberOf: string, mobile: string, uid: string, uidNumber: string, userPrincipalName: string, uuid: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/sync-ldap-users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/unlink
#
# operationId: ApiController.Unlink
export def "unlink ApiControllerUnlink" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<address: string, aud: string, email: string, email_verified: bool, groups: list<string>, is_verified: bool, iss: string, name: string, permissions: list<string>, phone: string, picture: string, preferred_username: string, real_name: string, roles: list<string>, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/unlink")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# update adapter
#
# POST /api/update-adapter
# operationId: ApiController.UpdateAdapter
export def "update-adapter ApiControllerUpdateAdapter" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the adapter
  --createdTime: string
  --database: string
  --databaseType: string
  --host: string
  --name: string
  --owner: string
  --password: string
  --port: int # format: int64
  --table: string
  --type: string
  --useSameDb: oneof<nothing, bool>
  --user: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/update-adapter" $qp)
  let body = {createdTime: $createdTime, database: $database, databaseType: $databaseType, host: $host, name: $name, owner: $owner, password: $password, port: $port, table: $table, type: $type, useSameDb: $useSameDb, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# update an application
#
# POST /api/update-application
# operationId: ApiController.UpdateApplication
# --organizationObj shape: {accountItems?: list, accountMenu?: string, balanceCredit?: float, balanceCurrency?: string, countryCodes?: list, createdTime?: string, defaultApplication?: string, defaultAvatar?: string, defaultPassword?: string, disableSignin?: bool, displayName?: string, enableSoftDeletion?: bool, enableTour?: bool, favicon?: string, hasPrivilegeConsent?: bool, initScore?: int, ipRestriction?: string, ipWhitelist?: string, isProfilePublic?: bool, languages?: list, logo?: string, logoDark?: string, masterPassword?: string, masterVerificationCode?: string, mfaItems?: list, mfaRememberInHours?: int, name?: string, navItems?: list, orgBalance?: float, owner?: string, passwordExpireDays?: int, passwordObfuscatorKey?: string, passwordObfuscatorType?: string, passwordOptions?: list, passwordSalt?: string, passwordType?: string, tags?: list, themeData?: record, useEmailAsUsername?: bool, userBalance?: float, userNavItems?: list, userTypes?: list, websiteUrl?: string, widgetItems?: list}
# --providers item shape: {canSignIn?: bool, canSignUp?: bool, canUnlink?: bool, countryCodes?: list, name?: string, owner?: string, prompted?: bool, provider?: record, rule?: string, signupGroup?: string}
# --samlAttributes item shape: {name?: string, nameFormat?: string, value?: string}
# --signinItems item shape: {customCss?: string, isCustom?: bool, label?: string, name?: string, placeholder?: string, rule?: string, visible?: bool}
# --signinMethods item shape: {displayName?: string, name?: string, rule?: string}
# --signupItems item shape: {customCss?: string, label?: string, name?: string, options?: list, placeholder?: string, prompted?: bool, regex?: string, required?: bool, rule?: string, type?: string, visible?: bool}
# --themeData shape: {borderRadius?: int, colorPrimary?: string, isCompact?: bool, isEnabled?: bool, themeType?: string}
# --tokenAttributes item shape: {name?: string, type?: string, value?: string}
export def "update-application ApiControllerUpdateApplication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the application
  --affiliationUrl: string
  --cert: string
  --certPublicKey: string
  --clientId: string
  --clientSecret: string
  --codeResendTimeout: int # format: int64
  --cookieExpireInHours: int # format: int64
  --createdTime: string
  --defaultGroup: string
  --description: string
  --disableSamlAttributes: oneof<nothing, bool>
  --disableSignin: oneof<nothing, bool>
  --displayName: string
  --enableAutoSignin: oneof<nothing, bool>
  --enableCodeSignin: oneof<nothing, bool>
  --enableExclusiveSignin: oneof<nothing, bool>
  --enableLinkWithEmail: oneof<nothing, bool>
  --enablePassword: oneof<nothing, bool>
  --enableSamlAssertionSignature: oneof<nothing, bool>
  --enableSamlC14n10: oneof<nothing, bool>
  --enableSamlCompress: oneof<nothing, bool>
  --enableSamlPostBinding: oneof<nothing, bool>
  --enableSignUp: oneof<nothing, bool>
  --enableSigninSession: oneof<nothing, bool>
  --enableWebAuthn: oneof<nothing, bool>
  --expireInHours: float # format: double
  --failedSigninFrozenTime: int # format: int64
  --failedSigninLimit: int # format: int64
  --favicon: string
  --footerHtml: string
  --forcedRedirectOrigin: string
  --forgetUrl: string
  --formBackgroundUrl: string
  --formBackgroundUrlMobile: string
  --formCss: string
  --formCssMobile: string
  --formOffset: int # format: int64
  --formSideHtml: string
  --grantTypes: list
  --headerHtml: string
  --homepageUrl: string
  --ipRestriction: string
  --ipWhitelist: string
  --isShared: oneof<nothing, bool>
  --logo: string
  --name: string
  --order: int # format: int64
  --orgChoiceMode: string
  --organization: string
  --organizationObj: record # shape: {accountItems?: list, accountMenu?: string, balanceCredit?: float, balanceCurrency?: string, countryCodes?: list, createdTime?: string, defaultApplication?: string, defaultAvatar?: string, defaultPassword?: string, disableSignin?: bool, displayName?: string, enableSoftDeletion?: bool, enableTour?: bool, favicon?: string, hasPrivilegeConsent?: bool, initScore?: int, ipRestriction?: string, ipWhitelist?: string, isProfilePublic?: bool, languages?: list, logo?: string, logoDark?: string, masterPassword?: string, masterVerificationCode?: string, mfaItems?: list, mfaRememberInHours?: int, name?: string, navItems?: list, orgBalance?: float, owner?: string, passwordExpireDays?: int, passwordObfuscatorKey?: string, passwordObfuscatorType?: string, passwordOptions?: list, passwordSalt?: string, passwordType?: string, tags?: list, themeData?: record, useEmailAsUsername?: bool, userBalance?: float, userNavItems?: list, userTypes?: list, websiteUrl?: string, widgetItems?: list}
  --owner: string
  --providers: list # item shape: {canSignIn?: bool, canSignUp?: bool, canUnlink?: bool, countryCodes?: list, name?: string, owner?: string, prompted?: bool, provider?: record, rule?: string, signupGroup?: string}
  --redirectUris: list
  --refreshExpireInHours: float # format: double
  --samlAttributes: list # item shape: {name?: string, nameFormat?: string, value?: string}
  --samlHashAlgorithm: string
  --samlReplyUrl: string
  --signinHtml: string
  --signinItems: list # item shape: {customCss?: string, isCustom?: bool, label?: string, name?: string, placeholder?: string, rule?: string, visible?: bool}
  --signinMethods: list # item shape: {displayName?: string, name?: string, rule?: string}
  --signinUrl: string
  --signupHtml: string
  --signupItems: list # item shape: {customCss?: string, label?: string, name?: string, options?: list, placeholder?: string, prompted?: bool, regex?: string, required?: bool, rule?: string, type?: string, visible?: bool}
  --signupUrl: string
  --tags: list
  --termsOfUse: string
  --themeData: record # shape: {borderRadius?: int, colorPrimary?: string, isCompact?: bool, isEnabled?: bool, themeType?: string}
  --title: string
  --tokenAttributes: list # item shape: {name?: string, type?: string, value?: string}
  --tokenFields: list
  --tokenFormat: string
  --tokenSigningMethod: string
  --useEmailAsSamlNameId: oneof<nothing, bool>
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/update-application" $qp)
  let body = {affiliationUrl: $affiliationUrl, cert: $cert, certPublicKey: $certPublicKey, clientId: $clientId, clientSecret: $clientSecret, codeResendTimeout: $codeResendTimeout, cookieExpireInHours: $cookieExpireInHours, createdTime: $createdTime, defaultGroup: $defaultGroup, description: $description, disableSamlAttributes: $disableSamlAttributes, disableSignin: $disableSignin, displayName: $displayName, enableAutoSignin: $enableAutoSignin, enableCodeSignin: $enableCodeSignin, enableExclusiveSignin: $enableExclusiveSignin, enableLinkWithEmail: $enableLinkWithEmail, enablePassword: $enablePassword, enableSamlAssertionSignature: $enableSamlAssertionSignature, enableSamlC14n10: $enableSamlC14n10, enableSamlCompress: $enableSamlCompress, enableSamlPostBinding: $enableSamlPostBinding, enableSignUp: $enableSignUp, enableSigninSession: $enableSigninSession, enableWebAuthn: $enableWebAuthn, expireInHours: $expireInHours, failedSigninFrozenTime: $failedSigninFrozenTime, failedSigninLimit: $failedSigninLimit, favicon: $favicon, footerHtml: $footerHtml, forcedRedirectOrigin: $forcedRedirectOrigin, forgetUrl: $forgetUrl, formBackgroundUrl: $formBackgroundUrl, formBackgroundUrlMobile: $formBackgroundUrlMobile, formCss: $formCss, formCssMobile: $formCssMobile, formOffset: $formOffset, formSideHtml: $formSideHtml, grantTypes: $grantTypes, headerHtml: $headerHtml, homepageUrl: $homepageUrl, ipRestriction: $ipRestriction, ipWhitelist: $ipWhitelist, isShared: $isShared, logo: $logo, name: $name, order: $order, orgChoiceMode: $orgChoiceMode, organization: $organization, organizationObj: $organizationObj, owner: $owner, providers: $providers, redirectUris: $redirectUris, refreshExpireInHours: $refreshExpireInHours, samlAttributes: $samlAttributes, samlHashAlgorithm: $samlHashAlgorithm, samlReplyUrl: $samlReplyUrl, signinHtml: $signinHtml, signinItems: $signinItems, signinMethods: $signinMethods, signinUrl: $signinUrl, signupHtml: $signupHtml, signupItems: $signupItems, signupUrl: $signupUrl, tags: $tags, termsOfUse: $termsOfUse, themeData: $themeData, title: $title, tokenAttributes: $tokenAttributes, tokenFields: $tokenFields, tokenFormat: $tokenFormat, tokenSigningMethod: $tokenSigningMethod, useEmailAsSamlNameId: $useEmailAsSamlNameId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# update cert
#
# POST /api/update-cert
# operationId: ApiController.UpdateCert
export def "update-cert ApiControllerUpdateCert" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the cert
  --bitSize: int # format: int64
  --certificate: string
  --createdTime: string
  --cryptoAlgorithm: string
  --displayName: string
  --expireInYears: int # format: int64
  --name: string
  --owner: string
  --privateKey: string
  --scope: string
  --type: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/update-cert" $qp)
  let body = {bitSize: $bitSize, certificate: $certificate, createdTime: $createdTime, cryptoAlgorithm: $cryptoAlgorithm, displayName: $displayName, expireInYears: $expireInYears, name: $name, owner: $owner, privateKey: $privateKey, scope: $scope, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# update enforcer
#
# POST /api/update-enforcer
# operationId: ApiController.UpdateEnforcer
export def "update-enforcer ApiControllerUpdateEnforcer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name )  of enforcer
  --body: record
]: any -> record<adapter: string, createdTime: string, description: string, displayName: string, model: string, modelCfg: any, name: string, owner: string, updatedTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/update-enforcer" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# update form
#
# POST /api/update-form
# operationId: ApiController.UpdateForm
# --formItems item shape: {label?: string, name?: string, visible?: bool, width?: string}
export def "update-form ApiControllerUpdateForm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id (owner/name) of the form
  --createdTime: string
  --displayName: string
  --formItems: list # item shape: {label?: string, name?: string, visible?: bool, width?: string}
  --name: string
  --owner: string
  --tag: string
  --type: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/update-form" $qp)
  let body = {createdTime: $createdTime, displayName: $displayName, formItems: $formItems, name: $name, owner: $owner, tag: $tag, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# update group
#
# POST /api/update-group
# operationId: ApiController.UpdateGroup
# --children item shape: {children?: list, contactEmail?: string, createdTime?: string, displayName?: string, haveChildren?: bool, isEnabled?: bool, isTopGroup?: bool, key?: string, manager?: string, name?: string, owner?: string, parentId?: string, parentName?: string, title?: string, type?: string, updatedTime?: string, users?: list}
export def "update-group ApiControllerUpdateGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the group
  --children: list # item shape: {children?: list, contactEmail?: string, createdTime?: string, displayName?: string, haveChildren?: bool, isEnabled?: bool, isTopGroup?: bool, key?: string, manager?: string, name?: string, owner?: string, parentId?: string, parentName?: string, title?: string, type?: string, updatedTime?: string, users?: list}
  --contactEmail: string
  --createdTime: string
  --displayName: string
  --haveChildren: oneof<nothing, bool>
  --isEnabled: oneof<nothing, bool>
  --isTopGroup: oneof<nothing, bool>
  --key: string
  --manager: string
  --name: string
  --owner: string
  --parentId: string
  --parentName: string
  --title: string
  --type: string
  --updatedTime: string
  --users: list
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/update-group" $qp)
  let body = {children: $children, contactEmail: $contactEmail, createdTime: $createdTime, displayName: $displayName, haveChildren: $haveChildren, isEnabled: $isEnabled, isTopGroup: $isTopGroup, key: $key, manager: $manager, name: $name, owner: $owner, parentId: $parentId, parentName: $parentName, title: $title, type: $type, updatedTime: $updatedTime, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# update invitation
#
# POST /api/update-invitation
# operationId: ApiController.UpdateInvitation
export def "update-invitation ApiControllerUpdateInvitation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the invitation
  --application: string
  --code: string
  --createdTime: string
  --defaultCode: string
  --displayName: string
  --email: string
  --isRegexp: oneof<nothing, bool>
  --name: string
  --owner: string
  --phone: string
  --quota: int # format: int64
  --signupGroup: string
  --state: string
  --updatedTime: string
  --usedCount: int # format: int64
  --username: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/update-invitation" $qp)
  let body = {application: $application, code: $code, createdTime: $createdTime, defaultCode: $defaultCode, displayName: $displayName, email: $email, isRegexp: $isRegexp, name: $name, owner: $owner, phone: $phone, quota: $quota, signupGroup: $signupGroup, state: $state, updatedTime: $updatedTime, usedCount: $usedCount, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# update ldap
#
# POST /api/update-ldap
# operationId: ApiController.UpdateLdap
export def "update-ldap ApiControllerUpdateLdap" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --allowSelfSignedCert: oneof<nothing, bool>
  --autoSync: int # format: int64
  --baseDn: string
  --createdTime: string
  --customAttributes: any
  --defaultGroup: string
  --enableSsl: oneof<nothing, bool>
  --filter: string
  --filterFields: list
  --host: string
  --id: string
  --lastSync: string
  --owner: string
  --password: string
  --passwordType: string
  --port: int # format: int64
  --serverName: string
  --username: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/update-ldap")
  let body = {allowSelfSignedCert: $allowSelfSignedCert, autoSync: $autoSync, baseDn: $baseDn, createdTime: $createdTime, customAttributes: $customAttributes, defaultGroup: $defaultGroup, enableSsl: $enableSsl, filter: $filter, filterFields: $filterFields, host: $host, id: $id, lastSync: $lastSync, owner: $owner, password: $password, passwordType: $passwordType, port: $port, serverName: $serverName, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# update model
#
# POST /api/update-model
# operationId: ApiController.UpdateModel
export def "update-model ApiControllerUpdateModel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the model
  --createdTime: string
  --description: string
  --displayName: string
  --modelText: string
  --name: string
  --owner: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/update-model" $qp)
  let body = {createdTime: $createdTime, description: $description, displayName: $displayName, modelText: $modelText, name: $name, owner: $owner} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# update order
#
# POST /api/update-order
# operationId: ApiController.UpdateOrder
# --productInfos item shape: {currency?: string, detail?: string, displayName?: string, image?: string, isRecharge?: bool, name?: string, owner?: string, planName?: string, price?: float, pricingName?: string, quantity?: int}
export def "update-order ApiControllerUpdateOrder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the order
  --createdTime: string
  --currency: string
  --displayName: string
  --message: string
  --name: string
  --owner: string
  --payment: string
  --price: float # format: double
  --productInfos: list # item shape: {currency?: string, detail?: string, displayName?: string, image?: string, isRecharge?: bool, name?: string, owner?: string, planName?: string, price?: float, pricingName?: string, quantity?: int}
  --products: list
  --state: string
  --updateTime: string
  --user: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/update-order" $qp)
  let body = {createdTime: $createdTime, currency: $currency, displayName: $displayName, message: $message, name: $name, owner: $owner, payment: $payment, price: $price, productInfos: $productInfos, products: $products, state: $state, updateTime: $updateTime, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# update organization
#
# POST /api/update-organization
# operationId: ApiController.UpdateOrganization
# --accountItems item shape: {modifyRule?: string, name?: string, regex?: string, tab?: string, viewRule?: string, visible?: bool}
# --mfaItems item shape: {name?: string, rule?: string}
# --themeData shape: {borderRadius?: int, colorPrimary?: string, isCompact?: bool, isEnabled?: bool, themeType?: string}
export def "update-organization ApiControllerUpdateOrganization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the organization
  --accountItems: list # item shape: {modifyRule?: string, name?: string, regex?: string, tab?: string, viewRule?: string, visible?: bool}
  --accountMenu: string
  --balanceCredit: float # format: double
  --balanceCurrency: string
  --countryCodes: list
  --createdTime: string
  --defaultApplication: string
  --defaultAvatar: string
  --defaultPassword: string
  --disableSignin: oneof<nothing, bool>
  --displayName: string
  --enableSoftDeletion: oneof<nothing, bool>
  --enableTour: oneof<nothing, bool>
  --favicon: string
  --hasPrivilegeConsent: oneof<nothing, bool>
  --initScore: int # format: int64
  --ipRestriction: string
  --ipWhitelist: string
  --isProfilePublic: oneof<nothing, bool>
  --languages: list
  --logo: string
  --logoDark: string
  --masterPassword: string
  --masterVerificationCode: string
  --mfaItems: list # item shape: {name?: string, rule?: string}
  --mfaRememberInHours: int # format: int64
  --name: string
  --navItems: list
  --orgBalance: float # format: double
  --owner: string
  --passwordExpireDays: int # format: int64
  --passwordObfuscatorKey: string
  --passwordObfuscatorType: string
  --passwordOptions: list
  --passwordSalt: string
  --passwordType: string
  --tags: list
  --themeData: record # shape: {borderRadius?: int, colorPrimary?: string, isCompact?: bool, isEnabled?: bool, themeType?: string}
  --useEmailAsUsername: oneof<nothing, bool>
  --userBalance: float # format: double
  --userNavItems: list
  --userTypes: list
  --websiteUrl: string
  --widgetItems: list
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/update-organization" $qp)
  let body = {accountItems: $accountItems, accountMenu: $accountMenu, balanceCredit: $balanceCredit, balanceCurrency: $balanceCurrency, countryCodes: $countryCodes, createdTime: $createdTime, defaultApplication: $defaultApplication, defaultAvatar: $defaultAvatar, defaultPassword: $defaultPassword, disableSignin: $disableSignin, displayName: $displayName, enableSoftDeletion: $enableSoftDeletion, enableTour: $enableTour, favicon: $favicon, hasPrivilegeConsent: $hasPrivilegeConsent, initScore: $initScore, ipRestriction: $ipRestriction, ipWhitelist: $ipWhitelist, isProfilePublic: $isProfilePublic, languages: $languages, logo: $logo, logoDark: $logoDark, masterPassword: $masterPassword, masterVerificationCode: $masterVerificationCode, mfaItems: $mfaItems, mfaRememberInHours: $mfaRememberInHours, name: $name, navItems: $navItems, orgBalance: $orgBalance, owner: $owner, passwordExpireDays: $passwordExpireDays, passwordObfuscatorKey: $passwordObfuscatorKey, passwordObfuscatorType: $passwordObfuscatorType, passwordOptions: $passwordOptions, passwordSalt: $passwordSalt, passwordType: $passwordType, tags: $tags, themeData: $themeData, useEmailAsUsername: $useEmailAsUsername, userBalance: $userBalance, userNavItems: $userNavItems, userTypes: $userTypes, websiteUrl: $websiteUrl, widgetItems: $widgetItems} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# update payment
#
# POST /api/update-payment
# operationId: ApiController.UpdatePayment
# --orderObj shape: {createdTime?: string, currency?: string, displayName?: string, message?: string, name?: string, owner?: string, payment?: string, price?: float, productInfos?: list, products?: list, state?: string, updateTime?: string, user?: string}
export def "update-payment ApiControllerUpdatePayment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the payment
  --createdTime: string
  --currency: string
  --detail: string
  --displayName: string
  --invoiceRemark: string
  --invoiceTaxId: string
  --invoiceTitle: string
  --invoiceType: string
  --invoiceUrl: string
  --message: string
  --name: string
  --order: string
  --orderObj: record # shape: {createdTime?: string, currency?: string, displayName?: string, message?: string, name?: string, owner?: string, payment?: string, price?: float, productInfos?: list, products?: list, state?: string, updateTime?: string, user?: string}
  --outOrderId: string
  --owner: string
  --payUrl: string
  --personEmail: string
  --personIdCard: string
  --personName: string
  --personPhone: string
  --price: float # format: double
  --products: list
  --productsDisplayName: string
  --provider: string
  --state: string@state-completer # e.g. Paid
  --successUrl: string
  --type: string
  --user: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/update-payment" $qp)
  let body = {createdTime: $createdTime, currency: $currency, detail: $detail, displayName: $displayName, invoiceRemark: $invoiceRemark, invoiceTaxId: $invoiceTaxId, invoiceTitle: $invoiceTitle, invoiceType: $invoiceType, invoiceUrl: $invoiceUrl, message: $message, name: $name, order: $order, orderObj: $orderObj, outOrderId: $outOrderId, owner: $owner, payUrl: $payUrl, personEmail: $personEmail, personIdCard: $personIdCard, personName: $personName, personPhone: $personPhone, price: $price, products: $products, productsDisplayName: $productsDisplayName, provider: $provider, state: $state, successUrl: $successUrl, type: $type, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# update permission
#
# POST /api/update-permission
# operationId: ApiController.UpdatePermission
export def "update-permission ApiControllerUpdatePermission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the permission
  --actions: list
  --adapter: string
  --approveTime: string
  --approver: string
  --createdTime: string
  --description: string
  --displayName: string
  --domains: list
  --effect: string
  --groups: list
  --isEnabled: oneof<nothing, bool>
  --model: string
  --name: string
  --owner: string
  --resourceType: string
  --resources: list
  --roles: list
  --state: string
  --submitter: string
  --users: list
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/update-permission" $qp)
  let body = {actions: $actions, adapter: $adapter, approveTime: $approveTime, approver: $approver, createdTime: $createdTime, description: $description, displayName: $displayName, domains: $domains, effect: $effect, groups: $groups, isEnabled: $isEnabled, model: $model, name: $name, owner: $owner, resourceType: $resourceType, resources: $resources, roles: $roles, state: $state, submitter: $submitter, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# update plan
#
# POST /api/update-plan
# operationId: ApiController.UpdatePlan
export def "update-plan ApiControllerUpdatePlan" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the plan
  --createdTime: string
  --currency: string
  --description: string
  --displayName: string
  --isEnabled: oneof<nothing, bool>
  --name: string
  --options: list
  --owner: string
  --paymentProviders: list
  --period: string
  --price: float # format: double
  --product: string
  --role: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/update-plan" $qp)
  let body = {createdTime: $createdTime, currency: $currency, description: $description, displayName: $displayName, isEnabled: $isEnabled, name: $name, options: $options, owner: $owner, paymentProviders: $paymentProviders, period: $period, price: $price, product: $product, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# update policy
#
# POST /api/update-policy
# operationId: ApiController.UpdatePolicy
export def "update-policy ApiControllerUpdatePolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name )  of enforcer
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/update-policy" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# update pricing
#
# POST /api/update-pricing
# operationId: ApiController.UpdatePricing
export def "update-pricing ApiControllerUpdatePricing" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the pricing
  --application: string
  --createdTime: string
  --description: string
  --displayName: string
  --isEnabled: oneof<nothing, bool>
  --name: string
  --owner: string
  --plans: list
  --trialDuration: int # format: int64
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/update-pricing" $qp)
  let body = {application: $application, createdTime: $createdTime, description: $description, displayName: $displayName, isEnabled: $isEnabled, name: $name, owner: $owner, plans: $plans, trialDuration: $trialDuration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# update product
#
# POST /api/update-product
# operationId: ApiController.UpdateProduct
# --providerObjs item shape: {appId?: string, bucket?: string, category?: string, cert?: string, clientId?: string, clientId2?: string, clientSecret?: string, clientSecret2?: string, content?: string, createdTime?: string, customAuthUrl?: string, customLogo?: string, customTokenUrl?: string, customUserInfoUrl?: string, disableSsl?: bool, displayName?: string, domain?: string, emailRegex?: string, enablePkce?: bool, enableProxy?: bool, enableSignAuthnRequest?: bool, endpoint?: string, host?: string, httpHeaders?: any, idP?: string, intranetEndpoint?: string, issuerUrl?: string, metadata?: string, method?: string, name?: string, owner?: string, pathPrefix?: string, port?: int, providerUrl?: string, receiver?: string, regionId?: string, scopes?: string, signName?: string, subType?: string, templateCode?: string, title?: string, type?: string, userMapping?: any}
export def "update-product ApiControllerUpdateProduct" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the product
  --createdTime: string
  --currency: string
  --description: string
  --detail: string
  --disableCustomRecharge: oneof<nothing, bool>
  --displayName: string
  --image: string
  --isRecharge: oneof<nothing, bool>
  --name: string
  --owner: string
  --price: float # format: double
  --providerObjs: list # item shape: {appId?: string, bucket?: string, category?: string, cert?: string, clientId?: string, clientId2?: string, clientSecret?: string, clientSecret2?: string, content?: string, createdTime?: string, customAuthUrl?: string, customLogo?: string, customTokenUrl?: string, customUserInfoUrl?: string, disableSsl?: bool, displayName?: string, domain?: string, emailRegex?: string, enablePkce?: bool, enableProxy?: bool, enableSignAuthnRequest?: bool, endpoint?: string, host?: string, httpHeaders?: any, idP?: string, intranetEndpoint?: string, issuerUrl?: string, metadata?: string, method?: string, name?: string, owner?: string, pathPrefix?: string, port?: int, providerUrl?: string, receiver?: string, regionId?: string, scopes?: string, signName?: string, subType?: string, templateCode?: string, title?: string, type?: string, userMapping?: any}
  --providers: list
  --quantity: int # format: int64
  --rechargeOptions: list
  --sold: int # format: int64
  --state: string
  --successUrl: string
  --tag: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/update-product" $qp)
  let body = {createdTime: $createdTime, currency: $currency, description: $description, detail: $detail, disableCustomRecharge: $disableCustomRecharge, displayName: $displayName, image: $image, isRecharge: $isRecharge, name: $name, owner: $owner, price: $price, providerObjs: $providerObjs, providers: $providers, quantity: $quantity, rechargeOptions: $rechargeOptions, sold: $sold, state: $state, successUrl: $successUrl, tag: $tag} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# update provider
#
# POST /api/update-provider
# operationId: ApiController.UpdateProvider
export def "update-provider ApiControllerUpdateProvider" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the provider
  --appId: string
  --bucket: string
  --category: string
  --cert: string
  --clientId: string
  --clientId2: string
  --clientSecret: string
  --clientSecret2: string
  --content: string
  --createdTime: string
  --customAuthUrl: string
  --customLogo: string
  --customTokenUrl: string
  --customUserInfoUrl: string
  --disableSsl: oneof<nothing, bool>
  --displayName: string
  --domain: string
  --emailRegex: string
  --enablePkce: oneof<nothing, bool>
  --enableProxy: oneof<nothing, bool>
  --enableSignAuthnRequest: oneof<nothing, bool>
  --endpoint: string
  --host: string
  --httpHeaders: any
  --idP: string
  --intranetEndpoint: string
  --issuerUrl: string
  --metadata: string
  --method: string
  --name: string
  --owner: string
  --pathPrefix: string
  --port: int # format: int64
  --providerUrl: string
  --receiver: string
  --regionId: string
  --scopes: string
  --signName: string
  --subType: string
  --templateCode: string
  --title: string
  --type: string
  --userMapping: any
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/update-provider" $qp)
  let body = {appId: $appId, bucket: $bucket, category: $category, cert: $cert, clientId: $clientId, clientId2: $clientId2, clientSecret: $clientSecret, clientSecret2: $clientSecret2, content: $content, createdTime: $createdTime, customAuthUrl: $customAuthUrl, customLogo: $customLogo, customTokenUrl: $customTokenUrl, customUserInfoUrl: $customUserInfoUrl, disableSsl: $disableSsl, displayName: $displayName, domain: $domain, emailRegex: $emailRegex, enablePkce: $enablePkce, enableProxy: $enableProxy, enableSignAuthnRequest: $enableSignAuthnRequest, endpoint: $endpoint, host: $host, httpHeaders: $httpHeaders, idP: $idP, intranetEndpoint: $intranetEndpoint, issuerUrl: $issuerUrl, metadata: $metadata, method: $method, name: $name, owner: $owner, pathPrefix: $pathPrefix, port: $port, providerUrl: $providerUrl, receiver: $receiver, regionId: $regionId, scopes: $scopes, signName: $signName, subType: $subType, templateCode: $templateCode, title: $title, type: $type, userMapping: $userMapping} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# get resource
#
# POST /api/update-resource
# operationId: ApiController.UpdateResource
export def "update-resource ApiControllerUpdateResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of resource
  --application: string
  --createdTime: string
  --description: string
  --fileFormat: string
  --fileName: string
  --fileSize: int # format: int64
  --fileType: string
  --name: string
  --owner: string
  --parent: string
  --provider: string
  --tag: string
  --body-url: string
  --user: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/update-resource" $qp)
  let body = {application: $application, createdTime: $createdTime, description: $description, fileFormat: $fileFormat, fileName: $fileName, fileSize: $fileSize, fileType: $fileType, name: $name, owner: $owner, parent: $parent, provider: $provider, tag: $tag, url: $body_url, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# update role
#
# POST /api/update-role
# operationId: ApiController.UpdateRole
export def "update-role ApiControllerUpdateRole" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the role
  --createdTime: string
  --description: string
  --displayName: string
  --domains: list
  --groups: list
  --isEnabled: oneof<nothing, bool>
  --name: string
  --owner: string
  --roles: list
  --users: list
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/update-role" $qp)
  let body = {createdTime: $createdTime, description: $description, displayName: $displayName, domains: $domains, groups: $groups, isEnabled: $isEnabled, name: $name, owner: $owner, roles: $roles, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update session for one user in one application.
#
# POST /api/update-session
# operationId: ApiController.UpdateSession
export def "update-session ApiControllerUpdateSession" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ExclusiveSignin: oneof<nothing, bool>
  --application: string
  --createdTime: string
  --name: string
  --owner: string
  --sessionId: list
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/update-session")
  let body = {ExclusiveSignin: $ExclusiveSignin, application: $application, createdTime: $createdTime, name: $name, owner: $owner, sessionId: $sessionId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# update subscription
#
# POST /api/update-subscription
# operationId: ApiController.UpdateSubscription
export def "update-subscription ApiControllerUpdateSubscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the subscription
  --createdTime: string
  --description: string
  --displayName: string
  --endTime: string
  --name: string
  --owner: string
  --payment: string
  --period: string
  --plan: string
  --pricing: string
  --startTime: string
  --state: string@state-completer-1 # e.g. Pending
  --user: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/update-subscription" $qp)
  let body = {createdTime: $createdTime, description: $description, displayName: $displayName, endTime: $endTime, name: $name, owner: $owner, payment: $payment, period: $period, plan: $plan, pricing: $pricing, startTime: $startTime, state: $state, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# update syncer
#
# POST /api/update-syncer
# operationId: ApiController.UpdateSyncer
# --tableColumns item shape: {casdoorName?: string, isHashed?: bool, isKey?: bool, name?: string, type?: string, values?: list}
export def "update-syncer ApiControllerUpdateSyncer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the syncer
  --affiliationTable: string
  --avatarBaseUrl: string
  --cert: string
  --createdTime: string
  --database: string
  --databaseType: string
  --errorText: string
  --host: string
  --isEnabled: oneof<nothing, bool>
  --isReadOnly: oneof<nothing, bool>
  --name: string
  --organization: string
  --owner: string
  --password: string
  --port: int # format: int64
  --sshHost: string
  --sshPassword: string
  --sshPort: int # format: int64
  --sshType: string
  --sshUser: string
  --sslMode: string
  --syncInterval: int # format: int64
  --table: string
  --tableColumns: list # item shape: {casdoorName?: string, isHashed?: bool, isKey?: bool, name?: string, type?: string, values?: list}
  --type: string
  --user: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/update-syncer" $qp)
  let body = {affiliationTable: $affiliationTable, avatarBaseUrl: $avatarBaseUrl, cert: $cert, createdTime: $createdTime, database: $database, databaseType: $databaseType, errorText: $errorText, host: $host, isEnabled: $isEnabled, isReadOnly: $isReadOnly, name: $name, organization: $organization, owner: $owner, password: $password, port: $port, sshHost: $sshHost, sshPassword: $sshPassword, sshPort: $sshPort, sshType: $sshType, sshUser: $sshUser, sslMode: $sslMode, syncInterval: $syncInterval, table: $table, tableColumns: $tableColumns, type: $type, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# update ticket
#
# POST /api/update-ticket
# operationId: ApiController.UpdateTicket
# --messages item shape: {author?: string, isAdmin?: bool, text?: string, timestamp?: string}
export def "update-ticket ApiControllerUpdateTicket" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the ticket
  --content: string
  --createdTime: string
  --displayName: string
  --messages: list # item shape: {author?: string, isAdmin?: bool, text?: string, timestamp?: string}
  --name: string
  --owner: string
  --state: string
  --title: string
  --updatedTime: string
  --user: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/update-ticket" $qp)
  let body = {content: $content, createdTime: $createdTime, displayName: $displayName, messages: $messages, name: $name, owner: $owner, state: $state, title: $title, updatedTime: $updatedTime, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# update token
#
# POST /api/update-token
# operationId: ApiController.UpdateToken
export def "update-token ApiControllerUpdateToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The token ID in format: organization/token-name (e.g., built-in/token-123456)
  --accessToken: string
  --accessTokenHash: string
  --application: string
  --code: string
  --codeChallenge: string
  --codeExpireIn: int # format: int64
  --codeIsUsed: oneof<nothing, bool>
  --createdTime: string
  --expiresIn: int # format: int64
  --name: string
  --organization: string
  --owner: string
  --refreshToken: string
  --refreshTokenHash: string
  --scope: string
  --tokenType: string
  --user: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/update-token" $qp)
  let body = {accessToken: $accessToken, accessTokenHash: $accessTokenHash, application: $application, code: $code, codeChallenge: $codeChallenge, codeExpireIn: $codeExpireIn, codeIsUsed: $codeIsUsed, createdTime: $createdTime, expiresIn: $expiresIn, name: $name, organization: $organization, owner: $owner, refreshToken: $refreshToken, refreshTokenHash: $refreshTokenHash, scope: $scope, tokenType: $tokenType, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# update transaction
#
# POST /api/update-transaction
# operationId: ApiController.UpdateTransaction
export def "update-transaction ApiControllerUpdateTransaction" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the transaction
  --amount: float # format: double
  --application: string
  --category: string@category-completer # e.g. Purchase
  --createdTime: string
  --currency: string
  --displayName: string
  --domain: string
  --name: string
  --owner: string
  --payment: string
  --provider: string
  --state: string
  --subtype: string
  --tag: string
  --type: string
  --user: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/update-transaction" $qp)
  let body = {amount: $amount, application: $application, category: $category, createdTime: $createdTime, currency: $currency, displayName: $displayName, domain: $domain, name: $name, owner: $owner, payment: $payment, provider: $provider, state: $state, subtype: $subtype, tag: $tag, type: $type, user: $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# update user
#
# POST /api/update-user
# operationId: ApiController.UpdateUser
# --addresses item shape: {city?: string, line1?: string, line2?: string, region?: string, state?: string, tag?: string, zipCode?: string}
# --cart item shape: {currency?: string, detail?: string, displayName?: string, image?: string, isRecharge?: bool, name?: string, owner?: string, planName?: string, price?: float, pricingName?: string, quantity?: int}
# --faceIds item shape: {ImageUrl?: string, faceIdData?: list, name?: string}
# --managedAccounts item shape: {application?: string, password?: string, signinUrl?: string, username?: string}
# --mfaAccounts item shape: {accountName?: string, issuer?: string, origin?: string, secretKey?: string}
# --mfaItems item shape: {name?: string, rule?: string}
# --multiFactorAuths item shape: {countryCode?: string, enabled?: bool, isPreferred?: bool, mfaRememberInHours?: int, mfaType?: string, recoveryCodes?: list, secret?: string, url?: string}
# --permissions item shape: {actions?: list, adapter?: string, approveTime?: string, approver?: string, createdTime?: string, description?: string, displayName?: string, domains?: list, effect?: string, groups?: list, isEnabled?: bool, model?: string, name?: string, owner?: string, resourceType?: string, resources?: list, roles?: list, state?: string, submitter?: string, users?: list}
# --roles item shape: {createdTime?: string, description?: string, displayName?: string, domains?: list, groups?: list, isEnabled?: bool, name?: string, owner?: string, roles?: list, users?: list}
export def "update-user ApiControllerUpdateUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the user
  --userId: string # The userId (UUID) of the user
  --owner: string # The owner of the user (required when using userId)
  --accessKey: string
  --accessSecret: string
  --accessToken: string
  --address: list
  --addresses: list # item shape: {city?: string, line1?: string, line2?: string, region?: string, state?: string, tag?: string, zipCode?: string}
  --adfs: string
  --affiliation: string
  --alipay: string
  --amazon: string
  --apple: string
  --auth0: string
  --avatar: string
  --avatarType: string
  --azuread: string
  --azureadb2c: string
  --baidu: string
  --balance: float # format: double
  --balanceCredit: float # format: double
  --balanceCurrency: string
  --battlenet: string
  --bilibili: string
  --bio: string
  --birthday: string
  --bitbucket: string
  --box: string
  --cart: list # item shape: {currency?: string, detail?: string, displayName?: string, image?: string, isRecharge?: bool, name?: string, owner?: string, planName?: string, price?: float, pricingName?: string, quantity?: int}
  --casdoor: string
  --cloudfoundry: string
  --countryCode: string
  --createdIp: string
  --createdTime: string
  --currency: string
  --custom: string
  --custom10: string
  --custom2: string
  --custom3: string
  --custom4: string
  --custom5: string
  --custom6: string
  --custom7: string
  --custom8: string
  --custom9: string
  --dailymotion: string
  --deezer: string
  --deletedTime: string
  --digitalocean: string
  --dingtalk: string
  --discord: string
  --displayName: string
  --douyin: string
  --dropbox: string
  --education: string
  --email: string
  --emailVerified: oneof<nothing, bool>
  --eveonline: string
  --externalId: string
  --faceIds: list # item shape: {ImageUrl?: string, faceIdData?: list, name?: string}
  --facebook: string
  --firstName: string
  --fitbit: string
  --gender: string
  --gitea: string
  --gitee: string
  --github: string
  --gitlab: string
  --google: string
  --groups: list
  --hash: string
  --heroku: string
  --homepage: string
  --id: string
  --idCard: string
  --idCardType: string
  --influxcloud: string
  --infoflow: string
  --instagram: string
  --intercom: string
  --invitation: string
  --invitationCode: string
  --ipWhitelist: string
  --isAdmin: oneof<nothing, bool>
  --isDefaultAvatar: oneof<nothing, bool>
  --isDeleted: oneof<nothing, bool>
  --isForbidden: oneof<nothing, bool>
  --isOnline: oneof<nothing, bool>
  --isVerified: oneof<nothing, bool>
  --kakao: string
  --karma: int # format: int64
  --kwai: string
  --language: string
  --lark: string
  --lastChangePasswordTime: string
  --lastName: string
  --lastSigninIp: string
  --lastSigninTime: string
  --lastSigninWrongTime: string
  --lastfm: string
  --ldap: string
  --line: string
  --linkedin: string
  --location: string
  --mailru: string
  --managedAccounts: list # item shape: {application?: string, password?: string, signinUrl?: string, username?: string}
  --meetup: string
  --metamask: string
  --mfaAccounts: list # item shape: {accountName?: string, issuer?: string, origin?: string, secretKey?: string}
  --mfaEmailEnabled: oneof<nothing, bool>
  --mfaItems: list # item shape: {name?: string, rule?: string}
  --mfaPhoneEnabled: oneof<nothing, bool>
  --mfaPushEnabled: oneof<nothing, bool>
  --mfaPushProvider: string
  --mfaPushReceiver: string
  --mfaRadiusEnabled: oneof<nothing, bool>
  --mfaRadiusProvider: string
  --mfaRadiusUsername: string
  --mfaRememberDeadline: string
  --microsoftonline: string
  --multiFactorAuths: list # item shape: {countryCode?: string, enabled?: bool, isPreferred?: bool, mfaRememberInHours?: int, mfaType?: string, recoveryCodes?: list, secret?: string, url?: string}
  --name: string
  --naver: string
  --needUpdatePassword: oneof<nothing, bool>
  --nextcloud: string
  --okta: string
  --onedrive: string
  --originalRefreshToken: string
  --originalToken: string
  --oura: string
  --owner: string
  --password: string
  --passwordSalt: string
  --passwordType: string
  --patreon: string
  --paypal: string
  --permanentAvatar: string
  --permissions: list # item shape: {actions?: list, adapter?: string, approveTime?: string, approver?: string, createdTime?: string, description?: string, displayName?: string, domains?: list, effect?: string, groups?: list, isEnabled?: bool, model?: string, name?: string, owner?: string, resourceType?: string, resources?: list, roles?: list, state?: string, submitter?: string, users?: list}
  --phone: string
  --preHash: string
  --preferredMfaType: string
  --properties: any
  --qq: string
  --ranking: int # format: int64
  --realName: string
  --recoveryCodes: list
  --region: string
  --registerSource: string
  --registerType: string
  --roles: list # item shape: {createdTime?: string, description?: string, displayName?: string, domains?: list, groups?: list, isEnabled?: bool, name?: string, owner?: string, roles?: list, users?: list}
  --salesforce: string
  --score: int # format: int64
  --shopify: string
  --signinWrongTimes: int # format: int64
  --signupApplication: string
  --slack: string
  --soundcloud: string
  --spotify: string
  --steam: string
  --strava: string
  --stripe: string
  --tag: string
  --tiktok: string
  --title: string
  --totpSecret: string
  --tumblr: string
  --twitch: string
  --twitter: string
  --type: string
  --typetalk: string
  --uber: string
  --updatedTime: string
  --vk: string
  --web3onboard: string
  --webauthnCredentials: list
  --wechat: string
  --wecom: string
  --weibo: string
  --wepay: string
  --xero: string
  --yahoo: string
  --yammer: string
  --yandex: string
  --zoom: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "userId" $userId "scalar") (serialize-qp "owner" $owner "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/update-user" $qp)
  let body = {accessKey: $accessKey, accessSecret: $accessSecret, accessToken: $accessToken, address: $address, addresses: $addresses, adfs: $adfs, affiliation: $affiliation, alipay: $alipay, amazon: $amazon, apple: $apple, auth0: $auth0, avatar: $avatar, avatarType: $avatarType, azuread: $azuread, azureadb2c: $azureadb2c, baidu: $baidu, balance: $balance, balanceCredit: $balanceCredit, balanceCurrency: $balanceCurrency, battlenet: $battlenet, bilibili: $bilibili, bio: $bio, birthday: $birthday, bitbucket: $bitbucket, box: $box, cart: $cart, casdoor: $casdoor, cloudfoundry: $cloudfoundry, countryCode: $countryCode, createdIp: $createdIp, createdTime: $createdTime, currency: $currency, custom: $custom, custom10: $custom10, custom2: $custom2, custom3: $custom3, custom4: $custom4, custom5: $custom5, custom6: $custom6, custom7: $custom7, custom8: $custom8, custom9: $custom9, dailymotion: $dailymotion, deezer: $deezer, deletedTime: $deletedTime, digitalocean: $digitalocean, dingtalk: $dingtalk, discord: $discord, displayName: $displayName, douyin: $douyin, dropbox: $dropbox, education: $education, email: $email, emailVerified: $emailVerified, eveonline: $eveonline, externalId: $externalId, faceIds: $faceIds, facebook: $facebook, firstName: $firstName, fitbit: $fitbit, gender: $gender, gitea: $gitea, gitee: $gitee, github: $github, gitlab: $gitlab, google: $google, groups: $groups, hash: $hash, heroku: $heroku, homepage: $homepage, id: $id, idCard: $idCard, idCardType: $idCardType, influxcloud: $influxcloud, infoflow: $infoflow, instagram: $instagram, intercom: $intercom, invitation: $invitation, invitationCode: $invitationCode, ipWhitelist: $ipWhitelist, isAdmin: $isAdmin, isDefaultAvatar: $isDefaultAvatar, isDeleted: $isDeleted, isForbidden: $isForbidden, isOnline: $isOnline, isVerified: $isVerified, kakao: $kakao, karma: $karma, kwai: $kwai, language: $language, lark: $lark, lastChangePasswordTime: $lastChangePasswordTime, lastName: $lastName, lastSigninIp: $lastSigninIp, lastSigninTime: $lastSigninTime, lastSigninWrongTime: $lastSigninWrongTime, lastfm: $lastfm, ldap: $ldap, line: $line, linkedin: $linkedin, location: $location, mailru: $mailru, managedAccounts: $managedAccounts, meetup: $meetup, metamask: $metamask, mfaAccounts: $mfaAccounts, mfaEmailEnabled: $mfaEmailEnabled, mfaItems: $mfaItems, mfaPhoneEnabled: $mfaPhoneEnabled, mfaPushEnabled: $mfaPushEnabled, mfaPushProvider: $mfaPushProvider, mfaPushReceiver: $mfaPushReceiver, mfaRadiusEnabled: $mfaRadiusEnabled, mfaRadiusProvider: $mfaRadiusProvider, mfaRadiusUsername: $mfaRadiusUsername, mfaRememberDeadline: $mfaRememberDeadline, microsoftonline: $microsoftonline, multiFactorAuths: $multiFactorAuths, name: $name, naver: $naver, needUpdatePassword: $needUpdatePassword, nextcloud: $nextcloud, okta: $okta, onedrive: $onedrive, originalRefreshToken: $originalRefreshToken, originalToken: $originalToken, oura: $oura, owner: $owner, password: $password, passwordSalt: $passwordSalt, passwordType: $passwordType, patreon: $patreon, paypal: $paypal, permanentAvatar: $permanentAvatar, permissions: $permissions, phone: $phone, preHash: $preHash, preferredMfaType: $preferredMfaType, properties: $properties, qq: $qq, ranking: $ranking, realName: $realName, recoveryCodes: $recoveryCodes, region: $region, registerSource: $registerSource, registerType: $registerType, roles: $roles, salesforce: $salesforce, score: $score, shopify: $shopify, signinWrongTimes: $signinWrongTimes, signupApplication: $signupApplication, slack: $slack, soundcloud: $soundcloud, spotify: $spotify, steam: $steam, strava: $strava, stripe: $stripe, tag: $tag, tiktok: $tiktok, title: $title, totpSecret: $totpSecret, tumblr: $tumblr, twitch: $twitch, twitter: $twitter, type: $type, typetalk: $typetalk, uber: $uber, updatedTime: $updatedTime, vk: $vk, web3onboard: $web3onboard, webauthnCredentials: $webauthnCredentials, wechat: $wechat, wecom: $wecom, weibo: $weibo, wepay: $wepay, xero: $xero, yahoo: $yahoo, yammer: $yammer, yandex: $yandex, zoom: $zoom} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# update webhook
#
# POST /api/update-webhook
# operationId: ApiController.UpdateWebhook
# --headers item shape: {name?: string, value?: string}
export def "update-webhook ApiControllerUpdateWebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the webhook (default: built-in/admin)
  --contentType: string
  --createdTime: string
  --events: list
  --headers: list # item shape: {name?: string, value?: string}
  --isEnabled: oneof<nothing, bool>
  --isUserExtended: oneof<nothing, bool>
  --method: string
  --name: string
  --objectFields: list
  --organization: string
  --owner: string
  --singleOrgOnly: oneof<nothing, bool>
  --tokenFields: list
  --body-url: string
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/update-webhook" $qp)
  let body = {contentType: $contentType, createdTime: $createdTime, events: $events, headers: $headers, isEnabled: $isEnabled, isUserExtended: $isUserExtended, method: $method, name: $name, objectFields: $objectFields, organization: $organization, owner: $owner, singleOrgOnly: $singleOrgOnly, tokenFields: $tokenFields, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /api/upload-resource
#
# operationId: ApiController.UploadResource
export def "upload-resource ApiControllerUploadResource" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # Owner
  --user: string # User
  --application: string # Application
  --tag: string # Tag
  --parent: string # Parent
  --fullFilePath: string # Full File Path
  --createdTime: string # Created Time
  --description: string # Description
  file: path # Resource file
]: any -> record<application: string, createdTime: string, description: string, fileFormat: string, fileName: string, fileSize: int, fileType: string, name: string, owner: string, parent: string, provider: string, tag: string, url: string, user: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar") (serialize-qp "user" $user "scalar") (serialize-qp "application" $application "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "parent" $parent "scalar") (serialize-qp "fullFilePath" $fullFilePath "scalar") (serialize-qp "createdTime" $createdTime "scalar") (serialize-qp "description" $description "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/upload-resource" $qp)
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let body = if ($file | is-not-empty) { $body | upsert file (open -r $file) } else { $body }
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# return Laravel compatible user information according to OAuth 2.0
#
# GET /api/user
# operationId: ApiController.UserInfo2
export def "user ApiControllerUserInfo2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<created_at: string, email: string, email_verified_at: string, id: string, name: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/user")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# return user information according to OIDC standards
#
# GET /api/userinfo
# operationId: ApiController.UserInfo
export def "userinfo ApiControllerUserInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<address: string, aud: string, email: string, email_verified: bool, groups: list<string>, is_verified: bool, iss: string, name: string, permissions: list<string>, phone: string, picture: string, preferred_username: string, real_name: string, roles: list<string>, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/userinfo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/verify-captcha
#
# operationId: ApiController.VerifyCaptcha
export def "verify-captcha ApiControllerVerifyCaptcha" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<address: string, aud: string, email: string, email_verified: bool, groups: list<string>, is_verified: bool, iss: string, name: string, permissions: list<string>, phone: string, picture: string, preferred_username: string, real_name: string, roles: list<string>, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/verify-captcha")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /api/verify-code
#
# operationId: ApiController.VerifyCode
export def "verify-code ApiControllerVerifyCode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<address: string, aud: string, email: string, email_verified: bool, groups: list<string>, is_verified: bool, iss: string, name: string, permissions: list<string>, phone: string, picture: string, preferred_username: string, real_name: string, roles: list<string>, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/verify-code")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# verify user's real identity using ID Verification provider
#
# POST /api/verify-identification
# operationId: ApiController.VerifyIdentification
export def "verify-identification ApiControllerVerifyIdentification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # The owner of the user (optional, defaults to logged-in user)
  --name: string # The name of the user (optional, defaults to logged-in user)
  --provider: string # The name of the ID Verification provider (optional, auto-selected if not provided)
]: nothing -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "provider" $provider "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/verify-identification" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# verify invitation
#
# GET /api/verify-invitation
# operationId: ApiController.VerifyInvitation
export def "verify-invitation ApiControllerVerifyInvitation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The id ( owner/name ) of the invitation
]: nothing -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/verify-invitation" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# WebAuthn Login Flow 1st stage
#
# GET /api/webauthn/signin/begin
# operationId: ApiController.WebAuthnSigninBegin
export def "webauthn-signin-begin ApiControllerWebAuthnSigninBegin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --owner: string # owner
  --name: string # name
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "owner" $owner "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/webauthn/signin/begin" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# WebAuthn Login Flow 2nd stage
#
# POST /api/webauthn/signin/finish
# operationId: ApiController.WebAuthnSigninFinish
export def "webauthn-signin-finish ApiControllerWebAuthnSigninFinish" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/webauthn/signin/finish")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# WebAuthn Registration Flow 1st stage
#
# GET /api/webauthn/signup/begin
# operationId: ApiController.WebAuthnSignupBegin
export def "webauthn-signup-begin ApiControllerWebAuthnSignupBegin" [
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
  let full_url = (build-url $base "/api/webauthn/signup/begin")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# WebAuthn Registration Flow 2nd stage
#
# POST /api/webauthn/signup/finish
# operationId: ApiController.WebAuthnSignupFinish
export def "webauthn-signup-finish ApiControllerWebAuthnSignupFinish" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/webauthn/signup/finish")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /api/webhook
#
# operationId: ApiController.HandleOfficialAccountEvent
export def "webhook ApiControllerHandleOfficialAccountEvent" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: any, data2: any, data3: any, msg: string, name: string, status: string, sub: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/webhook")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
