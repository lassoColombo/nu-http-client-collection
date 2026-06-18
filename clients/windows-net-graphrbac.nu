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
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://graph.windows.net"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "text/json"] }
def group-membership-claims-completer [] { ["All" "None" "SecurityGroup"] }
def mail-enabled-completer [] { ["false"] }
def security-enabled-completer [] { ["true"] }
def consent-type-completer [] { ["AllPrincipals" "Principal"] }
def user-type-completer [] { ["Guest" "Member"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "applications list" } } | get name | first)
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
export def "applications list" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --filter: string # The filters to apply to the operation.
  --api-version: string # Client API version.
]: nothing -> record<odata_nextLink: string, value: table<allowGuestsSignIn: bool, allowPassthroughUsers: bool, appId: string, appLogoUrl: string, appPermissions: list, appRoles: list, availableToOtherTenants: bool, displayName: string, errorUrl: string, groupMembershipClaims: string, homepage: string, identifierUris: list, informationalUrls: record, isDeviceOnlyAuthSupported: bool, keyCredentials: list, knownClientApplications: list, logoutUrl: string, oauth2AllowImplicitFlow: bool, oauth2AllowUrlPathMatching: bool, oauth2Permissions: list, oauth2RequirePostResponse: bool, optionalClaims: record, orgRestrictions: list, passwordCredentials: list, preAuthorizedApplications: list, publicClient: bool, publisherDomain: string, replyUrls: list, requiredResourceAccess: list, samlMetadataUrl: string, signInAudience: string, wwwHomepage: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id)} | format pattern "/{tenant_id}/applications") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create a new application.
#
# POST /{tenantID}/applications
# operationId: Applications_Create
# --appRoles item shape: {allowedMemberTypes?: list<string>, description?: string, displayName?: string, id?: string, isEnabled?: bool, value?: string}
# --informationalUrls shape: {marketing?: string, privacy?: string, support?: string, termsOfService?: string}
# --keyCredentials item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, type?: string, usage?: string, value?: string}
# --oauth2Permissions item shape: {adminConsentDescription?: string, adminConsentDisplayName?: string, id?: string, isEnabled?: bool, type?: string, userConsentDescription?: string, userConsentDisplayName?: string, value?: string}
# --optionalClaims shape: {accessToken?: list, idToken?: list, samlToken?: list}
# --passwordCredentials item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, value?: string}
# --preAuthorizedApplications item shape: {appId?: string, extensions?: list, permissions?: list}
# --requiredResourceAccess item shape: {resourceAccess: list, resourceAppId?: string}
export def "applications create" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  display_name: string # The display name of the application.
  --identifier-uris: list<string> # A collection of URIs for the application.
  --allow-guests-sign-in: oneof<nothing, bool> # A property on the application to indicate if the application accepts other IDPs or not or partially accepts.
  --allow-passthrough-users: oneof<nothing, bool> # Indicates that the application supports pass through users who have no presence in the resource tenant.
  --app-logo-url: string # The url for the application logo image stored in a CDN.
  --app-permissions: list<string> # The application permissions.
  --app-roles: list # The collection of application roles that an application may declare. These roles can be assigned to users, groups or service principals. — item shape: {allowedMemberTypes?: list<string>, description?: string, displayName?: string, id?: string, isEnabled?: bool, value?: string}
  --available-to-other-tenants: oneof<nothing, bool> # Whether the application is available to other tenants.
  --error-url: string # A URL provided by the author of the application to report errors when using the application.
  --group-membership-claims: string@group-membership-claims-completer # Configures the groups claim issued in a user or OAuth 2.0 access token that the app expects.
  --homepage: string # The home page of the application.
  --informational-urls: record # Represents a group of URIs that provide terms of service, marketing, support and privacy policy information about an application. The default value for each string is null. — shape: {marketing?: string, privacy?: string, support?: string, termsOfService?: string}
  --is-device-only-auth-supported: oneof<nothing, bool> # Specifies whether this application supports device authentication without a user. The default is false.
  --key-credentials: list # A collection of KeyCredential objects. — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, type?: string, usage?: string, value?: string}
  --known-client-applications: list<string> # Client applications that are tied to this resource application. Consent to any of the known client applications will result in implicit consent to the resource application through a combined consent dialog (showing the OAuth permission scopes required by the client and the resource).
  --logout-url: string # the url of the logout page
  --oauth2-allow-implicit-flow: oneof<nothing, bool> # Whether to allow implicit grant flow for OAuth2
  --oauth2-allow-url-path-matching: oneof<nothing, bool> # Specifies whether during a token Request Azure AD will allow path matching of the redirect URI against the applications collection of replyURLs. The default is false.
  --oauth2-permissions: list # The collection of OAuth 2.0 permission scopes that the web API (resource) application exposes to client applications. These permission scopes may be granted to client applications during consent. — item shape: {adminConsentDescription?: string, adminConsentDisplayName?: string, id?: string, isEnabled?: bool, type?: string, userConsentDescription?: string, userConsentDisplayName?: string, value?: string}
  --oauth2-require-post-response: oneof<nothing, bool> # Specifies whether, as part of OAuth 2.0 token requests, Azure AD will allow POST requests, as opposed to GET requests. The default is false, which specifies that only GET requests will be allowed.
  --optional-claims: record # Specifying the claims to be included in the token. — shape: {accessToken?: list, idToken?: list, samlToken?: list}
  --org-restrictions: list<string> # A list of tenants allowed to access application.
  --password-credentials: list # A collection of PasswordCredential objects — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, value?: string}
  --pre-authorized-applications: list # list of pre-authorized applications. — item shape: {appId?: string, extensions?: list, permissions?: list}
  --public-client: oneof<nothing, bool> # Specifies whether this application is a public client (such as an installed application running on a mobile device). Default is false.
  --publisher-domain: string # Reliable domain which can be used to identify an application.
  --reply-urls: list<string> # A collection of reply URLs for the application.
  --required-resource-access: list # Specifies resources that this application requires access to and the set of OAuth permission scopes and application roles that it needs under each of those resources. This pre-configuration of required resource access drives the consent experience. — item shape: {resourceAccess: list, resourceAppId?: string}
  --saml-metadata-url: string # The URL to the SAML metadata for the application.
  --sign-in-audience: string # Audience for signing in to the application (AzureADMyOrganization, AzureADAllOrganizations, AzureADAndMicrosoftAccounts).
  --www-homepage: string # The primary Web page.
]: any -> record<allowGuestsSignIn: bool, allowPassthroughUsers: bool, appId: string, appLogoUrl: string, appPermissions: list<string>, appRoles: table<allowedMemberTypes: list, description: string, displayName: string, id: string, isEnabled: bool, value: string>, availableToOtherTenants: bool, displayName: string, errorUrl: string, groupMembershipClaims: string, homepage: string, identifierUris: list<string>, informationalUrls: record<marketing: string, privacy: string, support: string, termsOfService: string>, isDeviceOnlyAuthSupported: bool, keyCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, type: string, usage: string, value: string>, knownClientApplications: list<string>, logoutUrl: string, oauth2AllowImplicitFlow: bool, oauth2AllowUrlPathMatching: bool, oauth2Permissions: table<adminConsentDescription: string, adminConsentDisplayName: string, id: string, isEnabled: bool, type: string, userConsentDescription: string, userConsentDisplayName: string, value: string>, oauth2RequirePostResponse: bool, optionalClaims: record<accessToken: list<record>, idToken: list<record>, samlToken: list<record>>, orgRestrictions: list<string>, passwordCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, value: string>, preAuthorizedApplications: table<appId: string, extensions: list, permissions: list>, publicClient: bool, publisherDomain: string, replyUrls: list<string>, requiredResourceAccess: table<resourceAccess: list, resourceAppId: string>, samlMetadataUrl: string, signInAudience: string, wwwHomepage: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id)} | format pattern "/{tenant_id}/applications") $qp)
  let req_body = {"displayName": $display_name, "identifierUris": $identifier_uris, "allowGuestsSignIn": $allow_guests_sign_in, "allowPassthroughUsers": $allow_passthrough_users, "appLogoUrl": $app_logo_url, "appPermissions": $app_permissions, "appRoles": $app_roles, "availableToOtherTenants": $available_to_other_tenants, "errorUrl": $error_url, "groupMembershipClaims": $group_membership_claims, "homepage": $homepage, "informationalUrls": $informational_urls, "isDeviceOnlyAuthSupported": $is_device_only_auth_supported, "keyCredentials": $key_credentials, "knownClientApplications": $known_client_applications, "logoutUrl": $logout_url, "oauth2AllowImplicitFlow": $oauth2_allow_implicit_flow, "oauth2AllowUrlPathMatching": $oauth2_allow_url_path_matching, "oauth2Permissions": $oauth2_permissions, "oauth2RequirePostResponse": $oauth2_require_post_response, "optionalClaims": $optional_claims, "orgRestrictions": $org_restrictions, "passwordCredentials": $password_credentials, "preAuthorizedApplications": $pre_authorized_applications, "publicClient": $public_client, "publisherDomain": $publisher_domain, "replyUrls": $reply_urls, "requiredResourceAccess": $required_resource_access, "samlMetadataUrl": $saml_metadata_url, "signInAudience": $sign_in_audience, "wwwHomepage": $www_homepage} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete an application.
#
# DELETE /{tenantID}/applications/{applicationObjectId}
# operationId: Applications_Delete
export def "applications delete" [
  tenant_id: string
  application_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_error: record<code: string, message: record<value: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), application_object_id: (encode-path-segment $application_object_id)} | format pattern "/{tenant_id}/applications/{application_object_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get an application by object ID.
#
# GET /{tenantID}/applications/{applicationObjectId}
# operationId: Applications_Get
export def "applications get" [
  tenant_id: string
  application_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<allowGuestsSignIn: bool, allowPassthroughUsers: bool, appId: string, appLogoUrl: string, appPermissions: list<string>, appRoles: table<allowedMemberTypes: list, description: string, displayName: string, id: string, isEnabled: bool, value: string>, availableToOtherTenants: bool, displayName: string, errorUrl: string, groupMembershipClaims: string, homepage: string, identifierUris: list<string>, informationalUrls: record<marketing: string, privacy: string, support: string, termsOfService: string>, isDeviceOnlyAuthSupported: bool, keyCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, type: string, usage: string, value: string>, knownClientApplications: list<string>, logoutUrl: string, oauth2AllowImplicitFlow: bool, oauth2AllowUrlPathMatching: bool, oauth2Permissions: table<adminConsentDescription: string, adminConsentDisplayName: string, id: string, isEnabled: bool, type: string, userConsentDescription: string, userConsentDisplayName: string, value: string>, oauth2RequirePostResponse: bool, optionalClaims: record<accessToken: list<record>, idToken: list<record>, samlToken: list<record>>, orgRestrictions: list<string>, passwordCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, value: string>, preAuthorizedApplications: table<appId: string, extensions: list, permissions: list>, publicClient: bool, publisherDomain: string, replyUrls: list<string>, requiredResourceAccess: table<resourceAccess: list, resourceAppId: string>, samlMetadataUrl: string, signInAudience: string, wwwHomepage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), application_object_id: (encode-path-segment $application_object_id)} | format pattern "/{tenant_id}/applications/{application_object_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update an existing application.
#
# PATCH /{tenantID}/applications/{applicationObjectId}
# operationId: Applications_Patch
# --appRoles item shape: {allowedMemberTypes?: list<string>, description?: string, displayName?: string, id?: string, isEnabled?: bool, value?: string}
# --informationalUrls shape: {marketing?: string, privacy?: string, support?: string, termsOfService?: string}
# --keyCredentials item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, type?: string, usage?: string, value?: string}
# --oauth2Permissions item shape: {adminConsentDescription?: string, adminConsentDisplayName?: string, id?: string, isEnabled?: bool, type?: string, userConsentDescription?: string, userConsentDisplayName?: string, value?: string}
# --optionalClaims shape: {accessToken?: list, idToken?: list, samlToken?: list}
# --passwordCredentials item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, value?: string}
# --preAuthorizedApplications item shape: {appId?: string, extensions?: list, permissions?: list}
# --requiredResourceAccess item shape: {resourceAccess: list, resourceAppId?: string}
export def "applications update" [
  tenant_id: string
  application_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  --display-name: string # The display name of the application.
  --identifier-uris: list<string> # A collection of URIs for the application.
  --allow-guests-sign-in: oneof<nothing, bool> # A property on the application to indicate if the application accepts other IDPs or not or partially accepts.
  --allow-passthrough-users: oneof<nothing, bool> # Indicates that the application supports pass through users who have no presence in the resource tenant.
  --app-logo-url: string # The url for the application logo image stored in a CDN.
  --app-permissions: list<string> # The application permissions.
  --app-roles: list # The collection of application roles that an application may declare. These roles can be assigned to users, groups or service principals. — item shape: {allowedMemberTypes?: list<string>, description?: string, displayName?: string, id?: string, isEnabled?: bool, value?: string}
  --available-to-other-tenants: oneof<nothing, bool> # Whether the application is available to other tenants.
  --error-url: string # A URL provided by the author of the application to report errors when using the application.
  --group-membership-claims: string@group-membership-claims-completer # Configures the groups claim issued in a user or OAuth 2.0 access token that the app expects.
  --homepage: string # The home page of the application.
  --informational-urls: record # Represents a group of URIs that provide terms of service, marketing, support and privacy policy information about an application. The default value for each string is null. — shape: {marketing?: string, privacy?: string, support?: string, termsOfService?: string}
  --is-device-only-auth-supported: oneof<nothing, bool> # Specifies whether this application supports device authentication without a user. The default is false.
  --key-credentials: list # A collection of KeyCredential objects. — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, type?: string, usage?: string, value?: string}
  --known-client-applications: list<string> # Client applications that are tied to this resource application. Consent to any of the known client applications will result in implicit consent to the resource application through a combined consent dialog (showing the OAuth permission scopes required by the client and the resource).
  --logout-url: string # the url of the logout page
  --oauth2-allow-implicit-flow: oneof<nothing, bool> # Whether to allow implicit grant flow for OAuth2
  --oauth2-allow-url-path-matching: oneof<nothing, bool> # Specifies whether during a token Request Azure AD will allow path matching of the redirect URI against the applications collection of replyURLs. The default is false.
  --oauth2-permissions: list # The collection of OAuth 2.0 permission scopes that the web API (resource) application exposes to client applications. These permission scopes may be granted to client applications during consent. — item shape: {adminConsentDescription?: string, adminConsentDisplayName?: string, id?: string, isEnabled?: bool, type?: string, userConsentDescription?: string, userConsentDisplayName?: string, value?: string}
  --oauth2-require-post-response: oneof<nothing, bool> # Specifies whether, as part of OAuth 2.0 token requests, Azure AD will allow POST requests, as opposed to GET requests. The default is false, which specifies that only GET requests will be allowed.
  --optional-claims: record # Specifying the claims to be included in the token. — shape: {accessToken?: list, idToken?: list, samlToken?: list}
  --org-restrictions: list<string> # A list of tenants allowed to access application.
  --password-credentials: list # A collection of PasswordCredential objects — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, value?: string}
  --pre-authorized-applications: list # list of pre-authorized applications. — item shape: {appId?: string, extensions?: list, permissions?: list}
  --public-client: oneof<nothing, bool> # Specifies whether this application is a public client (such as an installed application running on a mobile device). Default is false.
  --publisher-domain: string # Reliable domain which can be used to identify an application.
  --reply-urls: list<string> # A collection of reply URLs for the application.
  --required-resource-access: list # Specifies resources that this application requires access to and the set of OAuth permission scopes and application roles that it needs under each of those resources. This pre-configuration of required resource access drives the consent experience. — item shape: {resourceAccess: list, resourceAppId?: string}
  --saml-metadata-url: string # The URL to the SAML metadata for the application.
  --sign-in-audience: string # Audience for signing in to the application (AzureADMyOrganization, AzureADAllOrganizations, AzureADAndMicrosoftAccounts).
  --www-homepage: string # The primary Web page.
]: any -> record<odata_error: record<code: string, message: record<value: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), application_object_id: (encode-path-segment $application_object_id)} | format pattern "/{tenant_id}/applications/{application_object_id}") $qp)
  let req_body = {"displayName": $display_name, "identifierUris": $identifier_uris, "allowGuestsSignIn": $allow_guests_sign_in, "allowPassthroughUsers": $allow_passthrough_users, "appLogoUrl": $app_logo_url, "appPermissions": $app_permissions, "appRoles": $app_roles, "availableToOtherTenants": $available_to_other_tenants, "errorUrl": $error_url, "groupMembershipClaims": $group_membership_claims, "homepage": $homepage, "informationalUrls": $informational_urls, "isDeviceOnlyAuthSupported": $is_device_only_auth_supported, "keyCredentials": $key_credentials, "knownClientApplications": $known_client_applications, "logoutUrl": $logout_url, "oauth2AllowImplicitFlow": $oauth2_allow_implicit_flow, "oauth2AllowUrlPathMatching": $oauth2_allow_url_path_matching, "oauth2Permissions": $oauth2_permissions, "oauth2RequirePostResponse": $oauth2_require_post_response, "optionalClaims": $optional_claims, "orgRestrictions": $org_restrictions, "passwordCredentials": $password_credentials, "preAuthorizedApplications": $pre_authorized_applications, "publicClient": $public_client, "publisherDomain": $publisher_domain, "replyUrls": $reply_urls, "requiredResourceAccess": $required_resource_access, "samlMetadataUrl": $saml_metadata_url, "signInAudience": $sign_in_audience, "wwwHomepage": $www_homepage} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Add an owner to an application.
#
# POST /{tenantID}/applications/{applicationObjectId}/$links/owners
# operationId: Applications_AddOwner
export def "applications-links-owners create" [
  tenant_id: string
  application_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  url: string # A owner object URL, such as "https://graph.windows.net/0b1f9851-1bf0-433f-aec3-cb9272f093dc/directoryObjects/f260bbc4-c254-447b-94cf-293b5ec434dd", where "0b1f9851-1bf0-433f-aec3-cb9272f093dc" is the tenantId and "f260bbc4-c254-447b-94cf-293b5ec434dd" is the objectId of the owner (user, application, servicePrincipal, group) to be added.
]: any -> record<odata_error: record<code: string, message: record<value: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), application_object_id: (encode-path-segment $application_object_id)} | format pattern "/{tenant_id}/applications/{application_object_id}/$links/owners") $qp)
  let req_body = {"url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Remove a member from owners.
#
# DELETE /{tenantID}/applications/{applicationObjectId}/$links/owners/{ownerObjectId}
# operationId: Applications_RemoveOwner
export def "applications-links-owners delete" [
  tenant_id: string
  application_object_id: string
  owner_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_error: record<code: string, message: record<value: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), application_object_id: (encode-path-segment $application_object_id), owner_object_id: (encode-path-segment $owner_object_id)} | format pattern "/{tenant_id}/applications/{application_object_id}/$links/owners/{owner_object_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the keyCredentials associated with an application.
#
# GET /{tenantID}/applications/{applicationObjectId}/keyCredentials
# operationId: Applications_ListKeyCredentials
export def "applications-key-credentials list" [
  tenant_id: string
  application_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<value: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, type: string, usage: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), application_object_id: (encode-path-segment $application_object_id)} | format pattern "/{tenant_id}/applications/{application_object_id}/keyCredentials") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update the keyCredentials associated with an application.
#
# PATCH /{tenantID}/applications/{applicationObjectId}/keyCredentials
# operationId: Applications_UpdateKeyCredentials
# --value item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, type?: string, usage?: string, value?: string}
export def "applications-key-credentials update" [
  tenant_id: string
  application_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  value: list # A collection of KeyCredentials. — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, type?: string, usage?: string, value?: string}
]: any -> record<odata_error: record<code: string, message: record<value: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), application_object_id: (encode-path-segment $application_object_id)} | format pattern "/{tenant_id}/applications/{application_object_id}/keyCredentials") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Directory objects that are owners of the application.
#
# GET /{tenantID}/applications/{applicationObjectId}/owners
# operationId: Applications_ListOwners
export def "applications-owners list" [
  tenant_id: string
  application_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_nextLink: string, value: table<deletionTimestamp: string, objectId: string, objectType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), application_object_id: (encode-path-segment $application_object_id)} | format pattern "/{tenant_id}/applications/{application_object_id}/owners") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the passwordCredentials associated with an application.
#
# GET /{tenantID}/applications/{applicationObjectId}/passwordCredentials
# operationId: Applications_ListPasswordCredentials
export def "applications-password-credentials list" [
  tenant_id: string
  application_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<value: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), application_object_id: (encode-path-segment $application_object_id)} | format pattern "/{tenant_id}/applications/{application_object_id}/passwordCredentials") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update passwordCredentials associated with an application.
#
# PATCH /{tenantID}/applications/{applicationObjectId}/passwordCredentials
# operationId: Applications_UpdatePasswordCredentials
# --value item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, value?: string}
export def "applications-password-credentials update" [
  tenant_id: string
  application_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  value: list # A collection of PasswordCredentials. — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, value?: string}
]: any -> record<odata_error: record<code: string, message: record<value: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), application_object_id: (encode-path-segment $application_object_id)} | format pattern "/{tenant_id}/applications/{application_object_id}/passwordCredentials") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets a list of deleted applications in the directory.
#
# GET /{tenantID}/deletedApplications
# operationId: DeletedApplications_List
export def "deleted-applications list" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --filter: string # The filter to apply to the operation.
  --api-version: string # Client API version.
]: nothing -> record<odata_nextLink: string, value: table<allowGuestsSignIn: bool, allowPassthroughUsers: bool, appId: string, appLogoUrl: string, appPermissions: list, appRoles: list, availableToOtherTenants: bool, displayName: string, errorUrl: string, groupMembershipClaims: string, homepage: string, identifierUris: list, informationalUrls: record, isDeviceOnlyAuthSupported: bool, keyCredentials: list, knownClientApplications: list, logoutUrl: string, oauth2AllowImplicitFlow: bool, oauth2AllowUrlPathMatching: bool, oauth2Permissions: list, oauth2RequirePostResponse: bool, optionalClaims: record, orgRestrictions: list, passwordCredentials: list, preAuthorizedApplications: list, publicClient: bool, publisherDomain: string, replyUrls: list, requiredResourceAccess: list, samlMetadataUrl: string, signInAudience: string, wwwHomepage: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id)} | format pattern "/{tenant_id}/deletedApplications") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Hard-delete an application.
#
# DELETE /{tenantID}/deletedApplications/{applicationObjectId}
# operationId: DeletedApplications_HardDelete
export def "deleted-applications delete-hard" [
  tenant_id: string
  application_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_error: record<code: string, message: record<value: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), application_object_id: (encode-path-segment $application_object_id)} | format pattern "/{tenant_id}/deletedApplications/{application_object_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Restores the deleted application in the directory.
#
# POST /{tenantID}/deletedApplications/{objectId}/restore
# operationId: DeletedApplications_Restore
export def "deleted-applications-restore create" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<allowGuestsSignIn: bool, allowPassthroughUsers: bool, appId: string, appLogoUrl: string, appPermissions: list<string>, appRoles: table<allowedMemberTypes: list, description: string, displayName: string, id: string, isEnabled: bool, value: string>, availableToOtherTenants: bool, displayName: string, errorUrl: string, groupMembershipClaims: string, homepage: string, identifierUris: list<string>, informationalUrls: record<marketing: string, privacy: string, support: string, termsOfService: string>, isDeviceOnlyAuthSupported: bool, keyCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, type: string, usage: string, value: string>, knownClientApplications: list<string>, logoutUrl: string, oauth2AllowImplicitFlow: bool, oauth2AllowUrlPathMatching: bool, oauth2Permissions: table<adminConsentDescription: string, adminConsentDisplayName: string, id: string, isEnabled: bool, type: string, userConsentDescription: string, userConsentDisplayName: string, value: string>, oauth2RequirePostResponse: bool, optionalClaims: record<accessToken: list<record>, idToken: list<record>, samlToken: list<record>>, orgRestrictions: list<string>, passwordCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, value: string>, preAuthorizedApplications: table<appId: string, extensions: list, permissions: list>, publicClient: bool, publisherDomain: string, replyUrls: list<string>, requiredResourceAccess: table<resourceAccess: list, resourceAppId: string>, samlMetadataUrl: string, signInAudience: string, wwwHomepage: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), object_id: (encode-path-segment $object_id)} | format pattern "/{tenant_id}/deletedApplications/{object_id}/restore") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets a list of domains for the current tenant.
#
# GET /{tenantID}/domains
# operationId: Domains_List
export def "domains list" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --filter: string # The filter to apply to the operation.
  --api-version: string # Client API version.
]: nothing -> record<value: table<authenticationType: string, isDefault: bool, isVerified: bool, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id)} | format pattern "/{tenant_id}/domains") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets a specific domain in the current tenant.
#
# GET /{tenantID}/domains/{domainName}
# operationId: Domains_Get
export def "domains get" [
  tenant_id: string
  domain_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<authenticationType: string, isDefault: bool, isVerified: bool, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), domain_name: (encode-path-segment $domain_name)} | format pattern "/{tenant_id}/domains/{domain_name}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets the directory objects specified in a list of object IDs. You can also specify which resource collections (users, groups, etc.) should be searched by specifying the optional types parameter.
#
# POST /{tenantID}/getObjectsByObjectIds
# operationId: Objects_GetObjectsByObjectIds
export def "get-objects-by-object-ids get" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  --include-directory-object-references: oneof<nothing, bool> # If true, also searches for object IDs in the partner tenant.
  --object-ids: list<string> # The requested object IDs.
  --types: list<string> # The requested object types.
]: any -> record<odata_nextLink: string, value: table<deletionTimestamp: string, objectId: string, objectType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id)} | format pattern "/{tenant_id}/getObjectsByObjectIds") $qp)
  let req_body = {"includeDirectoryObjectReferences": $include_directory_object_references, "objectIds": $object_ids, "types": $types} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets list of groups for the current tenant.
#
# GET /{tenantID}/groups
# operationId: Groups_List
export def "groups list" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --filter: string # The filter to apply to the operation.
  --api-version: string # Client API version.
]: nothing -> record<odata_nextLink: string, value: table<displayName: string, mail: string, mailEnabled: bool, mailNickname: string, securityEnabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id)} | format pattern "/{tenant_id}/groups") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create a group in the directory.
#
# POST /{tenantID}/groups
# operationId: Groups_Create
export def "groups create" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  display_name: string # Group display name
  --mail-enabled: oneof<nothing, bool> # Whether the group is mail-enabled. Must be false. This is because only pure security groups can be created using the Graph API.
  mail_nickname: string # Mail nickname
  --security-enabled: oneof<nothing, bool> # Whether the group is a security group. Must be true. This is because only pure security groups can be created using the Graph API.
]: any -> record<displayName: string, mail: string, mailEnabled: bool, mailNickname: string, securityEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id)} | format pattern "/{tenant_id}/groups") $qp)
  let req_body = {"displayName": $display_name, "mailEnabled": $mail_enabled, "mailNickname": $mail_nickname, "securityEnabled": $security_enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Add a member to a group.
#
# POST /{tenantID}/groups/{groupObjectId}/$links/members
# operationId: Groups_AddMember
export def "groups-links-members create" [
  tenant_id: string
  group_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  url: string # A member object URL, such as "https://graph.windows.net/0b1f9851-1bf0-433f-aec3-cb9272f093dc/directoryObjects/f260bbc4-c254-447b-94cf-293b5ec434dd", where "0b1f9851-1bf0-433f-aec3-cb9272f093dc" is the tenantId and "f260bbc4-c254-447b-94cf-293b5ec434dd" is the objectId of the member (user, application, servicePrincipal, group) to be added.
]: any -> record<odata_error: record<code: string, message: record<value: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), group_object_id: (encode-path-segment $group_object_id)} | format pattern "/{tenant_id}/groups/{group_object_id}/$links/members") $qp)
  let req_body = {"url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Remove a member from a group.
#
# DELETE /{tenantID}/groups/{groupObjectId}/$links/members/{memberObjectId}
# operationId: Groups_RemoveMember
export def "groups-links-members delete" [
  tenant_id: string
  group_object_id: string
  member_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_error: record<code: string, message: record<value: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), group_object_id: (encode-path-segment $group_object_id), member_object_id: (encode-path-segment $member_object_id)} | format pattern "/{tenant_id}/groups/{group_object_id}/$links/members/{member_object_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete a group from the directory.
#
# DELETE /{tenantID}/groups/{objectId}
# operationId: Groups_Delete
export def "groups delete" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_error: record<code: string, message: record<value: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), object_id: (encode-path-segment $object_id)} | format pattern "/{tenant_id}/groups/{object_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets group information from the directory.
#
# GET /{tenantID}/groups/{objectId}
# operationId: Groups_Get
export def "groups get" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<displayName: string, mail: string, mailEnabled: bool, mailNickname: string, securityEnabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), object_id: (encode-path-segment $object_id)} | format pattern "/{tenant_id}/groups/{object_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Add an owner to a group.
#
# POST /{tenantID}/groups/{objectId}/$links/owners
# operationId: Groups_AddOwner
export def "groups-links-owners create" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  url: string # A owner object URL, such as "https://graph.windows.net/0b1f9851-1bf0-433f-aec3-cb9272f093dc/directoryObjects/f260bbc4-c254-447b-94cf-293b5ec434dd", where "0b1f9851-1bf0-433f-aec3-cb9272f093dc" is the tenantId and "f260bbc4-c254-447b-94cf-293b5ec434dd" is the objectId of the owner (user, application, servicePrincipal, group) to be added.
]: any -> record<odata_error: record<code: string, message: record<value: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), object_id: (encode-path-segment $object_id)} | format pattern "/{tenant_id}/groups/{object_id}/$links/owners") $qp)
  let req_body = {"url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Remove a member from owners.
#
# DELETE /{tenantID}/groups/{objectId}/$links/owners/{ownerObjectId}
# operationId: Groups_RemoveOwner
export def "groups-links-owners delete" [
  tenant_id: string
  object_id: string
  owner_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_error: record<code: string, message: record<value: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), object_id: (encode-path-segment $object_id), owner_object_id: (encode-path-segment $owner_object_id)} | format pattern "/{tenant_id}/groups/{object_id}/$links/owners/{owner_object_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets a collection of object IDs of groups of which the specified group is a member.
#
# POST /{tenantID}/groups/{objectId}/getMemberGroups
# operationId: Groups_GetMemberGroups
export def "groups-get-member-groups get" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  --security-enabled-only: oneof<nothing, bool> # If true, only membership in security-enabled groups should be checked. Otherwise, membership in all groups should be checked.
]: any -> record<value: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), object_id: (encode-path-segment $object_id)} | format pattern "/{tenant_id}/groups/{object_id}/getMemberGroups") $qp)
  let req_body = {"securityEnabledOnly": $security_enabled_only} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets the members of a group.
#
# GET /{tenantID}/groups/{objectId}/members
# operationId: Groups_GetGroupMembers
export def "groups-members get" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_nextLink: string, value: table<deletionTimestamp: string, objectId: string, objectType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), object_id: (encode-path-segment $object_id)} | format pattern "/{tenant_id}/groups/{object_id}/members") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Directory objects that are owners of the group.
#
# GET /{tenantID}/groups/{objectId}/owners
# operationId: Groups_ListOwners
export def "groups-owners list" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_nextLink: string, value: table<deletionTimestamp: string, objectId: string, objectType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), object_id: (encode-path-segment $object_id)} | format pattern "/{tenant_id}/groups/{object_id}/owners") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Checks whether the specified user, group, contact, or service principal is a direct or transitive member of the specified group.
#
# POST /{tenantID}/isMemberOf
# operationId: Groups_IsMemberOf
export def "is-member-of create-groups" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  group_id: string # The object ID of the group to check.
  member_id: string # The object ID of the contact, group, user, or service principal to check for membership in the specified group.
]: any -> record<value: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id)} | format pattern "/{tenant_id}/isMemberOf") $qp)
  let req_body = {"groupId": $group_id, "memberId": $member_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets the details for the currently logged-in user.
#
# GET /{tenantID}/me
# operationId: SignedInUser_Get
export def "me get-signed-in-user" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<accountEnabled: bool, displayName: string, givenName: string, immutableId: string, mail: string, mailNickname: string, signInNames: table<type: string, value: string>, surname: string, usageLocation: string, userPrincipalName: string, userType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id)} | format pattern "/{tenant_id}/me") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the list of directory objects that are owned by the user.
#
# GET /{tenantID}/me/ownedObjects
# operationId: SignedInUser_ListOwnedObjects
export def "me-owned-objects list-signed-in-user" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_nextLink: string, value: table<deletionTimestamp: string, objectId: string, objectType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id)} | format pattern "/{tenant_id}/me/ownedObjects") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Queries OAuth2 permissions grants for the relevant SP ObjectId of an app.
#
# GET /{tenantID}/oauth2PermissionGrants
# operationId: OAuth2PermissionGrant_List
export def "oauth2-permission-grants list-o-auth2" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # This is the Service Principal ObjectId associated with the app (e.g. clientId+eq+'61ed44c3-5a1d-4639-a215-07f25129c6c3)
  --api-version: string # Client API version.
]: nothing -> record<odata_nextLink: string, value: table<clientId: string, consentType: string, expiryTime: string, objectId: string, odata_type: string, principalId: string, resourceId: string, scope: string, startTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id)} | format pattern "/{tenant_id}/oauth2PermissionGrants") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Grants OAuth2 permissions for the relevant resource Ids of an app.
#
# POST /{tenantID}/oauth2PermissionGrants
# operationId: OAuth2PermissionGrant_Create
export def "oauth2-permission-grants create-o-auth2" [
  tenant_id: string
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
  --client-id: string # The id of the resource's service principal granted consent to impersonate the user when accessing the resource (represented by the resourceId property).
  --consent-type: string@consent-type-completer # Indicates if consent was provided by the administrator (on behalf of the organization) or by an individual.
  --expiry-time: string # Expiry time for TTL
  --object-id: string # The id of the permission grant
  --odata-type: string # Microsoft.DirectoryServices.OAuth2PermissionGrant
  --principal-id: string # When consent type is Principal, this property specifies the id of the user that granted consent and applies only for that user.
  --resource-id: string # Object Id of the resource you want to grant
  --scope: string # Specifies the value of the scope claim that the resource application should expect in the OAuth 2.0 access token. For example, User.Read
  --start-time: string # Start time for TTL
]: any -> record<clientId: string, consentType: string, expiryTime: string, objectId: string, odata_type: string, principalId: string, resourceId: string, scope: string, startTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id)} | format pattern "/{tenant_id}/oauth2PermissionGrants") $qp)
  let req_body = {"clientId": $client_id, "consentType": $consent_type, "expiryTime": $expiry_time, "objectId": $object_id, "odata.type": $odata_type, "principalId": $principal_id, "resourceId": $resource_id, "scope": $scope, "startTime": $start_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete a OAuth2 permission grant for the relevant resource Ids of an app.
#
# DELETE /{tenantID}/oauth2PermissionGrants/{objectId}
# operationId: OAuth2PermissionGrant_Delete
export def "oauth2-permission-grants delete-o-auth2" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_error: record<code: string, message: record<value: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), object_id: (encode-path-segment $object_id)} | format pattern "/{tenant_id}/oauth2PermissionGrants/{object_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets a list of service principals from the current tenant.
#
# GET /{tenantID}/servicePrincipals
# operationId: ServicePrincipals_List
export def "service-principals list" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --filter: string # The filter to apply to the operation.
  --api-version: string # Client API version.
]: nothing -> record<odata_nextLink: string, value: table<accountEnabled: bool, alternativeNames: list, appDisplayName: string, appId: string, appOwnerTenantId: string, appRoleAssignmentRequired: bool, appRoles: list, displayName: string, errorUrl: string, homepage: string, keyCredentials: list, logoutUrl: string, oauth2Permissions: list, passwordCredentials: list, preferredTokenSigningKeyThumbprint: string, publisherName: string, replyUrls: list, samlMetadataUrl: string, servicePrincipalNames: list, servicePrincipalType: string, tags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id)} | format pattern "/{tenant_id}/servicePrincipals") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Creates a service principal in the directory.
#
# POST /{tenantID}/servicePrincipals
# operationId: ServicePrincipals_Create
# --keyCredentials item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, type?: string, usage?: string, value?: string}
# --passwordCredentials item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, value?: string}
export def "service-principals create" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  app_id: string # The application ID.
  --account-enabled: oneof<nothing, bool> # whether or not the service principal account is enabled
  --app-role-assignment-required: oneof<nothing, bool> # Specifies whether an AppRoleAssignment to a user or group is required before Azure AD will issue a user or access token to the application.
  --key-credentials: list # The collection of key credentials associated with the service principal. — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, type?: string, usage?: string, value?: string}
  --password-credentials: list # The collection of password credentials associated with the service principal. — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, value?: string}
  --service-principal-type: string # the type of the service principal
  --tags: list<string> # Optional list of tags that you can apply to your service principals. Not nullable.
]: any -> record<accountEnabled: bool, alternativeNames: list<string>, appDisplayName: string, appId: string, appOwnerTenantId: string, appRoleAssignmentRequired: bool, appRoles: table<allowedMemberTypes: list, description: string, displayName: string, id: string, isEnabled: bool, value: string>, displayName: string, errorUrl: string, homepage: string, keyCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, type: string, usage: string, value: string>, logoutUrl: string, oauth2Permissions: table<adminConsentDescription: string, adminConsentDisplayName: string, id: string, isEnabled: bool, type: string, userConsentDescription: string, userConsentDisplayName: string, value: string>, passwordCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, value: string>, preferredTokenSigningKeyThumbprint: string, publisherName: string, replyUrls: list<string>, samlMetadataUrl: string, servicePrincipalNames: list<string>, servicePrincipalType: string, tags: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id)} | format pattern "/{tenant_id}/servicePrincipals") $qp)
  let req_body = {"appId": $app_id, "accountEnabled": $account_enabled, "appRoleAssignmentRequired": $app_role_assignment_required, "keyCredentials": $key_credentials, "passwordCredentials": $password_credentials, "servicePrincipalType": $service_principal_type, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes a service principal from the directory.
#
# DELETE /{tenantID}/servicePrincipals/{objectId}
# operationId: ServicePrincipals_Delete
export def "service-principals delete" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_error: record<code: string, message: record<value: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), object_id: (encode-path-segment $object_id)} | format pattern "/{tenant_id}/servicePrincipals/{object_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets service principal information from the directory. Query by objectId or pass a filter to query by appId
#
# GET /{tenantID}/servicePrincipals/{objectId}
# operationId: ServicePrincipals_Get
export def "service-principals get" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<accountEnabled: bool, alternativeNames: list<string>, appDisplayName: string, appId: string, appOwnerTenantId: string, appRoleAssignmentRequired: bool, appRoles: table<allowedMemberTypes: list, description: string, displayName: string, id: string, isEnabled: bool, value: string>, displayName: string, errorUrl: string, homepage: string, keyCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, type: string, usage: string, value: string>, logoutUrl: string, oauth2Permissions: table<adminConsentDescription: string, adminConsentDisplayName: string, id: string, isEnabled: bool, type: string, userConsentDescription: string, userConsentDisplayName: string, value: string>, passwordCredentials: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, value: string>, preferredTokenSigningKeyThumbprint: string, publisherName: string, replyUrls: list<string>, samlMetadataUrl: string, servicePrincipalNames: list<string>, servicePrincipalType: string, tags: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), object_id: (encode-path-segment $object_id)} | format pattern "/{tenant_id}/servicePrincipals/{object_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a service principal in the directory.
#
# PATCH /{tenantID}/servicePrincipals/{objectId}
# operationId: ServicePrincipals_Update
# --keyCredentials item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, type?: string, usage?: string, value?: string}
# --passwordCredentials item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, value?: string}
export def "service-principals update" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  --account-enabled: oneof<nothing, bool> # whether or not the service principal account is enabled
  --app-role-assignment-required: oneof<nothing, bool> # Specifies whether an AppRoleAssignment to a user or group is required before Azure AD will issue a user or access token to the application.
  --key-credentials: list # The collection of key credentials associated with the service principal. — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, type?: string, usage?: string, value?: string}
  --password-credentials: list # The collection of password credentials associated with the service principal. — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, value?: string}
  --service-principal-type: string # the type of the service principal
  --tags: list<string> # Optional list of tags that you can apply to your service principals. Not nullable.
]: any -> record<odata_error: record<code: string, message: record<value: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), object_id: (encode-path-segment $object_id)} | format pattern "/{tenant_id}/servicePrincipals/{object_id}") $qp)
  let req_body = {"accountEnabled": $account_enabled, "appRoleAssignmentRequired": $app_role_assignment_required, "keyCredentials": $key_credentials, "passwordCredentials": $password_credentials, "servicePrincipalType": $service_principal_type, "tags": $tags} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Add an owner to a service principal.
#
# POST /{tenantID}/servicePrincipals/{objectId}/$links/owners
# operationId: ServicePrincipals_AddOwner
export def "service-principals-links-owners create" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  url: string # A owner object URL, such as "https://graph.windows.net/0b1f9851-1bf0-433f-aec3-cb9272f093dc/directoryObjects/f260bbc4-c254-447b-94cf-293b5ec434dd", where "0b1f9851-1bf0-433f-aec3-cb9272f093dc" is the tenantId and "f260bbc4-c254-447b-94cf-293b5ec434dd" is the objectId of the owner (user, application, servicePrincipal, group) to be added.
]: any -> record<odata_error: record<code: string, message: record<value: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), object_id: (encode-path-segment $object_id)} | format pattern "/{tenant_id}/servicePrincipals/{object_id}/$links/owners") $qp)
  let req_body = {"url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Remove a member from owners.
#
# DELETE /{tenantID}/servicePrincipals/{objectId}/$links/owners/{ownerObjectId}
# operationId: ServicePrincipals_RemoveOwner
export def "service-principals-links-owners delete" [
  tenant_id: string
  object_id: string
  owner_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_error: record<code: string, message: record<value: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), object_id: (encode-path-segment $object_id), owner_object_id: (encode-path-segment $owner_object_id)} | format pattern "/{tenant_id}/servicePrincipals/{object_id}/$links/owners/{owner_object_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Principals (users, groups, and service principals) that are assigned to this service principal.
#
# GET /{tenantID}/servicePrincipals/{objectId}/appRoleAssignedTo
# operationId: ServicePrincipals_ListAppRoleAssignedTo
export def "service-principals-app-role-assigned-to list" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_nextLink: string, value: table<id: string, principalDisplayName: string, principalId: string, principalType: string, resourceDisplayName: string, resourceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), object_id: (encode-path-segment $object_id)} | format pattern "/{tenant_id}/servicePrincipals/{object_id}/appRoleAssignedTo") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Applications that the service principal is assigned to.
#
# GET /{tenantID}/servicePrincipals/{objectId}/appRoleAssignments
# operationId: ServicePrincipals_ListAppRoleAssignments
export def "service-principals-app-role-assignments list" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_nextLink: string, value: table<id: string, principalDisplayName: string, principalId: string, principalType: string, resourceDisplayName: string, resourceId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), object_id: (encode-path-segment $object_id)} | format pattern "/{tenant_id}/servicePrincipals/{object_id}/appRoleAssignments") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the keyCredentials associated with the specified service principal.
#
# GET /{tenantID}/servicePrincipals/{objectId}/keyCredentials
# operationId: ServicePrincipals_ListKeyCredentials
export def "service-principals-key-credentials list" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<value: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, type: string, usage: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), object_id: (encode-path-segment $object_id)} | format pattern "/{tenant_id}/servicePrincipals/{object_id}/keyCredentials") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update the keyCredentials associated with a service principal.
#
# PATCH /{tenantID}/servicePrincipals/{objectId}/keyCredentials
# operationId: ServicePrincipals_UpdateKeyCredentials
# --value item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, type?: string, usage?: string, value?: string}
export def "service-principals-key-credentials update" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  value: list # A collection of KeyCredentials. — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, type?: string, usage?: string, value?: string}
]: any -> record<odata_error: record<code: string, message: record<value: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), object_id: (encode-path-segment $object_id)} | format pattern "/{tenant_id}/servicePrincipals/{object_id}/keyCredentials") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Directory objects that are owners of this service principal.
#
# GET /{tenantID}/servicePrincipals/{objectId}/owners
# operationId: ServicePrincipals_ListOwners
export def "service-principals-owners list" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_nextLink: string, value: table<deletionTimestamp: string, objectId: string, objectType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), object_id: (encode-path-segment $object_id)} | format pattern "/{tenant_id}/servicePrincipals/{object_id}/owners") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets the passwordCredentials associated with a service principal.
#
# GET /{tenantID}/servicePrincipals/{objectId}/passwordCredentials
# operationId: ServicePrincipals_ListPasswordCredentials
export def "service-principals-password-credentials list" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<value: table<customKeyIdentifier: string, endDate: string, keyId: string, startDate: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), object_id: (encode-path-segment $object_id)} | format pattern "/{tenant_id}/servicePrincipals/{object_id}/passwordCredentials") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates the passwordCredentials associated with a service principal.
#
# PATCH /{tenantID}/servicePrincipals/{objectId}/passwordCredentials
# operationId: ServicePrincipals_UpdatePasswordCredentials
# --value item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, value?: string}
export def "service-principals-password-credentials update" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  value: list # A collection of PasswordCredentials. — item shape: {customKeyIdentifier?: string, endDate?: string, keyId?: string, startDate?: string, value?: string}
]: any -> record<odata_error: record<code: string, message: record<value: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), object_id: (encode-path-segment $object_id)} | format pattern "/{tenant_id}/servicePrincipals/{object_id}/passwordCredentials") $qp)
  let req_body = {"value": $value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets an object id for a given application id from the current tenant.
#
# GET /{tenantID}/servicePrincipalsByAppId/{applicationID}/objectId
# operationId: Applications_GetServicePrincipalsIdByAppId
export def "service-principals-by-app-id-object-id get-applications" [
  tenant_id: string
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_metadata: string, value: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), application_id: (encode-path-segment $application_id)} | format pattern "/{tenant_id}/servicePrincipalsByAppId/{application_id}/objectId") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets list of users for the current tenant.
#
# GET /{tenantID}/users
# operationId: Users_List
export def "users list" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id)} | format pattern "/{tenant_id}/users") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create a new user.
#
# POST /{tenantID}/users
# operationId: Users_Create
# --passwordProfile shape: {forceChangePasswordNextLogin?: bool, password: string}
export def "users create" [
  tenant_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  --account-enabled: oneof<nothing, bool> # Whether the account is enabled.
  display_name: string # The display name of the user.
  --mail: string # The primary email address of the user.
  mail_nickname: string # The mail alias for the user.
  password_profile: record # The password profile associated with a user. — shape: {forceChangePasswordNextLogin?: bool, password: string}
  user_principal_name: string # The user principal name (someuser@contoso.com). It must contain one of the verified domains for the tenant.
  --given-name: string # The given name for the user.
  --immutable-id: string # This must be specified if you are using a federated domain for the user's userPrincipalName (UPN) property when creating a new user account. It is used to associate an on-premises Active Directory user account with their Azure AD user object.
  --surname: string # The user's surname (family name or last name).
  --usage-location: string # A two letter country code (ISO standard 3166). Required for users that will be assigned licenses due to legal requirement to check for availability of services in countries. Examples include: "US", "JP", and "GB".
  --user-type: string@user-type-completer # A string value that can be used to classify user types in your directory, such as 'Member' and 'Guest'.
]: any -> record<accountEnabled: bool, displayName: string, givenName: string, immutableId: string, mail: string, mailNickname: string, signInNames: table<type: string, value: string>, surname: string, usageLocation: string, userPrincipalName: string, userType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id)} | format pattern "/{tenant_id}/users") $qp)
  let req_body = {"accountEnabled": $account_enabled, "displayName": $display_name, "mail": $mail, "mailNickname": $mail_nickname, "passwordProfile": $password_profile, "userPrincipalName": $user_principal_name, "givenName": $given_name, "immutableId": $immutable_id, "surname": $surname, "usageLocation": $usage_location, "userType": $user_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Gets a collection that contains the object IDs of the groups of which the user is a member.
#
# POST /{tenantID}/users/{objectId}/getMemberGroups
# operationId: Users_GetMemberGroups
export def "users-get-member-groups get" [
  tenant_id: string
  object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  --security-enabled-only: oneof<nothing, bool> # If true, only membership in security-enabled groups should be checked. Otherwise, membership in all groups should be checked.
]: any -> record<value: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), object_id: (encode-path-segment $object_id)} | format pattern "/{tenant_id}/users/{object_id}/getMemberGroups") $qp)
  let req_body = {"securityEnabledOnly": $security_enabled_only} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete a user.
#
# DELETE /{tenantID}/users/{upnOrObjectId}
# operationId: Users_Delete
export def "users delete" [
  tenant_id: string
  upn_or_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<odata_error: record<code: string, message: record<value: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), upn_or_object_id: (encode-path-segment $upn_or_object_id)} | format pattern "/{tenant_id}/users/{upn_or_object_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Gets user information from the directory.
#
# GET /{tenantID}/users/{upnOrObjectId}
# operationId: Users_Get
export def "users get" [
  tenant_id: string
  upn_or_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
]: nothing -> record<accountEnabled: bool, displayName: string, givenName: string, immutableId: string, mail: string, mailNickname: string, signInNames: table<type: string, value: string>, surname: string, usageLocation: string, userPrincipalName: string, userType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), upn_or_object_id: (encode-path-segment $upn_or_object_id)} | format pattern "/{tenant_id}/users/{upn_or_object_id}") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Updates a user.
#
# PATCH /{tenantID}/users/{upnOrObjectId}
# operationId: Users_Update
# --passwordProfile shape: {forceChangePasswordNextLogin?: bool, password: string}
export def "users update" [
  tenant_id: string
  upn_or_object_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --api-version: string # Client API version.
  --account-enabled: oneof<nothing, bool> # Whether the account is enabled.
  --display-name: string # The display name of the user.
  --mail: string # The primary email address of the user.
  --mail-nickname: string # The mail alias for the user.
  --password-profile: record # The password profile associated with a user. — shape: {forceChangePasswordNextLogin?: bool, password: string}
  --user-principal-name: string # The user principal name (someuser@contoso.com). It must contain one of the verified domains for the tenant.
  --given-name: string # The given name for the user.
  --immutable-id: string # This must be specified if you are using a federated domain for the user's userPrincipalName (UPN) property when creating a new user account. It is used to associate an on-premises Active Directory user account with their Azure AD user object.
  --surname: string # The user's surname (family name or last name).
  --usage-location: string # A two letter country code (ISO standard 3166). Required for users that will be assigned licenses due to legal requirement to check for availability of services in countries. Examples include: "US", "JP", and "GB".
  --user-type: string@user-type-completer # A string value that can be used to classify user types in your directory, such as 'Member' and 'Guest'.
]: any -> record<odata_error: record<code: string, message: record<value: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({tenant_id: (encode-path-segment $tenant_id), upn_or_object_id: (encode-path-segment $upn_or_object_id)} | format pattern "/{tenant_id}/users/{upn_or_object_id}") $qp)
  let req_body = {"accountEnabled": $account_enabled, "displayName": $display_name, "mail": $mail, "mailNickname": $mail_nickname, "passwordProfile": $password_profile, "userPrincipalName": $user_principal_name, "givenName": $given_name, "immutableId": $immutable_id, "surname": $surname, "usageLocation": $usage_location, "userType": $user_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}
