# Auto-generated client for GraphRbacManagementClient v1.6
# Source: https://api.apis.guru/v2/specs/windows.net/graphrbac/1.6/openapi.json
# Auth: --token flag or $env.GRAPHRBACMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://graph.windows.net"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GRAPHRBACMANAGEMENTCLIENT_TOKEN | default "" }
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

def base-url-completer [] { ["https://graph.windows.net"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/json"] }
def groupMembershipClaims-completer [] { ["All" "None" "SecurityGroup"] }
def mailEnabled-completer [] { ["false"] }
def securityEnabled-completer [] { ["true"] }
def consentType-completer [] { ["AllPrincipals" "Principal"] }
def userType-completer [] { ["Guest" "Member"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "applications List" } } | get name | first)
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

# Lists applications by filter parameters.
#
# GET /{tenantID}/applications
# operationId: Applications_List
export def "applications List" [
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --filter: string # The filters to apply to the operation.
  --api-version: string # Client API version.
]: nothing -> record<odata_nextLink: string, value: table<allowGuestsSignIn: bool, allowPassthroughUsers: bool, appId: string, appLogoUrl: string, appPermissions: list, appRoles: list, availableToOtherTenants: bool, displayName: string, errorUrl: string, groupMembershipClaims: string, homepage: string, identifierUris: list, informationalUrls: record, isDeviceOnlyAuthSupported: bool, keyCredentials: list, knownClientApplications: list, logoutUrl: string, oauth2AllowImplicitFlow: bool, oauth2AllowUrlPathMatching: bool, oauth2Permissions: list, oauth2RequirePostResponse: bool, optionalClaims: record, orgRestrictions: list, passwordCredentials: list, preAuthorizedApplications: list, publicClient: bool, publisherDomain: string, replyUrls: list, requiredResourceAccess: list, samlMetadataUrl: string, signInAudience: string, wwwHomepage: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/applications" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new application.
#
# POST /{tenantID}/applications
# operationId: Applications_Create
# --appRoles item shape: {allowedMemberTypes?: list, description?: string, displayName?: string, id?: string, isEnabled?: bool, value?: string}
# --informationalUrls shape: {marketing?: string, privacy?: string, support?: string, termsOfService?: string}
# --keyCredentials item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, type?: string, usage?: string, value?: string}
# --oauth2Permissions item shape: {adminConsentDescription?: string, adminConsentDisplayName?: string, id?: string, isEnabled?: bool, type?: string, userConsentDescription?: string, userConsentDisplayName?: string, value?: string}
# --optionalClaims shape: {accessToken?: list, idToken?: list, samlToken?: list}
# --passwordCredentials item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, value?: string}
# --preAuthorizedApplications item shape: {appId?: string, extensions?: list, permissions?: list}
# --requiredResourceAccess item shape: {resourceAccess: list, resourceAppId?: string}
export def "applications Create" [
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  displayName: string # The display name of the application.
  --identifierUris: list # A collection of URIs for the application.
  --allowGuestsSignIn: oneof<nothing, bool> # A property on the application to indicate if the application accepts other IDPs or not or partially accepts.
  --allowPassthroughUsers: oneof<nothing, bool> # Indicates that the application supports pass through users who have no presence in the resource tenant.
  --appLogoUrl: string # The url for the application logo image stored in a CDN.
  --appPermissions: list # The application permissions.
  --appRoles: list # The collection of application roles that an application may declare. These roles can be assigned to users, groups or service principals. — item shape: {allowedMemberTypes?: list, description?: string, displayName?: string, id?: string, isEnabled?: bool, value?: string}
  --availableToOtherTenants: oneof<nothing, bool> # Whether the application is available to other tenants.
  --errorUrl: string # A URL provided by the author of the application to report errors when using the application.
  --groupMembershipClaims: string@groupMembershipClaims-completer # Configures the groups claim issued in a user or OAuth 2.0 access token that the app expects.
  --homepage: string # The home page of the application.
  --informationalUrls: record # Represents a group of URIs that provide terms of service, marketing, support and privacy policy information about an application. The default value for each string is null. — shape: {marketing?: string, privacy?: string, support?: string, termsOfService?: string}
  --isDeviceOnlyAuthSupported: oneof<nothing, bool> # Specifies whether this application supports device authentication without a user. The default is false.
  --keyCredentials: list # A collection of KeyCredential objects. — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, type?: string, usage?: string, value?: string}
  --knownClientApplications: list # Client applications that are tied to this resource application. Consent to any of the known client applications will result in implicit consent to the resource application through a combined consent dialog (showing the OAuth permission scopes required by the client and the resource).
  --logoutUrl: string # the url of the logout page
  --oauth2AllowImplicitFlow: oneof<nothing, bool> # Whether to allow implicit grant flow for OAuth2
  --oauth2AllowUrlPathMatching: oneof<nothing, bool> # Specifies whether during a token Request Azure AD will allow path matching of the redirect URI against the applications collection of replyURLs. The default is false.
  --oauth2Permissions: list # The collection of OAuth 2.0 permission scopes that the web API (resource) application exposes to client applications. These permission scopes may be granted to client applications during consent. — item shape: {adminConsentDescription?: string, adminConsentDisplayName?: string, id?: string, isEnabled?: bool, type?: string, userConsentDescription?: string, userConsentDisplayName?: string, value?: string}
  --oauth2RequirePostResponse: oneof<nothing, bool> # Specifies whether, as part of OAuth 2.0 token requests, Azure AD will allow POST requests, as opposed to GET requests. The default is false, which specifies that only GET requests will be allowed.
  --optionalClaims: record # Specifying the claims to be included in the token. — shape: {accessToken?: list, idToken?: list, samlToken?: list}
  --orgRestrictions: list # A list of tenants allowed to access application.
  --passwordCredentials: list # A collection of PasswordCredential objects — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, value?: string}
  --preAuthorizedApplications: list # list of pre-authorized applications. — item shape: {appId?: string, extensions?: list, permissions?: list}
  --publicClient: oneof<nothing, bool> # Specifies whether this application is a public client (such as an installed application running on a mobile device). Default is false.
  --publisherDomain: string # Reliable domain which can be used to identify an application.
  --replyUrls: list # A collection of reply URLs for the application.
  --requiredResourceAccess: list # Specifies resources that this application requires access to and the set of OAuth permission scopes and application roles that it needs under each of those resources. This pre-configuration of required resource access drives the consent experience. — item shape: {resourceAccess: list, resourceAppId?: string}
  --samlMetadataUrl: string # The URL to the SAML metadata for the application.
  --signInAudience: string # Audience for signing in to the application (AzureADMyOrganization, AzureADAllOrganizations, AzureADAndMicrosoftAccounts).
  --wwwHomepage: string # The primary Web page.
]: any -> record<allowGuestsSignIn: bool, allowPassthroughUsers: bool, appId: string, appLogoUrl: string, appPermissions: list<string>, appRoles: table<allowedMemberTypes: list, description: string, displayName: string, id: string, isEnabled: bool, value: string>, availableToOtherTenants: bool, displayName: string, errorUrl: string, groupMembershipClaims: string, homepage: string, identifierUris: list<string>, informationalUrls: record<marketing: string, privacy: string, support: string, termsOfService: string>, isDeviceOnlyAuthSupported: bool, keyCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, type: string, usage: string, value: string>, knownClientApplications: list<string>, logoutUrl: string, oauth2AllowImplicitFlow: bool, oauth2AllowUrlPathMatching: bool, oauth2Permissions: table<adminConsentDescription: string, adminConsentDisplayName: string, id: string, isEnabled: bool, type: string, userConsentDescription: string, userConsentDisplayName: string, value: string>, oauth2RequirePostResponse: bool, optionalClaims: record<accessToken: list<record>, idToken: list<record>, samlToken: list<record>>, orgRestrictions: list<string>, passwordCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, value: string>, preAuthorizedApplications: table<appId: string, extensions: list, permissions: list>, publicClient: bool, publisherDomain: string, replyUrls: list<string>, requiredResourceAccess: table<resourceAccess: list, resourceAppId: string>, samlMetadataUrl: string, signInAudience: string, wwwHomepage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/applications" $qp)
  let body = {displayName: $displayName, identifierUris: $identifierUris, allowGuestsSignIn: $allowGuestsSignIn, allowPassthroughUsers: $allowPassthroughUsers, appLogoUrl: $appLogoUrl, appPermissions: $appPermissions, appRoles: $appRoles, availableToOtherTenants: $availableToOtherTenants, errorUrl: $errorUrl, groupMembershipClaims: $groupMembershipClaims, homepage: $homepage, informationalUrls: $informationalUrls, isDeviceOnlyAuthSupported: $isDeviceOnlyAuthSupported, keyCredentials: $keyCredentials, knownClientApplications: $knownClientApplications, logoutUrl: $logoutUrl, oauth2AllowImplicitFlow: $oauth2AllowImplicitFlow, oauth2AllowUrlPathMatching: $oauth2AllowUrlPathMatching, oauth2Permissions: $oauth2Permissions, oauth2RequirePostResponse: $oauth2RequirePostResponse, optionalClaims: $optionalClaims, orgRestrictions: $orgRestrictions, passwordCredentials: $passwordCredentials, preAuthorizedApplications: $preAuthorizedApplications, publicClient: $publicClient, publisherDomain: $publisherDomain, replyUrls: $replyUrls, requiredResourceAccess: $requiredResourceAccess, samlMetadataUrl: $samlMetadataUrl, signInAudience: $signInAudience, wwwHomepage: $wwwHomepage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an application.
#
# DELETE /{tenantID}/applications/{applicationObjectId}
# operationId: Applications_Delete
export def "applications Delete" [
  applicationObjectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_error: record<code: string, message: record<value: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/applications/($applicationObjectId)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an application by object ID.
#
# GET /{tenantID}/applications/{applicationObjectId}
# operationId: Applications_Get
export def "applications Get" [
  applicationObjectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<allowGuestsSignIn: bool, allowPassthroughUsers: bool, appId: string, appLogoUrl: string, appPermissions: list<string>, appRoles: table<allowedMemberTypes: list, description: string, displayName: string, id: string, isEnabled: bool, value: string>, availableToOtherTenants: bool, displayName: string, errorUrl: string, groupMembershipClaims: string, homepage: string, identifierUris: list<string>, informationalUrls: record<marketing: string, privacy: string, support: string, termsOfService: string>, isDeviceOnlyAuthSupported: bool, keyCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, type: string, usage: string, value: string>, knownClientApplications: list<string>, logoutUrl: string, oauth2AllowImplicitFlow: bool, oauth2AllowUrlPathMatching: bool, oauth2Permissions: table<adminConsentDescription: string, adminConsentDisplayName: string, id: string, isEnabled: bool, type: string, userConsentDescription: string, userConsentDisplayName: string, value: string>, oauth2RequirePostResponse: bool, optionalClaims: record<accessToken: list<record>, idToken: list<record>, samlToken: list<record>>, orgRestrictions: list<string>, passwordCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, value: string>, preAuthorizedApplications: table<appId: string, extensions: list, permissions: list>, publicClient: bool, publisherDomain: string, replyUrls: list<string>, requiredResourceAccess: table<resourceAccess: list, resourceAppId: string>, samlMetadataUrl: string, signInAudience: string, wwwHomepage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/applications/($applicationObjectId)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing application.
#
# PATCH /{tenantID}/applications/{applicationObjectId}
# operationId: Applications_Patch
# --appRoles item shape: {allowedMemberTypes?: list, description?: string, displayName?: string, id?: string, isEnabled?: bool, value?: string}
# --informationalUrls shape: {marketing?: string, privacy?: string, support?: string, termsOfService?: string}
# --keyCredentials item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, type?: string, usage?: string, value?: string}
# --oauth2Permissions item shape: {adminConsentDescription?: string, adminConsentDisplayName?: string, id?: string, isEnabled?: bool, type?: string, userConsentDescription?: string, userConsentDisplayName?: string, value?: string}
# --optionalClaims shape: {accessToken?: list, idToken?: list, samlToken?: list}
# --passwordCredentials item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, value?: string}
# --preAuthorizedApplications item shape: {appId?: string, extensions?: list, permissions?: list}
# --requiredResourceAccess item shape: {resourceAccess: list, resourceAppId?: string}
export def "applications Patch" [
  applicationObjectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  --displayName: string # The display name of the application.
  --identifierUris: list # A collection of URIs for the application.
  --allowGuestsSignIn: oneof<nothing, bool> # A property on the application to indicate if the application accepts other IDPs or not or partially accepts.
  --allowPassthroughUsers: oneof<nothing, bool> # Indicates that the application supports pass through users who have no presence in the resource tenant.
  --appLogoUrl: string # The url for the application logo image stored in a CDN.
  --appPermissions: list # The application permissions.
  --appRoles: list # The collection of application roles that an application may declare. These roles can be assigned to users, groups or service principals. — item shape: {allowedMemberTypes?: list, description?: string, displayName?: string, id?: string, isEnabled?: bool, value?: string}
  --availableToOtherTenants: oneof<nothing, bool> # Whether the application is available to other tenants.
  --errorUrl: string # A URL provided by the author of the application to report errors when using the application.
  --groupMembershipClaims: string@groupMembershipClaims-completer # Configures the groups claim issued in a user or OAuth 2.0 access token that the app expects.
  --homepage: string # The home page of the application.
  --informationalUrls: record # Represents a group of URIs that provide terms of service, marketing, support and privacy policy information about an application. The default value for each string is null. — shape: {marketing?: string, privacy?: string, support?: string, termsOfService?: string}
  --isDeviceOnlyAuthSupported: oneof<nothing, bool> # Specifies whether this application supports device authentication without a user. The default is false.
  --keyCredentials: list # A collection of KeyCredential objects. — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, type?: string, usage?: string, value?: string}
  --knownClientApplications: list # Client applications that are tied to this resource application. Consent to any of the known client applications will result in implicit consent to the resource application through a combined consent dialog (showing the OAuth permission scopes required by the client and the resource).
  --logoutUrl: string # the url of the logout page
  --oauth2AllowImplicitFlow: oneof<nothing, bool> # Whether to allow implicit grant flow for OAuth2
  --oauth2AllowUrlPathMatching: oneof<nothing, bool> # Specifies whether during a token Request Azure AD will allow path matching of the redirect URI against the applications collection of replyURLs. The default is false.
  --oauth2Permissions: list # The collection of OAuth 2.0 permission scopes that the web API (resource) application exposes to client applications. These permission scopes may be granted to client applications during consent. — item shape: {adminConsentDescription?: string, adminConsentDisplayName?: string, id?: string, isEnabled?: bool, type?: string, userConsentDescription?: string, userConsentDisplayName?: string, value?: string}
  --oauth2RequirePostResponse: oneof<nothing, bool> # Specifies whether, as part of OAuth 2.0 token requests, Azure AD will allow POST requests, as opposed to GET requests. The default is false, which specifies that only GET requests will be allowed.
  --optionalClaims: record # Specifying the claims to be included in the token. — shape: {accessToken?: list, idToken?: list, samlToken?: list}
  --orgRestrictions: list # A list of tenants allowed to access application.
  --passwordCredentials: list # A collection of PasswordCredential objects — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, value?: string}
  --preAuthorizedApplications: list # list of pre-authorized applications. — item shape: {appId?: string, extensions?: list, permissions?: list}
  --publicClient: oneof<nothing, bool> # Specifies whether this application is a public client (such as an installed application running on a mobile device). Default is false.
  --publisherDomain: string # Reliable domain which can be used to identify an application.
  --replyUrls: list # A collection of reply URLs for the application.
  --requiredResourceAccess: list # Specifies resources that this application requires access to and the set of OAuth permission scopes and application roles that it needs under each of those resources. This pre-configuration of required resource access drives the consent experience. — item shape: {resourceAccess: list, resourceAppId?: string}
  --samlMetadataUrl: string # The URL to the SAML metadata for the application.
  --signInAudience: string # Audience for signing in to the application (AzureADMyOrganization, AzureADAllOrganizations, AzureADAndMicrosoftAccounts).
  --wwwHomepage: string # The primary Web page.
]: any -> record<odata_error: record<code: string, message: record<value: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/applications/($applicationObjectId)" $qp)
  let body = {displayName: $displayName, identifierUris: $identifierUris, allowGuestsSignIn: $allowGuestsSignIn, allowPassthroughUsers: $allowPassthroughUsers, appLogoUrl: $appLogoUrl, appPermissions: $appPermissions, appRoles: $appRoles, availableToOtherTenants: $availableToOtherTenants, errorUrl: $errorUrl, groupMembershipClaims: $groupMembershipClaims, homepage: $homepage, informationalUrls: $informationalUrls, isDeviceOnlyAuthSupported: $isDeviceOnlyAuthSupported, keyCredentials: $keyCredentials, knownClientApplications: $knownClientApplications, logoutUrl: $logoutUrl, oauth2AllowImplicitFlow: $oauth2AllowImplicitFlow, oauth2AllowUrlPathMatching: $oauth2AllowUrlPathMatching, oauth2Permissions: $oauth2Permissions, oauth2RequirePostResponse: $oauth2RequirePostResponse, optionalClaims: $optionalClaims, orgRestrictions: $orgRestrictions, passwordCredentials: $passwordCredentials, preAuthorizedApplications: $preAuthorizedApplications, publicClient: $publicClient, publisherDomain: $publisherDomain, replyUrls: $replyUrls, requiredResourceAccess: $requiredResourceAccess, samlMetadataUrl: $samlMetadataUrl, signInAudience: $signInAudience, wwwHomepage: $wwwHomepage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add an owner to an application.
#
# POST /{tenantID}/applications/{applicationObjectId}/$links/owners
# operationId: Applications_AddOwner
export def "applications-links-owners AddOwner" [
  applicationObjectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  --body-url: string # A owner object URL, such as "https://graph.windows.net/0b1f9851-1bf0-433f-aec3-cb9272f093dc/directoryObjects/f260bbc4-c254-447b-94cf-293b5ec434dd", where "0b1f9851-1bf0-433f-aec3-cb9272f093dc" is the tenantId and "f260bbc4-c254-447b-94cf-293b5ec434dd" is the objectId of the owner (user, application, servicePrincipal, group) to be added.
]: any -> record<odata_error: record<code: string, message: record<value: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/applications/($applicationObjectId)/$links/owners" $qp)
  let body = {url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a member from owners.
#
# DELETE /{tenantID}/applications/{applicationObjectId}/$links/owners/{ownerObjectId}
# operationId: Applications_RemoveOwner
export def "applications-links-owners RemoveOwner" [
  applicationObjectId: string
  ownerObjectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_error: record<code: string, message: record<value: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/applications/($applicationObjectId)/$links/owners/($ownerObjectId)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the keyCredentials associated with an application.
#
# GET /{tenantID}/applications/{applicationObjectId}/keyCredentials
# operationId: Applications_ListKeyCredentials
export def "applications-key-credentials ListKeyCredentials" [
  applicationObjectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<value: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, type: string, usage: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/applications/($applicationObjectId)/keyCredentials" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the keyCredentials associated with an application.
#
# PATCH /{tenantID}/applications/{applicationObjectId}/keyCredentials
# operationId: Applications_UpdateKeyCredentials
# --value item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, type?: string, usage?: string, value?: string}
export def "applications-key-credentials UpdateKeyCredentials" [
  applicationObjectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  value: list # A collection of KeyCredentials. — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, type?: string, usage?: string, value?: string}
]: any -> record<odata_error: record<code: string, message: record<value: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/applications/($applicationObjectId)/keyCredentials" $qp)
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Directory objects that are owners of the application.
#
# GET /{tenantID}/applications/{applicationObjectId}/owners
# operationId: Applications_ListOwners
export def "applications-owners ListOwners" [
  applicationObjectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_nextLink: string, value: table<deletionTimestamp: string, objectId: string, objectType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/applications/($applicationObjectId)/owners" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the passwordCredentials associated with an application.
#
# GET /{tenantID}/applications/{applicationObjectId}/passwordCredentials
# operationId: Applications_ListPasswordCredentials
export def "applications-password-credentials ListPasswordCredentials" [
  applicationObjectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<value: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/applications/($applicationObjectId)/passwordCredentials" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update passwordCredentials associated with an application.
#
# PATCH /{tenantID}/applications/{applicationObjectId}/passwordCredentials
# operationId: Applications_UpdatePasswordCredentials
# --value item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, value?: string}
export def "applications-password-credentials UpdatePasswordCredentials" [
  applicationObjectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  value: list # A collection of PasswordCredentials. — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, value?: string}
]: any -> record<odata_error: record<code: string, message: record<value: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/applications/($applicationObjectId)/passwordCredentials" $qp)
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a list of deleted applications in the directory.
#
# GET /{tenantID}/deletedApplications
# operationId: DeletedApplications_List
export def "deleted-applications List" [
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --filter: string # The filter to apply to the operation.
  --api-version: string # Client API version.
]: nothing -> record<odata_nextLink: string, value: table<allowGuestsSignIn: bool, allowPassthroughUsers: bool, appId: string, appLogoUrl: string, appPermissions: list, appRoles: list, availableToOtherTenants: bool, displayName: string, errorUrl: string, groupMembershipClaims: string, homepage: string, identifierUris: list, informationalUrls: record, isDeviceOnlyAuthSupported: bool, keyCredentials: list, knownClientApplications: list, logoutUrl: string, oauth2AllowImplicitFlow: bool, oauth2AllowUrlPathMatching: bool, oauth2Permissions: list, oauth2RequirePostResponse: bool, optionalClaims: record, orgRestrictions: list, passwordCredentials: list, preAuthorizedApplications: list, publicClient: bool, publisherDomain: string, replyUrls: list, requiredResourceAccess: list, samlMetadataUrl: string, signInAudience: string, wwwHomepage: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/deletedApplications" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Hard-delete an application.
#
# DELETE /{tenantID}/deletedApplications/{applicationObjectId}
# operationId: DeletedApplications_HardDelete
export def "deleted-applications HardDelete" [
  applicationObjectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_error: record<code: string, message: record<value: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/deletedApplications/($applicationObjectId)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Restores the deleted application in the directory.
#
# POST /{tenantID}/deletedApplications/{objectId}/restore
# operationId: DeletedApplications_Restore
export def "deleted-applications-restore Restore" [
  objectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<allowGuestsSignIn: bool, allowPassthroughUsers: bool, appId: string, appLogoUrl: string, appPermissions: list<string>, appRoles: table<allowedMemberTypes: list, description: string, displayName: string, id: string, isEnabled: bool, value: string>, availableToOtherTenants: bool, displayName: string, errorUrl: string, groupMembershipClaims: string, homepage: string, identifierUris: list<string>, informationalUrls: record<marketing: string, privacy: string, support: string, termsOfService: string>, isDeviceOnlyAuthSupported: bool, keyCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, type: string, usage: string, value: string>, knownClientApplications: list<string>, logoutUrl: string, oauth2AllowImplicitFlow: bool, oauth2AllowUrlPathMatching: bool, oauth2Permissions: table<adminConsentDescription: string, adminConsentDisplayName: string, id: string, isEnabled: bool, type: string, userConsentDescription: string, userConsentDisplayName: string, value: string>, oauth2RequirePostResponse: bool, optionalClaims: record<accessToken: list<record>, idToken: list<record>, samlToken: list<record>>, orgRestrictions: list<string>, passwordCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, value: string>, preAuthorizedApplications: table<appId: string, extensions: list, permissions: list>, publicClient: bool, publisherDomain: string, replyUrls: list<string>, requiredResourceAccess: table<resourceAccess: list, resourceAppId: string>, samlMetadataUrl: string, signInAudience: string, wwwHomepage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/deletedApplications/($objectId)/restore" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of domains for the current tenant.
#
# GET /{tenantID}/domains
# operationId: Domains_List
export def "domains List" [
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --filter: string # The filter to apply to the operation.
  --api-version: string # Client API version.
]: nothing -> record<value: table<authenticationType: string, isDefault: bool, isVerified: bool, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/domains" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a specific domain in the current tenant.
#
# GET /{tenantID}/domains/{domainName}
# operationId: Domains_Get
export def "domains Get" [
  domainName: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<authenticationType: string, isDefault: bool, isVerified: bool, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/domains/($domainName)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the directory objects specified in a list of object IDs. You can also specify which resource collections (users, groups, etc.) should be searched by specifying the optional types parameter.
#
# POST /{tenantID}/getObjectsByObjectIds
# operationId: Objects_GetObjectsByObjectIds
export def "get-objects-by-object-ids GetObjectsByObjectIds" [
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  --includeDirectoryObjectReferences: oneof<nothing, bool> # If true, also searches for object IDs in the partner tenant.
  --objectIds: list # The requested object IDs.
  --types: list # The requested object types.
]: any -> record<odata_nextLink: string, value: table<deletionTimestamp: string, objectId: string, objectType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/getObjectsByObjectIds" $qp)
  let body = {includeDirectoryObjectReferences: $includeDirectoryObjectReferences, objectIds: $objectIds, types: $types} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets list of groups for the current tenant.
#
# GET /{tenantID}/groups
# operationId: Groups_List
export def "groups List" [
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --filter: string # The filter to apply to the operation.
  --api-version: string # Client API version.
]: nothing -> record<odata_nextLink: string, value: table<displayName: string, mail: string, mailEnabled: bool, mailNickname: string, securityEnabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/groups" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a group in the directory.
#
# POST /{tenantID}/groups
# operationId: Groups_Create
export def "groups Create" [
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  displayName: string # Group display name
  --mailEnabled: oneof<nothing, bool> # Whether the group is mail-enabled. Must be false. This is because only pure security groups can be created using the Graph API.
  mailNickname: string # Mail nickname
  --securityEnabled: oneof<nothing, bool> # Whether the group is a security group. Must be true. This is because only pure security groups can be created using the Graph API.
]: any -> record<displayName: string, mail: string, mailEnabled: bool, mailNickname: string, securityEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/groups" $qp)
  let body = {displayName: $displayName, mailEnabled: $mailEnabled, mailNickname: $mailNickname, securityEnabled: $securityEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add a member to a group.
#
# POST /{tenantID}/groups/{groupObjectId}/$links/members
# operationId: Groups_AddMember
export def "groups-links-members AddMember" [
  groupObjectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  --body-url: string # A member object URL, such as "https://graph.windows.net/0b1f9851-1bf0-433f-aec3-cb9272f093dc/directoryObjects/f260bbc4-c254-447b-94cf-293b5ec434dd", where "0b1f9851-1bf0-433f-aec3-cb9272f093dc" is the tenantId and "f260bbc4-c254-447b-94cf-293b5ec434dd" is the objectId of the member (user, application, servicePrincipal, group) to be added.
]: any -> record<odata_error: record<code: string, message: record<value: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/groups/($groupObjectId)/$links/members" $qp)
  let body = {url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a member from a group.
#
# DELETE /{tenantID}/groups/{groupObjectId}/$links/members/{memberObjectId}
# operationId: Groups_RemoveMember
export def "groups-links-members RemoveMember" [
  groupObjectId: string
  memberObjectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_error: record<code: string, message: record<value: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/groups/($groupObjectId)/$links/members/($memberObjectId)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a group from the directory.
#
# DELETE /{tenantID}/groups/{objectId}
# operationId: Groups_Delete
export def "groups Delete" [
  objectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_error: record<code: string, message: record<value: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/groups/($objectId)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets group information from the directory.
#
# GET /{tenantID}/groups/{objectId}
# operationId: Groups_Get
export def "groups Get" [
  objectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<displayName: string, mail: string, mailEnabled: bool, mailNickname: string, securityEnabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/groups/($objectId)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add an owner to a group.
#
# POST /{tenantID}/groups/{objectId}/$links/owners
# operationId: Groups_AddOwner
export def "groups-links-owners AddOwner" [
  objectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  --body-url: string # A owner object URL, such as "https://graph.windows.net/0b1f9851-1bf0-433f-aec3-cb9272f093dc/directoryObjects/f260bbc4-c254-447b-94cf-293b5ec434dd", where "0b1f9851-1bf0-433f-aec3-cb9272f093dc" is the tenantId and "f260bbc4-c254-447b-94cf-293b5ec434dd" is the objectId of the owner (user, application, servicePrincipal, group) to be added.
]: any -> record<odata_error: record<code: string, message: record<value: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/groups/($objectId)/$links/owners" $qp)
  let body = {url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a member from owners.
#
# DELETE /{tenantID}/groups/{objectId}/$links/owners/{ownerObjectId}
# operationId: Groups_RemoveOwner
export def "groups-links-owners RemoveOwner" [
  objectId: string
  ownerObjectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_error: record<code: string, message: record<value: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/groups/($objectId)/$links/owners/($ownerObjectId)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a collection of object IDs of groups of which the specified group is a member.
#
# POST /{tenantID}/groups/{objectId}/getMemberGroups
# operationId: Groups_GetMemberGroups
export def "groups-get-member-groups GetMemberGroups" [
  objectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  --securityEnabledOnly: oneof<nothing, bool> # If true, only membership in security-enabled groups should be checked. Otherwise, membership in all groups should be checked.
]: any -> record<value: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/groups/($objectId)/getMemberGroups" $qp)
  let body = {securityEnabledOnly: $securityEnabledOnly} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the members of a group.
#
# GET /{tenantID}/groups/{objectId}/members
# operationId: Groups_GetGroupMembers
export def "groups-members GetGroupMembers" [
  objectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_nextLink: string, value: table<deletionTimestamp: string, objectId: string, objectType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/groups/($objectId)/members" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Directory objects that are owners of the group.
#
# GET /{tenantID}/groups/{objectId}/owners
# operationId: Groups_ListOwners
export def "groups-owners ListOwners" [
  objectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_nextLink: string, value: table<deletionTimestamp: string, objectId: string, objectType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/groups/($objectId)/owners" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Checks whether the specified user, group, contact, or service principal is a direct or transitive member of the specified group.
#
# POST /{tenantID}/isMemberOf
# operationId: Groups_IsMemberOf
export def "is-member-of IsMemberOf" [
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  groupId: string # The object ID of the group to check.
  memberId: string # The object ID of the contact, group, user, or service principal to check for membership in the specified group.
]: any -> record<value: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/isMemberOf" $qp)
  let body = {groupId: $groupId, memberId: $memberId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the details for the currently logged-in user.
#
# GET /{tenantID}/me
# operationId: SignedInUser_Get
export def "me Get" [
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<accountEnabled: bool, displayName: string, givenName: string, immutableId: string, mail: string, mailNickname: string, signInNames: table<type: string, value: string>, surname: string, usageLocation: string, userPrincipalName: string, userType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/me" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the list of directory objects that are owned by the user.
#
# GET /{tenantID}/me/ownedObjects
# operationId: SignedInUser_ListOwnedObjects
export def "me-owned-objects ListOwnedObjects" [
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_nextLink: string, value: table<deletionTimestamp: string, objectId: string, objectType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/me/ownedObjects" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Queries OAuth2 permissions grants for the relevant SP ObjectId of an app.
#
# GET /{tenantID}/oauth2PermissionGrants
# operationId: OAuth2PermissionGrant_List
export def "oauth2-permission-grants List" [
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # This is the Service Principal ObjectId associated with the app (e.g. clientId+eq+'61ed44c3-5a1d-4639-a215-07f25129c6c3)
  --api-version: string # Client API version.
]: nothing -> record<odata_nextLink: string, value: table<clientId: string, consentType: string, expiryTime: string, objectId: string, odata_type: string, principalId: string, resourceId: string, scope: string, startTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/oauth2PermissionGrants" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Grants OAuth2 permissions for the relevant resource Ids of an app.
#
# POST /{tenantID}/oauth2PermissionGrants
# operationId: OAuth2PermissionGrant_Create
export def "oauth2-permission-grants Create" [
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client API version.
  --clientId: string # The id of the resource's service principal granted consent to impersonate the user when accessing the resource (represented by the resourceId property).
  --consentType: string@consentType-completer # Indicates if consent was provided by the administrator (on behalf of the organization) or by an individual.
  --expiryTime: string # Expiry time for TTL
  --objectId: string # The id of the permission grant
  --odatatype: string # Microsoft.DirectoryServices.OAuth2PermissionGrant
  --principalId: string # When consent type is Principal, this property specifies the id of the user that granted consent and applies only for that user.
  --resourceId: string # Object Id of the resource you want to grant
  --scope: string # Specifies the value of the scope claim that the resource application should expect in the OAuth 2.0 access token. For example, User.Read
  --startTime: string # Start time for TTL
]: any -> record<clientId: string, consentType: string, expiryTime: string, objectId: string, odata_type: string, principalId: string, resourceId: string, scope: string, startTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/oauth2PermissionGrants" $qp)
  let body = {clientId: $clientId, consentType: $consentType, expiryTime: $expiryTime, objectId: $objectId, odata.type: $odatatype, principalId: $principalId, resourceId: $resourceId, scope: $scope, startTime: $startTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a OAuth2 permission grant for the relevant resource Ids of an app.
#
# DELETE /{tenantID}/oauth2PermissionGrants/{objectId}
# operationId: OAuth2PermissionGrant_Delete
export def "oauth2-permission-grants Delete" [
  objectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_error: record<code: string, message: record<value: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/oauth2PermissionGrants/($objectId)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets a list of service principals from the current tenant.
#
# GET /{tenantID}/servicePrincipals
# operationId: ServicePrincipals_List
export def "service-principals List" [
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --filter: string # The filter to apply to the operation.
  --api-version: string # Client API version.
]: nothing -> record<odata_nextLink: string, value: table<accountEnabled: bool, alternativeNames: list, appDisplayName: string, appId: string, appOwnerTenantId: string, appRoleAssignmentRequired: bool, appRoles: list, displayName: string, errorUrl: string, homepage: string, keyCredentials: list, logoutUrl: string, oauth2Permissions: list, passwordCredentials: list, preferredTokenSigningKeyThumbprint: string, publisherName: string, replyUrls: list, samlMetadataUrl: string, servicePrincipalNames: list, servicePrincipalType: string, tags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/servicePrincipals" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a service principal in the directory.
#
# POST /{tenantID}/servicePrincipals
# operationId: ServicePrincipals_Create
# --keyCredentials item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, type?: string, usage?: string, value?: string}
# --passwordCredentials item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, value?: string}
export def "service-principals Create" [
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  appId: string # The application ID.
  --accountEnabled: oneof<nothing, bool> # whether or not the service principal account is enabled
  --appRoleAssignmentRequired: oneof<nothing, bool> # Specifies whether an AppRoleAssignment to a user or group is required before Azure AD will issue a user or access token to the application.
  --keyCredentials: list # The collection of key credentials associated with the service principal. — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, type?: string, usage?: string, value?: string}
  --passwordCredentials: list # The collection of password credentials associated with the service principal. — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, value?: string}
  --servicePrincipalType: string # the type of the service principal
  --tags: list # Optional list of tags that you can apply to your service principals. Not nullable.
]: any -> record<accountEnabled: bool, alternativeNames: list<string>, appDisplayName: string, appId: string, appOwnerTenantId: string, appRoleAssignmentRequired: bool, appRoles: table<allowedMemberTypes: list, description: string, displayName: string, id: string, isEnabled: bool, value: string>, displayName: string, errorUrl: string, homepage: string, keyCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, type: string, usage: string, value: string>, logoutUrl: string, oauth2Permissions: table<adminConsentDescription: string, adminConsentDisplayName: string, id: string, isEnabled: bool, type: string, userConsentDescription: string, userConsentDisplayName: string, value: string>, passwordCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, value: string>, preferredTokenSigningKeyThumbprint: string, publisherName: string, replyUrls: list<string>, samlMetadataUrl: string, servicePrincipalNames: list<string>, servicePrincipalType: string, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/servicePrincipals" $qp)
  let body = {appId: $appId, accountEnabled: $accountEnabled, appRoleAssignmentRequired: $appRoleAssignmentRequired, keyCredentials: $keyCredentials, passwordCredentials: $passwordCredentials, servicePrincipalType: $servicePrincipalType, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a service principal from the directory.
#
# DELETE /{tenantID}/servicePrincipals/{objectId}
# operationId: ServicePrincipals_Delete
export def "service-principals Delete" [
  objectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_error: record<code: string, message: record<value: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/servicePrincipals/($objectId)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets service principal information from the directory. Query by objectId or pass a filter to query by appId
#
# GET /{tenantID}/servicePrincipals/{objectId}
# operationId: ServicePrincipals_Get
export def "service-principals Get" [
  objectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<accountEnabled: bool, alternativeNames: list<string>, appDisplayName: string, appId: string, appOwnerTenantId: string, appRoleAssignmentRequired: bool, appRoles: table<allowedMemberTypes: list, description: string, displayName: string, id: string, isEnabled: bool, value: string>, displayName: string, errorUrl: string, homepage: string, keyCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, type: string, usage: string, value: string>, logoutUrl: string, oauth2Permissions: table<adminConsentDescription: string, adminConsentDisplayName: string, id: string, isEnabled: bool, type: string, userConsentDescription: string, userConsentDisplayName: string, value: string>, passwordCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, value: string>, preferredTokenSigningKeyThumbprint: string, publisherName: string, replyUrls: list<string>, samlMetadataUrl: string, servicePrincipalNames: list<string>, servicePrincipalType: string, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/servicePrincipals/($objectId)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a service principal in the directory.
#
# PATCH /{tenantID}/servicePrincipals/{objectId}
# operationId: ServicePrincipals_Update
# --keyCredentials item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, type?: string, usage?: string, value?: string}
# --passwordCredentials item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, value?: string}
export def "service-principals Update" [
  objectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  --accountEnabled: oneof<nothing, bool> # whether or not the service principal account is enabled
  --appRoleAssignmentRequired: oneof<nothing, bool> # Specifies whether an AppRoleAssignment to a user or group is required before Azure AD will issue a user or access token to the application.
  --keyCredentials: list # The collection of key credentials associated with the service principal. — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, type?: string, usage?: string, value?: string}
  --passwordCredentials: list # The collection of password credentials associated with the service principal. — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, value?: string}
  --servicePrincipalType: string # the type of the service principal
  --tags: list # Optional list of tags that you can apply to your service principals. Not nullable.
]: any -> record<odata_error: record<code: string, message: record<value: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/servicePrincipals/($objectId)" $qp)
  let body = {accountEnabled: $accountEnabled, appRoleAssignmentRequired: $appRoleAssignmentRequired, keyCredentials: $keyCredentials, passwordCredentials: $passwordCredentials, servicePrincipalType: $servicePrincipalType, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add an owner to a service principal.
#
# POST /{tenantID}/servicePrincipals/{objectId}/$links/owners
# operationId: ServicePrincipals_AddOwner
export def "service-principals-links-owners AddOwner" [
  objectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  --body-url: string # A owner object URL, such as "https://graph.windows.net/0b1f9851-1bf0-433f-aec3-cb9272f093dc/directoryObjects/f260bbc4-c254-447b-94cf-293b5ec434dd", where "0b1f9851-1bf0-433f-aec3-cb9272f093dc" is the tenantId and "f260bbc4-c254-447b-94cf-293b5ec434dd" is the objectId of the owner (user, application, servicePrincipal, group) to be added.
]: any -> record<odata_error: record<code: string, message: record<value: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/servicePrincipals/($objectId)/$links/owners" $qp)
  let body = {url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Remove a member from owners.
#
# DELETE /{tenantID}/servicePrincipals/{objectId}/$links/owners/{ownerObjectId}
# operationId: ServicePrincipals_RemoveOwner
export def "service-principals-links-owners RemoveOwner" [
  objectId: string
  ownerObjectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_error: record<code: string, message: record<value: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/servicePrincipals/($objectId)/$links/owners/($ownerObjectId)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Principals (users, groups, and service principals) that are assigned to this service principal.
#
# GET /{tenantID}/servicePrincipals/{objectId}/appRoleAssignedTo
# operationId: ServicePrincipals_ListAppRoleAssignedTo
export def "service-principals-app-role-assigned-to ListAppRoleAssignedTo" [
  objectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_nextLink: string, value: table<id: string, principalDisplayName: string, principalId: string, principalType: string, resourceDisplayName: string, resourceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/servicePrincipals/($objectId)/appRoleAssignedTo" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Applications that the service principal is assigned to.
#
# GET /{tenantID}/servicePrincipals/{objectId}/appRoleAssignments
# operationId: ServicePrincipals_ListAppRoleAssignments
export def "service-principals-app-role-assignments ListAppRoleAssignments" [
  objectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_nextLink: string, value: table<id: string, principalDisplayName: string, principalId: string, principalType: string, resourceDisplayName: string, resourceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/servicePrincipals/($objectId)/appRoleAssignments" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the keyCredentials associated with the specified service principal.
#
# GET /{tenantID}/servicePrincipals/{objectId}/keyCredentials
# operationId: ServicePrincipals_ListKeyCredentials
export def "service-principals-key-credentials ListKeyCredentials" [
  objectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<value: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, type: string, usage: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/servicePrincipals/($objectId)/keyCredentials" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the keyCredentials associated with a service principal.
#
# PATCH /{tenantID}/servicePrincipals/{objectId}/keyCredentials
# operationId: ServicePrincipals_UpdateKeyCredentials
# --value item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, type?: string, usage?: string, value?: string}
export def "service-principals-key-credentials UpdateKeyCredentials" [
  objectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  value: list # A collection of KeyCredentials. — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, type?: string, usage?: string, value?: string}
]: any -> record<odata_error: record<code: string, message: record<value: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/servicePrincipals/($objectId)/keyCredentials" $qp)
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Directory objects that are owners of this service principal.
#
# GET /{tenantID}/servicePrincipals/{objectId}/owners
# operationId: ServicePrincipals_ListOwners
export def "service-principals-owners ListOwners" [
  objectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_nextLink: string, value: table<deletionTimestamp: string, objectId: string, objectType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/servicePrincipals/($objectId)/owners" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the passwordCredentials associated with a service principal.
#
# GET /{tenantID}/servicePrincipals/{objectId}/passwordCredentials
# operationId: ServicePrincipals_ListPasswordCredentials
export def "service-principals-password-credentials ListPasswordCredentials" [
  objectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<value: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/servicePrincipals/($objectId)/passwordCredentials" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the passwordCredentials associated with a service principal.
#
# PATCH /{tenantID}/servicePrincipals/{objectId}/passwordCredentials
# operationId: ServicePrincipals_UpdatePasswordCredentials
# --value item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, value?: string}
export def "service-principals-password-credentials UpdatePasswordCredentials" [
  objectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  value: list # A collection of PasswordCredentials. — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, value?: string}
]: any -> record<odata_error: record<code: string, message: record<value: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/servicePrincipals/($objectId)/passwordCredentials" $qp)
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets an object id for a given application id from the current tenant.
#
# GET /{tenantID}/servicePrincipalsByAppId/{applicationID}/objectId
# operationId: Applications_GetServicePrincipalsIdByAppId
export def "service-principals-by-app-id-object-id GetServicePrincipalsIdByAppId" [
  tenantID: string
  applicationID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_metadata: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/servicePrincipalsByAppId/($applicationID)/objectId" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets list of users for the current tenant.
#
# GET /{tenantID}/users
# operationId: Users_List
export def "users List" [
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --filter: string # The filter to apply to the operation.
  --expand: string # The expand value for the operation result.
  --top: int # (Optional) Set the maximum number of results per response. (default: 100)
  --api-version: string # Client API version.
]: nothing -> record<odata_nextLink: string, value: table<accountEnabled: bool, displayName: string, givenName: string, immutableId: string, mail: string, mailNickname: string, signInNames: list, surname: string, usageLocation: string, userPrincipalName: string, userType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$expand" $expand "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/users" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new user.
#
# POST /{tenantID}/users
# operationId: Users_Create
# --passwordProfile shape: {forceChangePasswordNextLogin?: bool, password: string}
export def "users Create" [
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  --accountEnabled: oneof<nothing, bool> # Whether the account is enabled.
  displayName: string # The display name of the user.
  --mail: string # The primary email address of the user.
  mailNickname: string # The mail alias for the user.
  passwordProfile: record # The password profile associated with a user. — shape: {forceChangePasswordNextLogin?: bool, password: string}
  userPrincipalName: string # The user principal name (someuser@contoso.com). It must contain one of the verified domains for the tenant.
  --givenName: string # The given name for the user.
  --immutableId: string # This must be specified if you are using a federated domain for the user's userPrincipalName (UPN) property when creating a new user account. It is used to associate an on-premises Active Directory user account with their Azure AD user object.
  --surname: string # The user's surname (family name or last name).
  --usageLocation: string # A two letter country code (ISO standard 3166). Required for users that will be assigned licenses due to legal requirement to check for availability of services in countries. Examples include: "US", "JP", and "GB".
  --userType: string@userType-completer # A string value that can be used to classify user types in your directory, such as 'Member' and 'Guest'.
]: any -> record<accountEnabled: bool, displayName: string, givenName: string, immutableId: string, mail: string, mailNickname: string, signInNames: table<type: string, value: string>, surname: string, usageLocation: string, userPrincipalName: string, userType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/users" $qp)
  let body = {accountEnabled: $accountEnabled, displayName: $displayName, mail: $mail, mailNickname: $mailNickname, passwordProfile: $passwordProfile, userPrincipalName: $userPrincipalName, givenName: $givenName, immutableId: $immutableId, surname: $surname, usageLocation: $usageLocation, userType: $userType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets a collection that contains the object IDs of the groups of which the user is a member.
#
# POST /{tenantID}/users/{objectId}/getMemberGroups
# operationId: Users_GetMemberGroups
export def "users-get-member-groups GetMemberGroups" [
  objectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  --securityEnabledOnly: oneof<nothing, bool> # If true, only membership in security-enabled groups should be checked. Otherwise, membership in all groups should be checked.
]: any -> record<value: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/users/($objectId)/getMemberGroups" $qp)
  let body = {securityEnabledOnly: $securityEnabledOnly} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a user.
#
# DELETE /{tenantID}/users/{upnOrObjectId}
# operationId: Users_Delete
export def "users Delete" [
  upnOrObjectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_error: record<code: string, message: record<value: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/users/($upnOrObjectId)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets user information from the directory.
#
# GET /{tenantID}/users/{upnOrObjectId}
# operationId: Users_Get
export def "users Get" [
  upnOrObjectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<accountEnabled: bool, displayName: string, givenName: string, immutableId: string, mail: string, mailNickname: string, signInNames: table<type: string, value: string>, surname: string, usageLocation: string, userPrincipalName: string, userType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/users/($upnOrObjectId)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a user.
#
# PATCH /{tenantID}/users/{upnOrObjectId}
# operationId: Users_Update
# --passwordProfile shape: {forceChangePasswordNextLogin?: bool, password: string}
export def "users Update" [
  upnOrObjectId: string
  tenantID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  --accountEnabled: oneof<nothing, bool> # Whether the account is enabled.
  --displayName: string # The display name of the user.
  --mail: string # The primary email address of the user.
  --mailNickname: string # The mail alias for the user.
  --passwordProfile: record # The password profile associated with a user. — shape: {forceChangePasswordNextLogin?: bool, password: string}
  --userPrincipalName: string # The user principal name (someuser@contoso.com). It must contain one of the verified domains for the tenant.
  --givenName: string # The given name for the user.
  --immutableId: string # This must be specified if you are using a federated domain for the user's userPrincipalName (UPN) property when creating a new user account. It is used to associate an on-premises Active Directory user account with their Azure AD user object.
  --surname: string # The user's surname (family name or last name).
  --usageLocation: string # A two letter country code (ISO standard 3166). Required for users that will be assigned licenses due to legal requirement to check for availability of services in countries. Examples include: "US", "JP", and "GB".
  --userType: string@userType-completer # A string value that can be used to classify user types in your directory, such as 'Member' and 'Guest'.
]: any -> record<odata_error: record<code: string, message: record<value: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($tenantID)/users/($upnOrObjectId)" $qp)
  let body = {accountEnabled: $accountEnabled, displayName: $displayName, mail: $mail, mailNickname: $mailNickname, passwordProfile: $passwordProfile, userPrincipalName: $userPrincipalName, givenName: $givenName, immutableId: $immutableId, surname: $surname, usageLocation: $usageLocation, userType: $userType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
