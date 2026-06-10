# Auto-generated client for Ory Identities API v
# Source: https://raw.githubusercontent.com/ory/kratos/master/spec/api.json
# Auth: --token flag or $env.ORY_IDENTITIES_API_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ORY_IDENTITIES_API_TOKEN | default "" }
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
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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
def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def consistency-completer [] { ["" "eventual" "strong"] }
def region-completer [] { ["asia" "asia-northeast" "eu" "eu-central" "global" "us" "us-east" "us-west"] }
def state-completer [] { ["active" "inactive"] }
def action-completer [] { ["delete" "disable"] }
def accept-completer [] { ["application/json" "text/plain"] }
def method-completer [] { ["code" "identifier_first" "lookup_secret" "oidc" "passkey" "password" "saml" "totp" "webauthn"] }
def method-completer-1 [] { ["code" "link"] }
def method-completer-2 [] { ["code" "oidc" "passkey" "password" "profile" "saml" "webauthn"] }
def screen-completer [] { ["credential-selection" "previous"] }
def method-completer-3 [] { ["lookup_secret" "oidc" "passkey" "password" "profile" "saml" "totp" "webauthn"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "well-known-ory-webauthnjs get" } } | get name | first)
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

# Get WebAuthn JavaScript
#
# GET /.well-known/ory/webauthn.js
# operationId: getWebAuthnJavaScript
export def "well-known-ory-webauthnjs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/.well-known/ory/webauthn.js")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Messages
#
# GET /admin/courier/messages
# operationId: listCourierMessages
export def "admin-courier-messages listCourierMessages" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-size: int # Items per Page  This is the number of items per page to return. For details on pagination please head over to the [pagination documentation](https://www.ory.com/docs/ecosystem/api-design#pagination). (format: int64, default: 250)
  --page-token: string # Next Page Token  The next page token. For details on pagination please head over to the [pagination documentation](https://www.ory.com/docs/ecosystem/api-design#pagination).
  --status: string # Status filters out messages based on status. If no value is provided, it doesn't take effect on filter.
  --recipient: string # Recipient filters out messages based on recipient. If no value is provided, it doesn't take effect on filter.
]: nothing -> record<error: record<code: int, debug: string, details: record, id: string, message: string, reason: string, request: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "recipient" $recipient "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/courier/messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a Message
#
# GET /admin/courier/messages/{id}
# operationId: getCourierMessage
export def "admin-courier-messages get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<body: string, channel: string, created_at: string, dispatches: table<created_at: string, error: record, id: string, message_id: string, status: string, updated_at: string>, id: string, recipient: string, send_count: int, status: string, subject: string, template_type: string, type: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/courier/messages/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Identities
#
# GET /admin/identities
# operationId: listIdentities
export def "admin-identities listIdentities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Deprecated Items per Page  DEPRECATED: Please use `page_token` instead. This parameter will be removed in the future.  This is the number of items per page. (format: int64, default: 250)
  --page: int # Deprecated Pagination Page  DEPRECATED: Please use `page_token` instead. This parameter will be removed in the future.  This value is currently an integer, but it is not sequential. The value is not the page number, but a reference. The next page can be any number and some numbers might return an empty list.  For example, page 2 might not follow after page 1. And even if page 3 and 5 exist, but page 4 might not exist. The first page can be retrieved by omitting this parameter. Following page pointers will be returned in the `Link` header. (format: int64)
  --page-size: int # Page Size  This is the number of items per page to return. For details on pagination please head over to the [pagination documentation](https://www.ory.com/docs/ecosystem/api-design#pagination). (format: int64, default: 250)
  --page-token: string # Next Page Token  The next page token. For details on pagination please head over to the [pagination documentation](https://www.ory.com/docs/ecosystem/api-design#pagination).
  --consistency: string@consistency-completer # Read Consistency Level (preview)  The read consistency level determines the consistency guarantee for reads:  strong (slow): The read is guaranteed to return the most recent data committed at the start of the read. eventual (very fast): The result will return data that is about 4.8 seconds old.  The default consistency guarantee can be changed in the Ory Network Console or using the Ory CLI with `ory patch project --replace '/previews/default_read_consistency_level="strong"'`.  Setting the default consistency level to `eventual` may cause regressions in the future as we add consistency controls to more APIs. Currently, the following APIs will be affected by this setting:  `GET /admin/identities`  This feature is in preview and only available in Ory Network.  ConsistencyLevelUnset  ConsistencyLevelUnset is the unset / default consistency level. strong ConsistencyLevelStrong  ConsistencyLevelStrong is the strong consistency level. eventual ConsistencyLevelEventual  ConsistencyLevelEventual is the eventual consistency level using follower read timestamps.
  --ids: list # Retrieve multiple identities by their IDs.  This parameter has the following limitations:  Duplicate or non-existent IDs are ignored. The order of returned IDs may be different from the request. This filter does not support pagination. You must implement your own pagination as the maximum number of items returned by this endpoint may not exceed a certain threshold (currently 500).
  --credentials-identifier: string # CredentialsIdentifier is the identifier (username, email) of the credentials to look up using exact match. Only one of CredentialsIdentifier and CredentialsIdentifierSimilar can be used.
  --preview-credentials-identifier-similar: string # This is an EXPERIMENTAL parameter that WILL CHANGE. Do NOT rely on consistent, deterministic behavior. THIS PARAMETER WILL BE REMOVED IN AN UPCOMING RELEASE WITHOUT ANY MIGRATION PATH.  CredentialsIdentifierSimilar is the (partial) identifier (username, email) of the credentials to look up using similarity search. Only one of CredentialsIdentifier and CredentialsIdentifierSimilar can be used.
  --include-credential: list # Include Credentials in Response  Include any credential, for example `password` or `oidc`, in the response. When set to `oidc`, This will return the initial OAuth 2.0 Access Token, OAuth 2.0 Refresh Token, and the OpenID Connect ID Token if available.
  --organization-id: string # List identities that belong to a specific organization.
]: nothing -> record<error: record<code: int, debug: string, details: record, id: string, message: string, reason: string, request: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "consistency" $consistency "scalar") (serialize-qp "ids" $ids "multi") (serialize-qp "credentials_identifier" $credentials_identifier "scalar") (serialize-qp "preview_credentials_identifier_similar" $preview_credentials_identifier_similar "scalar") (serialize-qp "include_credential" $include_credential "multi") (serialize-qp "organization_id" $organization_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/identities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create multiple identities
#
# PATCH /admin/identities
# operationId: batchPatchIdentities
# --identities item shape: {create?: record, patch_id?: string}
export def "admin-identities batchPatchIdentities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identities: list # Identities holds the list of patches to apply  required — item shape: {create?: record, patch_id?: string}
]: any -> record<identities: table<action: string, error: any, identity: string, patch_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/identities")
  let body = {identities: $identities} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an Identity
#
# POST /admin/identities
# operationId: createIdentity
# --credentials shape: {lookup_secret?: record, oidc?: record, passkey?: record, password?: record, saml?: record, totp?: record, webauthn?: record}
# --recovery_addresses item shape: {break_glass_for_organization?: string, created_at?: string, id?: string, updated_at?: string, value: string, via: string}
# --verifiable_addresses item shape: {created_at?: string, id?: string, status: string, updated_at?: string, value: string, verified: bool, verified_at?: string, via: "email"|"sms"}
export def "admin-identities createIdentity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --credentials: record # Create Identity and Import Credentials — shape: {lookup_secret?: record, oidc?: record, passkey?: record, password?: record, saml?: record, totp?: record, webauthn?: record}
  --external-id: string # ExternalID is an optional external ID of the identity. This is used to link the identity to an external system. If set, the external ID must be unique across all identities.
  --metadata-admin: any # Store metadata about the user which is only accessible through admin APIs such as `GET /admin/identities/<id>`.
  --metadata-public: any # Store metadata about the identity which the identity itself can see when calling for example the session endpoint. Do not store sensitive information (e.g. credit score) about the identity in this field.
  --organization-id: string # nullable, format: uuid4
  --recovery-addresses: list # RecoveryAddresses contains all the addresses that can be used to recover an identity.  Use this structure to import recovery addresses for an identity. Please keep in mind that the address needs to be represented in the Identity Schema or this field will be overwritten on the next identity update. — item shape: {break_glass_for_organization?: string, created_at?: string, id?: string, updated_at?: string, value: string, via: string}
  --region: string@region-completer # Region is the Ory Network region this identity will be created in. Optional; defaults to the project home region if omitted. Only effective on the Ory Network. eu-central EUCentral asia-northeast AsiaNorthEast us-east USEast us-west USWest eu EU asia Asia us US global Global
  schema_id: string # SchemaID is the ID of the JSON Schema to be used for validating the identity's traits.
  --state: string@state-completer # State is the identity's state. active StateActive inactive StateInactive
  traits: record # Traits represent an identity's traits. The identity is able to create, modify, and delete traits in a self-service manner. The input will always be validated against the JSON Schema defined in `schema_url`.
  --verifiable-addresses: list # VerifiableAddresses contains all the addresses that can be verified by the user.  Use this structure to import verified addresses for an identity. Please keep in mind that the address needs to be represented in the Identity Schema or this field will be overwritten on the next identity update. — item shape: {created_at?: string, id?: string, status: string, updated_at?: string, value: string, verified: bool, verified_at?: string, via: "email"|"sms"}
]: any -> record<created_at: string, credentials: record, external_id: string, id: string, metadata_admin: any, metadata_public: any, organization_id: string, recovery_addresses: table<break_glass_for_organization: string, created_at: string, id: string, updated_at: string, value: string, via: string>, region: string, schema_id: string, schema_url: string, state: string, state_changed_at: string, traits: any, updated_at: string, verifiable_addresses: table<created_at: string, id: string, status: string, updated_at: string, value: string, verified: bool, verified_at: string, via: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/identities")
  let body = {credentials: $credentials, external_id: $external_id, metadata_admin: $metadata_admin, metadata_public: $metadata_public, organization_id: $organization_id, recovery_addresses: $recovery_addresses, region: $region, schema_id: $schema_id, state: $state, traits: $traits, verifiable_addresses: $verifiable_addresses} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an Identity by its External ID
#
# GET /admin/identities/by/external/{externalID}
# operationId: getIdentityByExternalID
export def "admin-identities-by-external get" [
  externalID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-credential: list # Include Credentials in Response  Include any credential, for example `password` or `oidc`, in the response. When set to `oidc`, This will return the initial OAuth 2.0 Access Token, OAuth 2.0 Refresh Token, and the OpenID Connect ID Token if available.
]: nothing -> record<created_at: string, credentials: record, external_id: string, id: string, metadata_admin: any, metadata_public: any, organization_id: string, recovery_addresses: table<break_glass_for_organization: string, created_at: string, id: string, updated_at: string, value: string, via: string>, region: string, schema_id: string, schema_url: string, state: string, state_changed_at: string, traits: any, updated_at: string, verifiable_addresses: table<created_at: string, id: string, status: string, updated_at: string, value: string, verified: bool, verified_at: string, via: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_credential" $include_credential "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/identities/by/external/($externalID)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete an Identity
#
# DELETE /admin/identities/{id}
# operationId: deleteIdentity
export def "admin-identities delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: record<code: int, debug: string, details: record, id: string, message: string, reason: string, request: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/identities/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an Identity
#
# GET /admin/identities/{id}
# operationId: getIdentity
export def "admin-identities get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-credential: list # Include Credentials in Response  Include any credential, for example `password` or `oidc`, in the response. When set to `oidc`, This will return the initial OAuth 2.0 Access Token, OAuth 2.0 Refresh Token, and the OpenID Connect ID Token if available.
]: nothing -> record<created_at: string, credentials: record, external_id: string, id: string, metadata_admin: any, metadata_public: any, organization_id: string, recovery_addresses: table<break_glass_for_organization: string, created_at: string, id: string, updated_at: string, value: string, via: string>, region: string, schema_id: string, schema_url: string, state: string, state_changed_at: string, traits: any, updated_at: string, verifiable_addresses: table<created_at: string, id: string, status: string, updated_at: string, value: string, verified: bool, verified_at: string, via: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_credential" $include_credential "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/identities/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch an Identity
#
# PATCH /admin/identities/{id}
# operationId: patchIdentity
export def "admin-identities patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<created_at: string, credentials: record, external_id: string, id: string, metadata_admin: any, metadata_public: any, organization_id: string, recovery_addresses: table<break_glass_for_organization: string, created_at: string, id: string, updated_at: string, value: string, via: string>, region: string, schema_id: string, schema_url: string, state: string, state_changed_at: string, traits: any, updated_at: string, verifiable_addresses: table<created_at: string, id: string, status: string, updated_at: string, value: string, verified: bool, verified_at: string, via: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/identities/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an Identity
#
# PUT /admin/identities/{id}
# operationId: updateIdentity
# --credentials shape: {lookup_secret?: record, oidc?: record, passkey?: record, password?: record, saml?: record, totp?: record, webauthn?: record}
export def "admin-identities updateIdentity" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --credentials: record # Create Identity and Import Credentials — shape: {lookup_secret?: record, oidc?: record, passkey?: record, password?: record, saml?: record, totp?: record, webauthn?: record}
  --external-id: string # ExternalID is an optional external ID of the identity. This is used to link the identity to an external system. If set, the external ID must be unique across all identities.
  --metadata-admin: any # Store metadata about the user which is only accessible through admin APIs such as `GET /admin/identities/<id>`.
  --metadata-public: any # Store metadata about the identity which the identity itself can see when calling for example the session endpoint. Do not store sensitive information (e.g. credit score) about the identity in this field.
  --region: string@region-completer # Region is the Ory Network region this identity is homed in. Optional; omit to leave the current region unchanged. eu-central EUCentral asia-northeast AsiaNorthEast us-east USEast us-west USWest eu EU asia Asia us US global Global
  schema_id: string # SchemaID is the ID of the JSON Schema to be used for validating the identity's traits. If set will update the Identity's SchemaID.
  state: string@state-completer # State is the identity's state. active StateActive inactive StateInactive
  traits: record # Traits represent an identity's traits. The identity is able to create, modify, and delete traits in a self-service manner. The input will always be validated against the JSON Schema defined in `schema_id`.
]: any -> record<created_at: string, credentials: record, external_id: string, id: string, metadata_admin: any, metadata_public: any, organization_id: string, recovery_addresses: table<break_glass_for_organization: string, created_at: string, id: string, updated_at: string, value: string, via: string>, region: string, schema_id: string, schema_url: string, state: string, state_changed_at: string, traits: any, updated_at: string, verifiable_addresses: table<created_at: string, id: string, status: string, updated_at: string, value: string, verified: bool, verified_at: string, via: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/identities/($id)")
  let body = {credentials: $credentials, external_id: $external_id, metadata_admin: $metadata_admin, metadata_public: $metadata_public, region: $region, schema_id: $schema_id, state: $state, traits: $traits} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a credential for a specific identity
#
# DELETE /admin/identities/{id}/credentials/{type}
# operationId: deleteIdentityCredentials
export def "admin-identities-credentials delete" [
  id: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifier: string # Identifier is the identifier of the OIDC/SAML credential to delete. Find the identifier by calling the `GET /admin/identities/{id}?include_credential={oidc,saml}` endpoint.
]: nothing -> record<error: record<code: int, debug: string, details: record, id: string, message: string, reason: string, request: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "identifier" $identifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/identities/($id)/credentials/($type)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete & Invalidate an Identity's Sessions
#
# DELETE /admin/identities/{id}/sessions
# operationId: deleteIdentitySessions
export def "admin-identities-sessions delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: record<code: int, debug: string, details: record, id: string, message: string, reason: string, request: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/identities/($id)/sessions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List an Identity's Sessions
#
# GET /admin/identities/{id}/sessions
# operationId: listIdentitySessions
export def "admin-identities-sessions listIdentitySessions" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Deprecated Items per Page  DEPRECATED: Please use `page_token` instead. This parameter will be removed in the future.  This is the number of items per page. (format: int64, default: 250)
  --page: int # Deprecated Pagination Page  DEPRECATED: Please use `page_token` instead. This parameter will be removed in the future.  This value is currently an integer, but it is not sequential. The value is not the page number, but a reference. The next page can be any number and some numbers might return an empty list.  For example, page 2 might not follow after page 1. And even if page 3 and 5 exist, but page 4 might not exist. The first page can be retrieved by omitting this parameter. Following page pointers will be returned in the `Link` header. (format: int64)
  --page-size: int # Page Size  This is the number of items per page to return. For details on pagination please head over to the [pagination documentation](https://www.ory.com/docs/ecosystem/api-design#pagination). (format: int64, default: 250)
  --page-token: string # Next Page Token  The next page token. For details on pagination please head over to the [pagination documentation](https://www.ory.com/docs/ecosystem/api-design#pagination).
  --active: string@bool-completer # Active is a boolean flag that filters out sessions based on the state. If no value is provided, all sessions are returned.
]: nothing -> record<error: record<code: int, debug: string, details: record, id: string, message: string, reason: string, request: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "active" $active "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/identities/($id)/sessions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a Recovery Code
#
# POST /admin/recovery/code
# operationId: createRecoveryCodeForIdentity
export def "admin-recovery-code createRecoveryCodeForIdentity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expires-in: string # Code Expires In  The recovery code will expire after that amount of time has passed. Defaults to the configuration value of `selfservice.methods.code.config.lifespan`.
  --flow-type: string # The flow type can either be `api` or `browser`.
  identity_id: string # Identity to Recover  The identity's ID you wish to recover. (format: uuid)
]: any -> record<expires_at: string, recovery_code: string, recovery_link: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/recovery/code")
  let body = {expires_in: $expires_in, flow_type: $flow_type, identity_id: $identity_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a Recovery Link
#
# POST /admin/recovery/link
# operationId: createRecoveryLinkForIdentity
export def "admin-recovery-link createRecoveryLinkForIdentity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --return-to: string
  --expires-in: string # Link Expires In  The recovery link will expire after that amount of time has passed. Defaults to the configuration value of `selfservice.methods.code.config.lifespan`.
  identity_id: string # Identity to Recover  The identity's ID you wish to recover. (format: uuid)
]: any -> record<expires_at: string, recovery_link: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "return_to" $return_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/recovery/link" $qp)
  let body = {expires_in: $expires_in, identity_id: $identity_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List All Sessions
#
# GET /admin/sessions
# operationId: listSessions
export def "admin-sessions listSessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page-size: int # Items per Page  This is the number of items per page to return. For details on pagination please head over to the [pagination documentation](https://www.ory.com/docs/ecosystem/api-design#pagination). (format: int64, default: 250)
  --page-token: string # Next Page Token  The next page token. For details on pagination please head over to the [pagination documentation](https://www.ory.com/docs/ecosystem/api-design#pagination).
  --active: string@bool-completer # Active is a boolean flag that filters out sessions based on the state. If no value is provided, all sessions are returned.
  --expand: list # ExpandOptions is a query parameter encoded list of all properties that must be expanded in the Session. If no value is provided, the expandable properties are skipped.
]: nothing -> record<error: record<code: int, debug: string, details: record, id: string, message: string, reason: string, request: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar") (serialize-qp "active" $active "scalar") (serialize-qp "expand" $expand "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/admin/sessions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Manage sessions in bulk
#
# POST /admin/sessions
# operationId: manageSessions
export def "admin-sessions manageSessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  action: string@action-completer # Action to perform on the matching sessions. disable ManageSessionsActionDisable delete ManageSessionsActionDelete
  --identities: list # Identity IDs whose sessions should be disabled or deleted, or `["*"]` to operate on every session in the network. Mutually exclusive with `sessions`.
  --sessions: list # Session IDs to disable or delete. Mutually exclusive with `identities`. The wildcard `["*"]` is not accepted in this field — pass `identities: ["*"]` to scope the operation to every session in the network.
]: any -> record<more: bool, processed: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/sessions")
  let body = {action: $action, identities: $identities, sessions: $sessions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deactivate a Session
#
# DELETE /admin/sessions/{id}
# operationId: disableSession
export def "admin-sessions disableSession" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<error: record<code: int, debug: string, details: record, id: string, message: string, reason: string, request: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/sessions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Session
#
# GET /admin/sessions/{id}
# operationId: getSession
export def "admin-sessions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expand: list # ExpandOptions is a query parameter encoded list of all properties that must be expanded in the Session. Example - ?expand=Identity&expand=Devices If no value is provided, the expandable properties are skipped.
]: nothing -> record<active: bool, authenticated_at: string, authentication_methods: table<aal: string, completed_at: string, method: string, organization: string, provider: string, upstream_acr: string, upstream_amr: list>, authenticator_assurance_level: string, devices: table<id: string, ip_address: string, location: string, user_agent: string>, expires_at: string, id: string, identity: record<created_at: string, credentials: record, external_id: string, id: string, metadata_admin: any, metadata_public: any, organization_id: string, recovery_addresses: list<record>, region: string, schema_id: string, schema_url: string, state: string, state_changed_at: string, traits: any, updated_at: string, verifiable_addresses: list<record>>, issued_at: string, tokenized: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "expand" $expand "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/admin/sessions/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Extend a Session
#
# PATCH /admin/sessions/{id}/extend
# operationId: extendSession
export def "admin-sessions-extend extendSession" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<active: bool, authenticated_at: string, authentication_methods: table<aal: string, completed_at: string, method: string, organization: string, provider: string, upstream_acr: string, upstream_amr: list>, authenticator_assurance_level: string, devices: table<id: string, ip_address: string, location: string, user_agent: string>, expires_at: string, id: string, identity: record<created_at: string, credentials: record, external_id: string, id: string, metadata_admin: any, metadata_public: any, organization_id: string, recovery_addresses: list<record>, region: string, schema_id: string, schema_url: string, state: string, state_changed_at: string, traits: any, updated_at: string, verifiable_addresses: list<record>>, issued_at: string, tokenized: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/admin/sessions/($id)/extend")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a test OIDC login flow
#
# POST /admin/test-login-flows
# operationId: createTestLoginFlow
export def "admin-test-login-flows createTestLoginFlow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  provider_id: string # ID of the OIDC provider to test. Must match a provider configured on the project that serves this request.
]: any -> record<active: string, created_at: string, expires_at: string, id: string, identity_schema: string, issued_at: string, oauth2_login_challenge: string, oauth2_login_request: record<challenge: string, client: record<access_token_strategy: string, allowed_cors_origins: list, audience: list, authorization_code_grant_access_token_lifespan: string, authorization_code_grant_id_token_lifespan: string, authorization_code_grant_refresh_token_lifespan: string, backchannel_logout_session_required: bool, backchannel_logout_uri: string, client_credentials_grant_access_token_lifespan: string, client_id: string, client_name: string, client_secret: string, client_secret_expires_at: int, client_uri: string, contacts: list, created_at: string, frontchannel_logout_session_required: bool, frontchannel_logout_uri: string, grant_types: list, implicit_grant_access_token_lifespan: string, implicit_grant_id_token_lifespan: string, jwks: any, jwks_uri: string, jwt_bearer_grant_access_token_lifespan: string, logo_uri: string, metadata: any, owner: string, policy_uri: string, post_logout_redirect_uris: list, redirect_uris: list, refresh_token_grant_access_token_lifespan: string, refresh_token_grant_id_token_lifespan: string, refresh_token_grant_refresh_token_lifespan: string, registration_access_token: string, registration_client_uri: string, request_object_signing_alg: string, request_uris: list, response_types: list, scope: string, sector_identifier_uri: string, skip_consent: bool, skip_logout_consent: bool, subject_type: string, token_endpoint_auth_method: string, token_endpoint_auth_signing_alg: string, tos_uri: string, updated_at: string, userinfo_signed_response_alg: string>, oidc_context: record<acr_values: list, display: string, id_token_hint_claims: record, login_hint: string, ui_locales: list>, request_url: string, requested_access_token_audience: list<string>, requested_scope: list<string>, session_id: string, skip: bool, subject: string>, organization_id: string, refresh: bool, request_url: string, requested_aal: string, return_to: string, session_token_exchange_code: string, state: any, test_context: record<debug_payload: record<error: record, id_token_claims: record, jsonnet_input: record, jsonnet_mapper_url: string, jsonnet_output: record, jsonnet_stderr: string, schema_validation_errors: list, userinfo: record>, provider_id: string>, transient_payload: record, type: string, ui: record<action: string, messages: list<record>, method: string, nodes: list<record>>, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/admin/test-login-flows")
  let body = {provider_id: $provider_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check HTTP Server Status
#
# GET /health/alive
# operationId: isAlive
export def "health-alive isAlive" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health/alive")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check HTTP Server and Database Status
#
# GET /health/ready
# operationId: isReady
export def "health-ready isReady" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accept: string@accept-completer # Response content type
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/health/ready")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all Identity Schemas
#
# GET /schemas
# operationId: listIdentitySchemas
export def "schemas listIdentitySchemas" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Deprecated Items per Page  DEPRECATED: Please use `page_token` instead. This parameter will be removed in the future.  This is the number of items per page. (format: int64, default: 250)
  --page: int # Deprecated Pagination Page  DEPRECATED: Please use `page_token` instead. This parameter will be removed in the future.  This value is currently an integer, but it is not sequential. The value is not the page number, but a reference. The next page can be any number and some numbers might return an empty list.  For example, page 2 might not follow after page 1. And even if page 3 and 5 exist, but page 4 might not exist. The first page can be retrieved by omitting this parameter. Following page pointers will be returned in the `Link` header. (format: int64)
  --page-size: int # Page Size  This is the number of items per page to return. For details on pagination please head over to the [pagination documentation](https://www.ory.com/docs/ecosystem/api-design#pagination). (format: int64, default: 250)
  --page-token: string # Next Page Token  The next page token. For details on pagination please head over to the [pagination documentation](https://www.ory.com/docs/ecosystem/api-design#pagination).
]: nothing -> record<error: record<code: int, debug: string, details: record, id: string, message: string, reason: string, request: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/schemas" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Identity JSON Schema
#
# GET /schemas/{id}
# operationId: getIdentitySchema
export def "schemas get" [
  id: string
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
  let full_url = (build-url $base $"/schemas/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get User-Flow Errors
#
# GET /self-service/errors
# operationId: getFlowError
export def "self-service-errors get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # Error is the error's ID
]: nothing -> record<created_at: string, error: record, id: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/self-service/errors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get FedCM Parameters
#
# GET /self-service/fed-cm/parameters
# operationId: createFedcmFlow
export def "self-service-fed-cm-parameters createFedcmFlow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<csrf_token: string, providers: table<client_id: string, config_url: string, domain_hint: string, fields: list, login_hint: string, nonce: string, parameters: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/self-service/fed-cm/parameters")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Submit a FedCM token
#
# POST /self-service/fed-cm/token
# operationId: updateFedcmFlow
export def "self-service-fed-cm-token updateFedcmFlow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  csrf_token: string # CSRFToken is the anti-CSRF token.
  --nonce: string # Nonce is the nonce that was used in the `navigator.credentials.get` call. If specified, it must match the `nonce` claim in the token.
  --body-token: string # Token contains the result of `navigator.credentials.get`.
  --transient-payload: record # Transient data to pass along to any webhooks.
]: any -> record<continue_with: list<record>, session: record<active: bool, authenticated_at: string, authentication_methods: list<record>, authenticator_assurance_level: string, devices: list<record>, expires_at: string, id: string, identity: record<created_at: string, credentials: record, external_id: string, id: string, metadata_admin: any, metadata_public: any, organization_id: string, recovery_addresses: list, region: string, schema_id: string, schema_url: string, state: string, state_changed_at: string, traits: any, updated_at: string, verifiable_addresses: list>, issued_at: string, tokenized: string>, session_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/self-service/fed-cm/token")
  let body = {csrf_token: $csrf_token, nonce: $nonce, token: $body_token, transient_payload: $transient_payload} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Submit a Login Flow
#
# POST /self-service/login
# Discriminator (request): method = code, identifier_first, lookup_secret, oidc, passkey, password, saml, totp, webauthn
# operationId: updateLoginFlow
export def "self-service-login updateLoginFlow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --flow: string # The Login Flow ID  The value for this parameter comes from `flow` URL Query parameter sent to your application (e.g. `/login?flow=abcde`).
  --X-Session-Token: string # The Session Token of the Identity performing the settings flow.
  --Cookie: string # HTTP Cookies  When using the SDK in a browser app, on the server side you must include the HTTP Cookie Header sent by the client to your server here. This ensures that CSRF and session cookies are respected.
  --csrf-token: string # Sending the anti-csrf token is only required for browser login flows.
  --identifier: string # Identifier is the email or username of the user trying to log in.
  method: string@method-completer # Method should be set to "password" when logging in using the identifier and password strategy.
  --password: string # The user's password.
  --password-identifier: string # Identifier is the email or username of the user trying to log in. This field is deprecated!
  --transient-payload: record # Transient data to pass along to any webhooks
  --id-token: string # IDToken is an optional id token provided by an OIDC provider  If submitted, it is verified using the OIDC provider's public key set and the claims are used to populate the OIDC credentials of the identity. If the OIDC provider does not store additional claims (such as name, etc.) in the IDToken itself, you can use the `traits` field to populate the identity's traits. Note, that Apple only includes the users email in the IDToken.  Supported providers are Apple Google
  --id-token-nonce: string # IDTokenNonce is the nonce, used when generating the IDToken. If the provider supports nonce validation, the nonce will be validated against this value and required.
  --provider: string # The provider to register with
  --traits: record # The identity traits. This is a placeholder for the registration flow.
  --upstream-parameters: record # UpstreamParameters are the parameters that are passed to the upstream identity provider.  These parameters are optional and depend on what the upstream identity provider supports. Supported parameters are: `login_hint` (string): The `login_hint` parameter suppresses the account chooser and either pre-fills the email box on the sign-in form, or selects the proper session. `hd` (string): The `hd` parameter limits the login/registration process to a Google Organization, e.g. `mycollege.edu`. `prompt` (string): The `prompt` specifies whether the Authorization Server prompts the End-User for reauthentication and consent, e.g. `select_account`. `acr_values` (string): The `acr_values` specifies the Authentication Context Class Reference values for the authorization request.
  --totp-code: string # The TOTP code.
  --webauthn-login: string # Login a WebAuthn Security Key  This must contain the ID of the WebAuthN connection.
  --lookup-secret: string # The lookup secret.
  --address: string # Address is the address to send the code to, in case that there are multiple addresses. This field is only used in two-factor flows and is ineffective for passwordless flows.
  --code: string # Code is the 6 digits code sent to the user
  --resend: string # Resend is set when the user wants to resend the code
  --passkey-login: string # Login a WebAuthn Security Key  This must contain the ID of the WebAuthN connection.
]: any -> record<continue_with: list<record>, session: record<active: bool, authenticated_at: string, authentication_methods: list<record>, authenticator_assurance_level: string, devices: list<record>, expires_at: string, id: string, identity: record<created_at: string, credentials: record, external_id: string, id: string, metadata_admin: any, metadata_public: any, organization_id: string, recovery_addresses: list, region: string, schema_id: string, schema_url: string, state: string, state_changed_at: string, traits: any, updated_at: string, verifiable_addresses: list>, issued_at: string, tokenized: string>, session_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "flow" $flow "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/self-service/login" $qp)
  let body = {csrf_token: $csrf_token, identifier: $identifier, method: $method, password: $password, password_identifier: $password_identifier, transient_payload: $transient_payload, id_token: $id_token, id_token_nonce: $id_token_nonce, provider: $provider, traits: $traits, upstream_parameters: $upstream_parameters, totp_code: $totp_code, webauthn_login: $webauthn_login, lookup_secret: $lookup_secret, address: $address, code: $code, resend: $resend, passkey_login: $passkey_login} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Session-Token": $X_Session_Token, "Cookie": $Cookie} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Login Flow for Native Apps
#
# GET /self-service/login/api
# operationId: createNativeLoginFlow
export def "self-service-login createNativeLoginFlow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --refresh: string@bool-completer # Refresh a login session  If set to true, this will refresh an existing login session by asking the user to sign in again. This will reset the authenticated_at time of the session.
  --aal: string # Request a Specific AuthenticationMethod Assurance Level  Use this parameter to upgrade an existing session's authenticator assurance level (AAL). This allows you to ask for multi-factor authentication. When an identity sign in using e.g. username+password, the AAL is 1. If you wish to "upgrade" the session's security by asking the user to perform TOTP / WebAuth/ ... you would set this to "aal2".
  --return-session-token-exchange-code: string@bool-completer # EnableSessionTokenExchangeCode requests the login flow to include a code that can be used to retrieve the session token after the login flow has been completed.
  --return-to: string # The URL to return the browser to after the flow was completed.
  --organization: string # An optional organization ID that should be used for logging this user in. This parameter is only effective in the Ory Network.
  --via: string # Via should contain the identity's credential the code should be sent to. Only relevant in aal2 flows.  DEPRECATED: This field is deprecated. Please remove it from your requests. The user will now see a choice of MFA credentials to choose from to perform the second factor instead.
  --identity-schema: string # An optional identity schema to use for the login flow.
  --X-Session-Token: string # The Session Token of the Identity performing the settings flow.
]: nothing -> record<active: string, created_at: string, expires_at: string, id: string, identity_schema: string, issued_at: string, oauth2_login_challenge: string, oauth2_login_request: record<challenge: string, client: record<access_token_strategy: string, allowed_cors_origins: list, audience: list, authorization_code_grant_access_token_lifespan: string, authorization_code_grant_id_token_lifespan: string, authorization_code_grant_refresh_token_lifespan: string, backchannel_logout_session_required: bool, backchannel_logout_uri: string, client_credentials_grant_access_token_lifespan: string, client_id: string, client_name: string, client_secret: string, client_secret_expires_at: int, client_uri: string, contacts: list, created_at: string, frontchannel_logout_session_required: bool, frontchannel_logout_uri: string, grant_types: list, implicit_grant_access_token_lifespan: string, implicit_grant_id_token_lifespan: string, jwks: any, jwks_uri: string, jwt_bearer_grant_access_token_lifespan: string, logo_uri: string, metadata: any, owner: string, policy_uri: string, post_logout_redirect_uris: list, redirect_uris: list, refresh_token_grant_access_token_lifespan: string, refresh_token_grant_id_token_lifespan: string, refresh_token_grant_refresh_token_lifespan: string, registration_access_token: string, registration_client_uri: string, request_object_signing_alg: string, request_uris: list, response_types: list, scope: string, sector_identifier_uri: string, skip_consent: bool, skip_logout_consent: bool, subject_type: string, token_endpoint_auth_method: string, token_endpoint_auth_signing_alg: string, tos_uri: string, updated_at: string, userinfo_signed_response_alg: string>, oidc_context: record<acr_values: list, display: string, id_token_hint_claims: record, login_hint: string, ui_locales: list>, request_url: string, requested_access_token_audience: list<string>, requested_scope: list<string>, session_id: string, skip: bool, subject: string>, organization_id: string, refresh: bool, request_url: string, requested_aal: string, return_to: string, session_token_exchange_code: string, state: any, test_context: record<debug_payload: record<error: record, id_token_claims: record, jsonnet_input: record, jsonnet_mapper_url: string, jsonnet_output: record, jsonnet_stderr: string, schema_validation_errors: list, userinfo: record>, provider_id: string>, transient_payload: record, type: string, ui: record<action: string, messages: list<record>, method: string, nodes: list<record>>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "refresh" $refresh "scalar") (serialize-qp "aal" $aal "scalar") (serialize-qp "return_session_token_exchange_code" $return_session_token_exchange_code "scalar") (serialize-qp "return_to" $return_to "scalar") (serialize-qp "organization" $organization "scalar") (serialize-qp "via" $via "scalar") (serialize-qp "identity_schema" $identity_schema "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/self-service/login/api" $qp)
  let extra_headers = {"X-Session-Token": $X_Session_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Login Flow for Browsers
#
# GET /self-service/login/browser
# operationId: createBrowserLoginFlow
export def "self-service-login-browser createBrowserLoginFlow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --refresh: string@bool-completer # Refresh a login session  If set to true, this will refresh an existing login session by asking the user to sign in again. This will reset the authenticated_at time of the session.
  --aal: string # Request a Specific AuthenticationMethod Assurance Level  Use this parameter to upgrade an existing session's authenticator assurance level (AAL). This allows you to ask for multi-factor authentication. When an identity sign in using e.g. username+password, the AAL is 1. If you wish to "upgrade" the session's security by asking the user to perform TOTP / WebAuth/ ... you would set this to "aal2".
  --return-to: string # The URL to return the browser to after the flow was completed.
  --login-challenge: string # An optional Hydra login challenge. If present, Kratos will cooperate with Ory Hydra to act as an OAuth2 identity provider.  The value for this parameter comes from `login_challenge` URL Query parameter sent to your application (e.g. `/login?login_challenge=abcde`).
  --organization: string # An optional organization ID that should be used for logging this user in. This parameter is only effective in the Ory Network.
  --via: string # Via should contain the identity's credential the code should be sent to. Only relevant in aal2 flows.  DEPRECATED: This field is deprecated. Please remove it from your requests. The user will now see a choice of MFA credentials to choose from to perform the second factor instead.
  --identity-schema: string # An optional identity schema to use for the login flow.
  --Cookie: string # HTTP Cookies  When using the SDK in a browser app, on the server side you must include the HTTP Cookie Header sent by the client to your server here. This ensures that CSRF and session cookies are respected.
]: nothing -> record<active: string, created_at: string, expires_at: string, id: string, identity_schema: string, issued_at: string, oauth2_login_challenge: string, oauth2_login_request: record<challenge: string, client: record<access_token_strategy: string, allowed_cors_origins: list, audience: list, authorization_code_grant_access_token_lifespan: string, authorization_code_grant_id_token_lifespan: string, authorization_code_grant_refresh_token_lifespan: string, backchannel_logout_session_required: bool, backchannel_logout_uri: string, client_credentials_grant_access_token_lifespan: string, client_id: string, client_name: string, client_secret: string, client_secret_expires_at: int, client_uri: string, contacts: list, created_at: string, frontchannel_logout_session_required: bool, frontchannel_logout_uri: string, grant_types: list, implicit_grant_access_token_lifespan: string, implicit_grant_id_token_lifespan: string, jwks: any, jwks_uri: string, jwt_bearer_grant_access_token_lifespan: string, logo_uri: string, metadata: any, owner: string, policy_uri: string, post_logout_redirect_uris: list, redirect_uris: list, refresh_token_grant_access_token_lifespan: string, refresh_token_grant_id_token_lifespan: string, refresh_token_grant_refresh_token_lifespan: string, registration_access_token: string, registration_client_uri: string, request_object_signing_alg: string, request_uris: list, response_types: list, scope: string, sector_identifier_uri: string, skip_consent: bool, skip_logout_consent: bool, subject_type: string, token_endpoint_auth_method: string, token_endpoint_auth_signing_alg: string, tos_uri: string, updated_at: string, userinfo_signed_response_alg: string>, oidc_context: record<acr_values: list, display: string, id_token_hint_claims: record, login_hint: string, ui_locales: list>, request_url: string, requested_access_token_audience: list<string>, requested_scope: list<string>, session_id: string, skip: bool, subject: string>, organization_id: string, refresh: bool, request_url: string, requested_aal: string, return_to: string, session_token_exchange_code: string, state: any, test_context: record<debug_payload: record<error: record, id_token_claims: record, jsonnet_input: record, jsonnet_mapper_url: string, jsonnet_output: record, jsonnet_stderr: string, schema_validation_errors: list, userinfo: record>, provider_id: string>, transient_payload: record, type: string, ui: record<action: string, messages: list<record>, method: string, nodes: list<record>>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "refresh" $refresh "scalar") (serialize-qp "aal" $aal "scalar") (serialize-qp "return_to" $return_to "scalar") (serialize-qp "login_challenge" $login_challenge "scalar") (serialize-qp "organization" $organization "scalar") (serialize-qp "via" $via "scalar") (serialize-qp "identity_schema" $identity_schema "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/self-service/login/browser" $qp)
  let extra_headers = {"Cookie": $Cookie} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Login Flow
#
# GET /self-service/login/flows
# operationId: getLoginFlow
export def "self-service-login-flows get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The Login Flow ID  The value for this parameter comes from `flow` URL Query parameter sent to your application (e.g. `/login?flow=abcde`).
  --Cookie: string # HTTP Cookies  When using the SDK in a browser app, on the server side you must include the HTTP Cookie Header sent by the client to your server here. This ensures that CSRF and session cookies are respected.
]: nothing -> record<active: string, created_at: string, expires_at: string, id: string, identity_schema: string, issued_at: string, oauth2_login_challenge: string, oauth2_login_request: record<challenge: string, client: record<access_token_strategy: string, allowed_cors_origins: list, audience: list, authorization_code_grant_access_token_lifespan: string, authorization_code_grant_id_token_lifespan: string, authorization_code_grant_refresh_token_lifespan: string, backchannel_logout_session_required: bool, backchannel_logout_uri: string, client_credentials_grant_access_token_lifespan: string, client_id: string, client_name: string, client_secret: string, client_secret_expires_at: int, client_uri: string, contacts: list, created_at: string, frontchannel_logout_session_required: bool, frontchannel_logout_uri: string, grant_types: list, implicit_grant_access_token_lifespan: string, implicit_grant_id_token_lifespan: string, jwks: any, jwks_uri: string, jwt_bearer_grant_access_token_lifespan: string, logo_uri: string, metadata: any, owner: string, policy_uri: string, post_logout_redirect_uris: list, redirect_uris: list, refresh_token_grant_access_token_lifespan: string, refresh_token_grant_id_token_lifespan: string, refresh_token_grant_refresh_token_lifespan: string, registration_access_token: string, registration_client_uri: string, request_object_signing_alg: string, request_uris: list, response_types: list, scope: string, sector_identifier_uri: string, skip_consent: bool, skip_logout_consent: bool, subject_type: string, token_endpoint_auth_method: string, token_endpoint_auth_signing_alg: string, tos_uri: string, updated_at: string, userinfo_signed_response_alg: string>, oidc_context: record<acr_values: list, display: string, id_token_hint_claims: record, login_hint: string, ui_locales: list>, request_url: string, requested_access_token_audience: list<string>, requested_scope: list<string>, session_id: string, skip: bool, subject: string>, organization_id: string, refresh: bool, request_url: string, requested_aal: string, return_to: string, session_token_exchange_code: string, state: any, test_context: record<debug_payload: record<error: record, id_token_claims: record, jsonnet_input: record, jsonnet_mapper_url: string, jsonnet_output: record, jsonnet_stderr: string, schema_validation_errors: list, userinfo: record>, provider_id: string>, transient_payload: record, type: string, ui: record<action: string, messages: list<record>, method: string, nodes: list<record>>, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/self-service/login/flows" $qp)
  let extra_headers = {"Cookie": $Cookie} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a test OIDC login flow
#
# DELETE /self-service/login/test
# operationId: deleteTestLoginFlow
export def "self-service-login-test delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # ID of the test login flow to delete.
  --Cookie: string # HTTP Cookies. A captured test flow requires the ory_kratos_test_flow cookie set by the OIDC callback; a flow still in the initial choose-method state does not.
]: nothing -> record<error: record<code: int, debug: string, details: record, id: string, message: string, reason: string, request: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/self-service/login/test" $qp)
  let extra_headers = {"Cookie": $Cookie} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Logout Flow
#
# GET /self-service/logout
# operationId: updateLogoutFlow
export def "self-service-logout updateLogoutFlow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-token: string # A Valid Logout Token  If you do not have a logout token because you only have a session cookie, call `/self-service/logout/browser` to generate a URL for this endpoint.
  --return-to: string # The URL to return to after the logout was completed.
  --Cookie: string # HTTP Cookies  When using the SDK in a browser app, on the server side you must include the HTTP Cookie Header sent by the client to your server here. This ensures that CSRF and session cookies are respected.
]: nothing -> record<error: record<code: int, debug: string, details: record, id: string, message: string, reason: string, request: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "token" $qp_token "scalar") (serialize-qp "return_to" $return_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/self-service/logout" $qp)
  let extra_headers = {"Cookie": $Cookie} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Perform Logout for Native Apps
#
# DELETE /self-service/logout/api
# operationId: performNativeLogout
export def "self-service-logout performNativeLogout" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  session_token: string # The Session Token  Invalidate this session token.
]: any -> record<error: record<code: int, debug: string, details: record, id: string, message: string, reason: string, request: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/self-service/logout/api")
  let body = {session_token: $session_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a Logout URL for Browsers
#
# GET /self-service/logout/browser
# operationId: createBrowserLogoutFlow
export def "self-service-logout-browser createBrowserLogoutFlow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --return-to: string # Return to URL  The URL to which the browser should be redirected to after the logout has been performed.
  --cookie: string # HTTP Cookies  If you call this endpoint from a backend, please include the original Cookie header in the request.
]: nothing -> record<logout_token: string, logout_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "return_to" $return_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/self-service/logout/browser" $qp)
  let extra_headers = {"cookie": $cookie} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Recovery Flow
#
# POST /self-service/recovery
# Discriminator (request): method = code, link
# operationId: updateRecoveryFlow
export def "self-service-recovery updateRecoveryFlow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --flow: string # The Recovery Flow ID  The value for this parameter comes from `flow` URL Query parameter sent to your application (e.g. `/recovery?flow=abcde`).
  --qp-token: string # Recovery Token  The recovery token which completes the recovery request. If the token is invalid (e.g. expired) an error will be shown to the end-user.  This parameter is usually set in a link and not used by any direct API call.
  --Cookie: string # HTTP Cookies  When using the SDK in a browser app, on the server side you must include the HTTP Cookie Header sent by the client to your server here. This ensures that CSRF and session cookies are respected.
  --csrf-token: string # Sending the anti-csrf token is only required for browser login flows.
  --email: string # Email to Recover  Needs to be set when initiating the flow. If the email is a registered recovery email, a recovery link will be sent. If the email is not known, an email with details on what happened will be sent instead.  format: email
  method: string@method-completer-1 # Method is the method that should be used for this recovery flow  Allowed values are `link` and `code` link RecoveryStrategyLink code RecoveryStrategyCode
  --transient-payload: record # Transient data to pass along to any webhooks
  --code: string # Code from the recovery email  If you want to submit a code, use this field, but make sure to _not_ include the email field, as well.
  --recovery-address: string # A recovery address that is registered for the user. It can be an email, a phone number (to receive the code via SMS), etc. Used in RecoveryV2.
  --recovery-confirm-address: string # If there are multiple recovery addresses registered for the user, and the initially provided address is different from the address chosen when the choice (of masked addresses) is presented, then we need to make sure that the user actually knows the full address to avoid information exfiltration, so we ask for the full address. Used in RecoveryV2.
  --recovery-select-address: string # If there are multiple addresses registered for the user, a choice is presented and this field stores the result of this choice. Addresses are 'masked' (never sent in full to the client and shown partially in the UI) since at this point in the recovery flow, the user has not yet proven that it knows the full address and we want to avoid information exfiltration. So for all intents and purposes, the value of this field should be treated as an opaque identifier. Used in RecoveryV2.
  --screen: string # Set to "previous" to go back in the flow, meaningfully. Used in RecoveryV2.
]: any -> record<active: string, continue_with: list<record>, expires_at: string, id: string, issued_at: string, request_url: string, return_to: string, state: any, transient_payload: record, type: string, ui: record<action: string, messages: list<record>, method: string, nodes: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "flow" $flow "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/self-service/recovery" $qp)
  let body = {csrf_token: $csrf_token, email: $email, method: $method, transient_payload: $transient_payload, code: $code, recovery_address: $recovery_address, recovery_confirm_address: $recovery_confirm_address, recovery_select_address: $recovery_select_address, screen: $screen} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Cookie": $Cookie} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Recovery Flow for Native Apps
#
# GET /self-service/recovery/api
# operationId: createNativeRecoveryFlow
export def "self-service-recovery createNativeRecoveryFlow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<active: string, continue_with: list<record>, expires_at: string, id: string, issued_at: string, request_url: string, return_to: string, state: any, transient_payload: record, type: string, ui: record<action: string, messages: list<record>, method: string, nodes: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/self-service/recovery/api")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Recovery Flow for Browsers
#
# GET /self-service/recovery/browser
# operationId: createBrowserRecoveryFlow
export def "self-service-recovery-browser createBrowserRecoveryFlow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --return-to: string # The URL to return the browser to after the flow was completed.
  --skip-settings: string # Skip redirection to the settings UI after the recovery flow was completed. Instead, the user will be redirected to the URL specified in `return_to` query parameter or the default return URL if `return_to` is not set.
]: nothing -> record<active: string, continue_with: list<record>, expires_at: string, id: string, issued_at: string, request_url: string, return_to: string, state: any, transient_payload: record, type: string, ui: record<action: string, messages: list<record>, method: string, nodes: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "return_to" $return_to "scalar") (serialize-qp "skip_settings" $skip_settings "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/self-service/recovery/browser" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Recovery Flow
#
# GET /self-service/recovery/flows
# operationId: getRecoveryFlow
export def "self-service-recovery-flows get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The Flow ID  The value for this parameter comes from `request` URL Query parameter sent to your application (e.g. `/recovery?flow=abcde`).
  --Cookie: string # HTTP Cookies  When using the SDK in a browser app, on the server side you must include the HTTP Cookie Header sent by the client to your server here. This ensures that CSRF and session cookies are respected.
]: nothing -> record<active: string, continue_with: list<record>, expires_at: string, id: string, issued_at: string, request_url: string, return_to: string, state: any, transient_payload: record, type: string, ui: record<action: string, messages: list<record>, method: string, nodes: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/self-service/recovery/flows" $qp)
  let extra_headers = {"Cookie": $Cookie} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Registration Flow
#
# POST /self-service/registration
# Discriminator (request): method = code, oidc, passkey, password, profile, saml, webauthn
# operationId: updateRegistrationFlow
export def "self-service-registration updateRegistrationFlow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --flow: string # The Registration Flow ID  The value for this parameter comes from `flow` URL Query parameter sent to your application (e.g. `/registration?flow=abcde`).
  --Cookie: string # HTTP Cookies  When using the SDK in a browser app, on the server side you must include the HTTP Cookie Header sent by the client to your server here. This ensures that CSRF and session cookies are respected.
  --csrf-token: string # The CSRF Token
  method: string@method-completer-2 # Method to use  This field must be set to `password` when using the password method.
  --password: string # Password to sign the user up with
  --traits: record # The identity's traits
  --transient-payload: record # Transient data to pass along to any webhooks
  --id-token: string # IDToken is an optional id token provided by an OIDC provider  If submitted, it is verified using the OIDC provider's public key set and the claims are used to populate the OIDC credentials of the identity. If the OIDC provider does not store additional claims (such as name, etc.) in the IDToken itself, you can use the `traits` field to populate the identity's traits. Note, that Apple only includes the users email in the IDToken.  Supported providers are Apple Google
  --id-token-nonce: string # IDTokenNonce is the nonce, used when generating the IDToken. If the provider supports nonce validation, the nonce will be validated against this value and is required.
  --provider: string # The provider to register with
  --upstream-parameters: record # UpstreamParameters are the parameters that are passed to the upstream identity provider.  These parameters are optional and depend on what the upstream identity provider supports. Supported parameters are: `login_hint` (string): The `login_hint` parameter suppresses the account chooser and either pre-fills the email box on the sign-in form, or selects the proper session. `hd` (string): The `hd` parameter limits the login/registration process to a Google Organization, e.g. `mycollege.edu`. `prompt` (string): The `prompt` specifies whether the Authorization Server prompts the End-User for reauthentication and consent, e.g. `select_account`. `acr_values` (string): The `acr_values` specifies the Authentication Context Class Reference values for the authorization request.
  --webauthn-register: string # Register a WebAuthn Security Key  It is expected that the JSON returned by the WebAuthn registration process is included here.
  --webauthn-register-displayname: string # Name of the WebAuthn Security Key to be Added  A human-readable name for the security key which will be added.
  --code: string # The OTP Code sent to the user
  --resend: string # Resend restarts the flow with a new code
  --passkey-register: string # Register a WebAuthn Security Key  It is expected that the JSON returned by the WebAuthn registration process is included here.
  --screen: string@screen-completer # Screen requests navigation to a previous screen.  This must be set to credential-selection to go back to the credential selection screen. credential-selection RegistrationScreenCredentialSelection nolint:gosec // not a credential previous RegistrationScreenPrevious
]: any -> record<continue_with: list<record>, identity: record<created_at: string, credentials: record, external_id: string, id: string, metadata_admin: any, metadata_public: any, organization_id: string, recovery_addresses: list<record>, region: string, schema_id: string, schema_url: string, state: string, state_changed_at: string, traits: any, updated_at: string, verifiable_addresses: list<record>>, session: record<active: bool, authenticated_at: string, authentication_methods: list<record>, authenticator_assurance_level: string, devices: list<record>, expires_at: string, id: string, identity: record<created_at: string, credentials: record, external_id: string, id: string, metadata_admin: any, metadata_public: any, organization_id: string, recovery_addresses: list, region: string, schema_id: string, schema_url: string, state: string, state_changed_at: string, traits: any, updated_at: string, verifiable_addresses: list>, issued_at: string, tokenized: string>, session_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "flow" $flow "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/self-service/registration" $qp)
  let body = {csrf_token: $csrf_token, method: $method, password: $password, traits: $traits, transient_payload: $transient_payload, id_token: $id_token, id_token_nonce: $id_token_nonce, provider: $provider, upstream_parameters: $upstream_parameters, webauthn_register: $webauthn_register, webauthn_register_displayname: $webauthn_register_displayname, code: $code, resend: $resend, passkey_register: $passkey_register, screen: $screen} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Cookie": $Cookie} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Registration Flow for Native Apps
#
# GET /self-service/registration/api
# operationId: createNativeRegistrationFlow
export def "self-service-registration createNativeRegistrationFlow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --return-session-token-exchange-code: string@bool-completer # EnableSessionTokenExchangeCode requests the login flow to include a code that can be used to retrieve the session token after the login flow has been completed.
  --return-to: string # The URL to return the browser to after the flow was completed.
  --organization: string # An optional organization ID that should be used to register this user. This parameter is only effective in the Ory Network.
  --identity-schema: string # An optional identity schema to use for the registration flow.
]: nothing -> record<active: string, expires_at: string, id: string, identity_schema: string, issued_at: string, oauth2_login_challenge: string, oauth2_login_request: record<challenge: string, client: record<access_token_strategy: string, allowed_cors_origins: list, audience: list, authorization_code_grant_access_token_lifespan: string, authorization_code_grant_id_token_lifespan: string, authorization_code_grant_refresh_token_lifespan: string, backchannel_logout_session_required: bool, backchannel_logout_uri: string, client_credentials_grant_access_token_lifespan: string, client_id: string, client_name: string, client_secret: string, client_secret_expires_at: int, client_uri: string, contacts: list, created_at: string, frontchannel_logout_session_required: bool, frontchannel_logout_uri: string, grant_types: list, implicit_grant_access_token_lifespan: string, implicit_grant_id_token_lifespan: string, jwks: any, jwks_uri: string, jwt_bearer_grant_access_token_lifespan: string, logo_uri: string, metadata: any, owner: string, policy_uri: string, post_logout_redirect_uris: list, redirect_uris: list, refresh_token_grant_access_token_lifespan: string, refresh_token_grant_id_token_lifespan: string, refresh_token_grant_refresh_token_lifespan: string, registration_access_token: string, registration_client_uri: string, request_object_signing_alg: string, request_uris: list, response_types: list, scope: string, sector_identifier_uri: string, skip_consent: bool, skip_logout_consent: bool, subject_type: string, token_endpoint_auth_method: string, token_endpoint_auth_signing_alg: string, tos_uri: string, updated_at: string, userinfo_signed_response_alg: string>, oidc_context: record<acr_values: list, display: string, id_token_hint_claims: record, login_hint: string, ui_locales: list>, request_url: string, requested_access_token_audience: list<string>, requested_scope: list<string>, session_id: string, skip: bool, subject: string>, organization_id: string, request_url: string, return_to: string, session_token_exchange_code: string, state: any, transient_payload: record, type: string, ui: record<action: string, messages: list<record>, method: string, nodes: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "return_session_token_exchange_code" $return_session_token_exchange_code "scalar") (serialize-qp "return_to" $return_to "scalar") (serialize-qp "organization" $organization "scalar") (serialize-qp "identity_schema" $identity_schema "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/self-service/registration/api" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Registration Flow for Browsers
#
# GET /self-service/registration/browser
# operationId: createBrowserRegistrationFlow
export def "self-service-registration-browser createBrowserRegistrationFlow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --return-to: string # The URL to return the browser to after the flow was completed.
  --login-challenge: string # Ory OAuth 2.0 Login Challenge.  If set will cooperate with Ory OAuth2 and OpenID to act as an OAuth2 server / OpenID Provider.  The value for this parameter comes from `login_challenge` URL Query parameter sent to your application (e.g. `/registration?login_challenge=abcde`).  This feature is compatible with Ory Hydra when not running on the Ory Network.
  --after-verification-return-to: string # The URL to return the browser to after the verification flow was completed.  After the registration flow is completed, the user will be sent a verification email. Upon completing the verification flow, this URL will be used to override the default `selfservice.flows.verification.after.default_redirect_to` value.
  --organization: string # An optional organization ID that should be used to register this user. This parameter is only effective in the Ory Network.
  --identity-schema: string # An optional identity schema to use for the registration flow.
]: nothing -> record<active: string, expires_at: string, id: string, identity_schema: string, issued_at: string, oauth2_login_challenge: string, oauth2_login_request: record<challenge: string, client: record<access_token_strategy: string, allowed_cors_origins: list, audience: list, authorization_code_grant_access_token_lifespan: string, authorization_code_grant_id_token_lifespan: string, authorization_code_grant_refresh_token_lifespan: string, backchannel_logout_session_required: bool, backchannel_logout_uri: string, client_credentials_grant_access_token_lifespan: string, client_id: string, client_name: string, client_secret: string, client_secret_expires_at: int, client_uri: string, contacts: list, created_at: string, frontchannel_logout_session_required: bool, frontchannel_logout_uri: string, grant_types: list, implicit_grant_access_token_lifespan: string, implicit_grant_id_token_lifespan: string, jwks: any, jwks_uri: string, jwt_bearer_grant_access_token_lifespan: string, logo_uri: string, metadata: any, owner: string, policy_uri: string, post_logout_redirect_uris: list, redirect_uris: list, refresh_token_grant_access_token_lifespan: string, refresh_token_grant_id_token_lifespan: string, refresh_token_grant_refresh_token_lifespan: string, registration_access_token: string, registration_client_uri: string, request_object_signing_alg: string, request_uris: list, response_types: list, scope: string, sector_identifier_uri: string, skip_consent: bool, skip_logout_consent: bool, subject_type: string, token_endpoint_auth_method: string, token_endpoint_auth_signing_alg: string, tos_uri: string, updated_at: string, userinfo_signed_response_alg: string>, oidc_context: record<acr_values: list, display: string, id_token_hint_claims: record, login_hint: string, ui_locales: list>, request_url: string, requested_access_token_audience: list<string>, requested_scope: list<string>, session_id: string, skip: bool, subject: string>, organization_id: string, request_url: string, return_to: string, session_token_exchange_code: string, state: any, transient_payload: record, type: string, ui: record<action: string, messages: list<record>, method: string, nodes: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "return_to" $return_to "scalar") (serialize-qp "login_challenge" $login_challenge "scalar") (serialize-qp "after_verification_return_to" $after_verification_return_to "scalar") (serialize-qp "organization" $organization "scalar") (serialize-qp "identity_schema" $identity_schema "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/self-service/registration/browser" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Registration Flow
#
# GET /self-service/registration/flows
# operationId: getRegistrationFlow
export def "self-service-registration-flows get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The Registration Flow ID  The value for this parameter comes from `flow` URL Query parameter sent to your application (e.g. `/registration?flow=abcde`).
  --Cookie: string # HTTP Cookies  When using the SDK in a browser app, on the server side you must include the HTTP Cookie Header sent by the client to your server here. This ensures that CSRF and session cookies are respected.
]: nothing -> record<active: string, expires_at: string, id: string, identity_schema: string, issued_at: string, oauth2_login_challenge: string, oauth2_login_request: record<challenge: string, client: record<access_token_strategy: string, allowed_cors_origins: list, audience: list, authorization_code_grant_access_token_lifespan: string, authorization_code_grant_id_token_lifespan: string, authorization_code_grant_refresh_token_lifespan: string, backchannel_logout_session_required: bool, backchannel_logout_uri: string, client_credentials_grant_access_token_lifespan: string, client_id: string, client_name: string, client_secret: string, client_secret_expires_at: int, client_uri: string, contacts: list, created_at: string, frontchannel_logout_session_required: bool, frontchannel_logout_uri: string, grant_types: list, implicit_grant_access_token_lifespan: string, implicit_grant_id_token_lifespan: string, jwks: any, jwks_uri: string, jwt_bearer_grant_access_token_lifespan: string, logo_uri: string, metadata: any, owner: string, policy_uri: string, post_logout_redirect_uris: list, redirect_uris: list, refresh_token_grant_access_token_lifespan: string, refresh_token_grant_id_token_lifespan: string, refresh_token_grant_refresh_token_lifespan: string, registration_access_token: string, registration_client_uri: string, request_object_signing_alg: string, request_uris: list, response_types: list, scope: string, sector_identifier_uri: string, skip_consent: bool, skip_logout_consent: bool, subject_type: string, token_endpoint_auth_method: string, token_endpoint_auth_signing_alg: string, tos_uri: string, updated_at: string, userinfo_signed_response_alg: string>, oidc_context: record<acr_values: list, display: string, id_token_hint_claims: record, login_hint: string, ui_locales: list>, request_url: string, requested_access_token_audience: list<string>, requested_scope: list<string>, session_id: string, skip: bool, subject: string>, organization_id: string, request_url: string, return_to: string, session_token_exchange_code: string, state: any, transient_payload: record, type: string, ui: record<action: string, messages: list<record>, method: string, nodes: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/self-service/registration/flows" $qp)
  let extra_headers = {"Cookie": $Cookie} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Complete Settings Flow
#
# POST /self-service/settings
# Discriminator (request): method = lookup_secret, oidc, passkey, password, profile, saml, totp, webauthn
# operationId: updateSettingsFlow
export def "self-service-settings updateSettingsFlow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --flow: string # The Settings Flow ID  The value for this parameter comes from `flow` URL Query parameter sent to your application (e.g. `/settings?flow=abcde`).
  --X-Session-Token: string # The Session Token of the Identity performing the settings flow.
  --Cookie: string # HTTP Cookies  When using the SDK in a browser app, on the server side you must include the HTTP Cookie Header sent by the client to your server here. This ensures that CSRF and session cookies are respected.
  --csrf-token: string # CSRFToken is the anti-CSRF token
  method: string@method-completer-3 # Method  Should be set to password when trying to update a password.
  --password: string # Password is the updated password
  --transient-payload: record # Transient data to pass along to any webhooks
  --traits: record # Traits  The identity's traits.
  --flow: string # Flow ID is the flow's ID.  in: query
  --link: string # Link this provider  Either this or `unlink` must be set.  type: string in: body
  --unlink: string # Unlink this provider  Either this or `link` must be set.  type: string in: body
  --upstream-parameters: record # UpstreamParameters are the parameters that are passed to the upstream identity provider.  These parameters are optional and depend on what the upstream identity provider supports. Supported parameters are: `login_hint` (string): The `login_hint` parameter suppresses the account chooser and either pre-fills the email box on the sign-in form, or selects the proper session. `hd` (string): The `hd` parameter limits the login/registration process to a Google Organization, e.g. `mycollege.edu`. `prompt` (string): The `prompt` specifies whether the Authorization Server prompts the End-User for reauthentication and consent, e.g. `select_account`. `acr_values` (string): The `acr_values` specifies the Authentication Context Class Reference values for the authorization request.
  --totp-code: string # ValidationTOTP must contain a valid TOTP based on the
  --totp-unlink: string@bool-completer # UnlinkTOTP if true will remove the TOTP pairing, effectively removing the credential. This can be used to set up a new TOTP device.
  --webauthn-register: string # Register a WebAuthn Security Key  It is expected that the JSON returned by the WebAuthn registration process is included here.
  --webauthn-register-displayname: string # Name of the WebAuthn Security Key to be Added  A human-readable name for the security key which will be added.
  --webauthn-remove: string # Remove a WebAuthn Security Key  This must contain the ID of the WebAuthN connection.
  --lookup-secret-confirm: string@bool-completer # If set to true will save the regenerated lookup secrets
  --lookup-secret-disable: string@bool-completer # Disables this method if true.
  --lookup-secret-regenerate: string@bool-completer # If set to true will regenerate the lookup secrets
  --lookup-secret-reveal: string@bool-completer # If set to true will reveal the lookup secrets
  --passkey-remove: string # Remove a WebAuthn Security Key  This must contain the ID of the WebAuthN connection.
  --passkey-settings-register: string # Register a WebAuthn Security Key  It is expected that the JSON returned by the WebAuthn registration process is included here.
]: any -> record<active: string, continue_with: list<record>, expires_at: string, id: string, identity: record<created_at: string, credentials: record, external_id: string, id: string, metadata_admin: any, metadata_public: any, organization_id: string, recovery_addresses: list<record>, region: string, schema_id: string, schema_url: string, state: string, state_changed_at: string, traits: any, updated_at: string, verifiable_addresses: list<record>>, issued_at: string, request_url: string, return_to: string, state: any, transient_payload: record, type: string, ui: record<action: string, messages: list<record>, method: string, nodes: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "flow" $flow "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/self-service/settings" $qp)
  let body = {csrf_token: $csrf_token, method: $method, password: $password, transient_payload: $transient_payload, traits: $traits, flow: $flow, link: $link, unlink: $unlink, upstream_parameters: $upstream_parameters, totp_code: $totp_code, totp_unlink: $totp_unlink, webauthn_register: $webauthn_register, webauthn_register_displayname: $webauthn_register_displayname, webauthn_remove: $webauthn_remove, lookup_secret_confirm: $lookup_secret_confirm, lookup_secret_disable: $lookup_secret_disable, lookup_secret_regenerate: $lookup_secret_regenerate, lookup_secret_reveal: $lookup_secret_reveal, passkey_remove: $passkey_remove, passkey_settings_register: $passkey_settings_register} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Session-Token": $X_Session_Token, "Cookie": $Cookie} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Settings Flow for Native Apps
#
# GET /self-service/settings/api
# operationId: createNativeSettingsFlow
export def "self-service-settings createNativeSettingsFlow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Session-Token: string # The Session Token of the Identity performing the settings flow.
]: nothing -> record<active: string, continue_with: list<record>, expires_at: string, id: string, identity: record<created_at: string, credentials: record, external_id: string, id: string, metadata_admin: any, metadata_public: any, organization_id: string, recovery_addresses: list<record>, region: string, schema_id: string, schema_url: string, state: string, state_changed_at: string, traits: any, updated_at: string, verifiable_addresses: list<record>>, issued_at: string, request_url: string, return_to: string, state: any, transient_payload: record, type: string, ui: record<action: string, messages: list<record>, method: string, nodes: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/self-service/settings/api")
  let extra_headers = {"X-Session-Token": $X_Session_Token} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Settings Flow for Browsers
#
# GET /self-service/settings/browser
# operationId: createBrowserSettingsFlow
export def "self-service-settings-browser createBrowserSettingsFlow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --return-to: string # The URL to return the browser to after the flow was completed.
  --Cookie: string # HTTP Cookies  When using the SDK in a browser app, on the server side you must include the HTTP Cookie Header sent by the client to your server here. This ensures that CSRF and session cookies are respected.
]: nothing -> record<active: string, continue_with: list<record>, expires_at: string, id: string, identity: record<created_at: string, credentials: record, external_id: string, id: string, metadata_admin: any, metadata_public: any, organization_id: string, recovery_addresses: list<record>, region: string, schema_id: string, schema_url: string, state: string, state_changed_at: string, traits: any, updated_at: string, verifiable_addresses: list<record>>, issued_at: string, request_url: string, return_to: string, state: any, transient_payload: record, type: string, ui: record<action: string, messages: list<record>, method: string, nodes: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "return_to" $return_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/self-service/settings/browser" $qp)
  let extra_headers = {"Cookie": $Cookie} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Settings Flow
#
# GET /self-service/settings/flows
# operationId: getSettingsFlow
export def "self-service-settings-flows get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # ID is the Settings Flow ID  The value for this parameter comes from `flow` URL Query parameter sent to your application (e.g. `/settings?flow=abcde`).
  --X-Session-Token: string # The Session Token  When using the SDK in an app without a browser, please include the session token here.
  --Cookie: string # HTTP Cookies  When using the SDK in a browser app, on the server side you must include the HTTP Cookie Header sent by the client to your server here. This ensures that CSRF and session cookies are respected.
]: nothing -> record<active: string, continue_with: list<record>, expires_at: string, id: string, identity: record<created_at: string, credentials: record, external_id: string, id: string, metadata_admin: any, metadata_public: any, organization_id: string, recovery_addresses: list<record>, region: string, schema_id: string, schema_url: string, state: string, state_changed_at: string, traits: any, updated_at: string, verifiable_addresses: list<record>>, issued_at: string, request_url: string, return_to: string, state: any, transient_payload: record, type: string, ui: record<action: string, messages: list<record>, method: string, nodes: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/self-service/settings/flows" $qp)
  let extra_headers = {"X-Session-Token": $X_Session_Token, "Cookie": $Cookie} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Complete Verification Flow
#
# POST /self-service/verification
# Discriminator (request): method = code, link
# operationId: updateVerificationFlow
export def "self-service-verification updateVerificationFlow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --flow: string # The Verification Flow ID  The value for this parameter comes from `flow` URL Query parameter sent to your application (e.g. `/verification?flow=abcde`).
  --qp-token: string # Verification Token  The verification token which completes the verification request. If the token is invalid (e.g. expired) an error will be shown to the end-user.  This parameter is usually set in a link and not used by any direct API call.
  --Cookie: string # HTTP Cookies  When using the SDK in a browser app, on the server side you must include the HTTP Cookie Header sent by the client to your server here. This ensures that CSRF and session cookies are respected.
  --csrf-token: string # Sending the anti-csrf token is only required for browser login flows.
  --email: string # Email to Verify  Needs to be set when initiating the flow. If the email is a registered verification email, a verification link will be sent. If the email is not known, a email with details on what happened will be sent instead.  format: email
  method: string@method-completer-1 # Method is the method that should be used for this verification flow  Allowed values are `link` and `code` link VerificationStrategyLink code VerificationStrategyCode
  --transient-payload: record # Transient data to pass along to any webhooks
  --code: string # Code from the recovery email  If you want to submit a code, use this field, but make sure to _not_ include the email field, as well.
]: any -> record<active: string, expires_at: string, id: string, issued_at: string, request_url: string, return_to: string, state: any, transient_payload: record, type: string, ui: record<action: string, messages: list<record>, method: string, nodes: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "flow" $flow "scalar") (serialize-qp "token" $qp_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/self-service/verification" $qp)
  let body = {csrf_token: $csrf_token, email: $email, method: $method, transient_payload: $transient_payload, code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Cookie": $Cookie} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Verification Flow for Native Apps
#
# GET /self-service/verification/api
# operationId: createNativeVerificationFlow
export def "self-service-verification createNativeVerificationFlow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --return-to: string # A URL contained in the return_to key of the verification flow. This piece of data has no effect on the actual logic of the flow and is purely informational.
]: nothing -> record<active: string, expires_at: string, id: string, issued_at: string, request_url: string, return_to: string, state: any, transient_payload: record, type: string, ui: record<action: string, messages: list<record>, method: string, nodes: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "return_to" $return_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/self-service/verification/api" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Verification Flow for Browser Clients
#
# GET /self-service/verification/browser
# operationId: createBrowserVerificationFlow
export def "self-service-verification-browser createBrowserVerificationFlow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --return-to: string # The URL to return the browser to after the flow was completed.
]: nothing -> record<active: string, expires_at: string, id: string, issued_at: string, request_url: string, return_to: string, state: any, transient_payload: record, type: string, ui: record<action: string, messages: list<record>, method: string, nodes: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "return_to" $return_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/self-service/verification/browser" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Verification Flow
#
# GET /self-service/verification/flows
# operationId: getVerificationFlow
export def "self-service-verification-flows get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: string # The Flow ID  The value for this parameter comes from `request` URL Query parameter sent to your application (e.g. `/verification?flow=abcde`).
  --cookie: string # HTTP Cookies  When using the SDK on the server side you must include the HTTP Cookie Header originally sent to your HTTP handler here.
]: nothing -> record<active: string, expires_at: string, id: string, issued_at: string, request_url: string, return_to: string, state: any, transient_payload: record, type: string, ui: record<action: string, messages: list<record>, method: string, nodes: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/self-service/verification/flows" $qp)
  let extra_headers = {"cookie": $cookie} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable my other sessions
#
# DELETE /sessions
# operationId: disableMyOtherSessions
export def "sessions disableMyOtherSessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Session-Token: string # Set the Session Token when calling from non-browser clients. A session token has a format of `MP2YWEMeM8MxjkGKpH4dqOQ4Q4DlSPaj`.
  --Cookie: string # Set the Cookie Header. This is especially useful when calling this endpoint from a server-side application. In that scenario you must include the HTTP Cookie Header which originally was included in the request to your server. An example of a session in the HTTP Cookie Header is: `ory_kratos_session=a19iOVAbdzdgl70Rq1QZmrKmcjDtdsviCTZx7m9a9yHIUS8Wa9T7hvqyGTsLHi6Qifn2WUfpAKx9DWp0SJGleIn9vh2YF4A16id93kXFTgIgmwIOvbVAScyrx7yVl6bPZnCx27ec4WQDtaTewC1CpgudeDV2jQQnSaCP6ny3xa8qLH-QUgYqdQuoA_LF1phxgRCUfIrCLQOkolX5nv3ze_f==`.  It is ok if more than one cookie are included here as all other cookies will be ignored.
]: nothing -> record<count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sessions")
  let extra_headers = {"X-Session-Token": $X_Session_Token, "Cookie": $Cookie} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get My Active Sessions
#
# GET /sessions
# operationId: listMySessions
export def "sessions listMySessions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --per-page: int # Deprecated Items per Page  DEPRECATED: Please use `page_token` instead. This parameter will be removed in the future.  This is the number of items per page. (format: int64, default: 250)
  --page: int # Deprecated Pagination Page  DEPRECATED: Please use `page_token` instead. This parameter will be removed in the future.  This value is currently an integer, but it is not sequential. The value is not the page number, but a reference. The next page can be any number and some numbers might return an empty list.  For example, page 2 might not follow after page 1. And even if page 3 and 5 exist, but page 4 might not exist. The first page can be retrieved by omitting this parameter. Following page pointers will be returned in the `Link` header. (format: int64)
  --page-size: int # Page Size  This is the number of items per page to return. For details on pagination please head over to the [pagination documentation](https://www.ory.com/docs/ecosystem/api-design#pagination). (format: int64, default: 250)
  --page-token: string # Next Page Token  The next page token. For details on pagination please head over to the [pagination documentation](https://www.ory.com/docs/ecosystem/api-design#pagination).
  --X-Session-Token: string # Set the Session Token when calling from non-browser clients. A session token has a format of `MP2YWEMeM8MxjkGKpH4dqOQ4Q4DlSPaj`.
  --Cookie: string # Set the Cookie Header. This is especially useful when calling this endpoint from a server-side application. In that scenario you must include the HTTP Cookie Header which originally was included in the request to your server. An example of a session in the HTTP Cookie Header is: `ory_kratos_session=a19iOVAbdzdgl70Rq1QZmrKmcjDtdsviCTZx7m9a9yHIUS8Wa9T7hvqyGTsLHi6Qifn2WUfpAKx9DWp0SJGleIn9vh2YF4A16id93kXFTgIgmwIOvbVAScyrx7yVl6bPZnCx27ec4WQDtaTewC1CpgudeDV2jQQnSaCP6ny3xa8qLH-QUgYqdQuoA_LF1phxgRCUfIrCLQOkolX5nv3ze_f==`.  It is ok if more than one cookie are included here as all other cookies will be ignored.
]: nothing -> record<error: record<code: int, debug: string, details: record, id: string, message: string, reason: string, request: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "page_size" $page_size "scalar") (serialize-qp "page_token" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sessions" $qp)
  let extra_headers = {"X-Session-Token": $X_Session_Token, "Cookie": $Cookie} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Exchange Session Token
#
# GET /sessions/token-exchange
# operationId: exchangeSessionToken
export def "sessions-token-exchange exchangeSessionToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --init-code: string # The part of the code return when initializing the flow.
  --return-to-code: string # The part of the code returned by the return_to URL.
]: nothing -> record<continue_with: list<record>, session: record<active: bool, authenticated_at: string, authentication_methods: list<record>, authenticator_assurance_level: string, devices: list<record>, expires_at: string, id: string, identity: record<created_at: string, credentials: record, external_id: string, id: string, metadata_admin: any, metadata_public: any, organization_id: string, recovery_addresses: list, region: string, schema_id: string, schema_url: string, state: string, state_changed_at: string, traits: any, updated_at: string, verifiable_addresses: list>, issued_at: string, tokenized: string>, session_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "init_code" $init_code "scalar") (serialize-qp "return_to_code" $return_to_code "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sessions/token-exchange" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check Who the Current HTTP Session Belongs To
#
# GET /sessions/whoami
# operationId: toSession
export def "sessions-whoami toSession" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tokenize-as: string # Returns the session additionally as a token (such as a JWT)  The value of this parameter has to be a valid, configured Ory Session token template. For more information head over to [the documentation](http://ory.sh/docs/identities/session-to-jwt-cors).
  --X-Session-Token: string # Set the Session Token when calling from non-browser clients. A session token has a format of `MP2YWEMeM8MxjkGKpH4dqOQ4Q4DlSPaj`. (e.g. MP2YWEMeM8MxjkGKpH4dqOQ4Q4DlSPaj)
  --Cookie: string # Set the Cookie Header. This is especially useful when calling this endpoint from a server-side application. In that scenario you must include the HTTP Cookie Header which originally was included in the request to your server. An example of a session in the HTTP Cookie Header is: `ory_kratos_session=a19iOVAbdzdgl70Rq1QZmrKmcjDtdsviCTZx7m9a9yHIUS8Wa9T7hvqyGTsLHi6Qifn2WUfpAKx9DWp0SJGleIn9vh2YF4A16id93kXFTgIgmwIOvbVAScyrx7yVl6bPZnCx27ec4WQDtaTewC1CpgudeDV2jQQnSaCP6ny3xa8qLH-QUgYqdQuoA_LF1phxgRCUfIrCLQOkolX5nv3ze_f==`.  It is ok if more than one cookie are included here as all other cookies will be ignored. (e.g. ory_session=a19iOVAbdzdgl70Rq1QZmrKmcjDtdsviCTZx7m9a9yHIUS8Wa9T7hvqyGTsLHi6Qifn2WUfpAKx9DWp0SJGleIn9vh2YF4A16id93kXFTgIgmwIOvbVAScyrx7yVl6bPZnCx27ec4WQDtaTewC1CpgudeDV2jQQnSaCP6ny3xa8qLH-QUgYqdQuoA_LF1phxgRCUfIrCLQOkolX5nv3ze_f==)
]: nothing -> record<active: bool, authenticated_at: string, authentication_methods: table<aal: string, completed_at: string, method: string, organization: string, provider: string, upstream_acr: string, upstream_amr: list>, authenticator_assurance_level: string, devices: table<id: string, ip_address: string, location: string, user_agent: string>, expires_at: string, id: string, identity: record<created_at: string, credentials: record, external_id: string, id: string, metadata_admin: any, metadata_public: any, organization_id: string, recovery_addresses: list<record>, region: string, schema_id: string, schema_url: string, state: string, state_changed_at: string, traits: any, updated_at: string, verifiable_addresses: list<record>>, issued_at: string, tokenized: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "tokenize_as" $tokenize_as "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sessions/whoami" $qp)
  let extra_headers = {"X-Session-Token": $X_Session_Token, "Cookie": $Cookie} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Disable one of my sessions
#
# DELETE /sessions/{id}
# operationId: disableMySession
export def "sessions disableMySession" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Session-Token: string # Set the Session Token when calling from non-browser clients. A session token has a format of `MP2YWEMeM8MxjkGKpH4dqOQ4Q4DlSPaj`.
  --Cookie: string # Set the Cookie Header. This is especially useful when calling this endpoint from a server-side application. In that scenario you must include the HTTP Cookie Header which originally was included in the request to your server. An example of a session in the HTTP Cookie Header is: `ory_kratos_session=a19iOVAbdzdgl70Rq1QZmrKmcjDtdsviCTZx7m9a9yHIUS8Wa9T7hvqyGTsLHi6Qifn2WUfpAKx9DWp0SJGleIn9vh2YF4A16id93kXFTgIgmwIOvbVAScyrx7yVl6bPZnCx27ec4WQDtaTewC1CpgudeDV2jQQnSaCP6ny3xa8qLH-QUgYqdQuoA_LF1phxgRCUfIrCLQOkolX5nv3ze_f==`.  It is ok if more than one cookie are included here as all other cookies will be ignored.
]: nothing -> record<error: record<code: int, debug: string, details: record, id: string, message: string, reason: string, request: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sessions/($id)")
  let extra_headers = {"X-Session-Token": $X_Session_Token, "Cookie": $Cookie} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Return Running Software Version.
#
# GET /version
# operationId: getVersion
export def "version get" [
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
  let full_url = (build-url $base "/version")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
