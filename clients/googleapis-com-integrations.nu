# Auto-generated client for Application Integration API vv1
# Source: https://api.apis.guru/v2/specs/googleapis.com/integrations/v1/openapi.json
# Auth: --token flag or $env.APPLICATION_INTEGRATION_API_TOKEN

const BASE_URL = "https://integrations.googleapis.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o APPLICATION_INTEGRATION_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://integrations.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def product-completer [] { ["APIGEE" "IP" "SECURITY" "UNSPECIFIED_PRODUCT"] }
def fileFormat-completer [] { ["FILE_FORMAT_UNSPECIFIED" "JSON" "YAML"] }
def credentialType-completer [] { ["API_KEY" "AUTH_TOKEN" "CLIENT_CERTIFICATE_ONLY" "CREDENTIAL_TYPE_UNSPECIFIED" "JWT" "OAUTH2_AUTHORIZATION_CODE" "OAUTH2_CLIENT_CREDENTIALS" "OAUTH2_IMPLICIT" "OAUTH2_RESOURCE_OWNER_CREDENTIALS" "OIDC_TOKEN" "SERVICE_ACCOUNT" "USERNAME_AND_PASSWORD"] }
def state-completer [] { ["EXPIRED" "INVALID" "SOFT_DELETED" "STATE_UNSPECIFIED" "UNAUTHORIZED" "UNSUPPORTED" "VALID"] }
def visibility-completer [] { ["AUTH_CONFIG_VISIBILITY_UNSPECIFIED" "CLIENT_VISIBLE" "PRIVATE"] }
def certificateStatus-completer [] { ["ACTIVE" "EXPIRED" "STATE_UNSPECIFIED"] }
def databasePersistencePolicy-completer [] { ["DATABASE_PERSISTENCE_DISABLED" "DATABASE_PERSISTENCE_POLICY_UNSPECIFIED"] }
def origin-completer [] { ["APPLICATION_IP_PROVISIONING" "PIPER_V2" "PIPER_V3" "UI" "UNSPECIFIED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "callback-generate-token integrationscallbackgenerateToken" } } | get name | first)
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

# Receives the auth code and auth config id to combine that with the client id and secret to retrieve access tokens from the token endpoint. Returns either a success or error message when it's done.
#
# GET /v1/callback:generateToken
# operationId: integrations.callback.generateToken
export def "callback-generate-token integrationscallbackgenerateToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --code: string # The auth code for the given request
  --gcpProjectId: string # The gcp project id of the request
  --product: string@product-completer # Which product sends the request
  --redirectUri: string # Redirect uri of the auth code request
  --state: string # The auth config id for the given request
]: nothing -> record<message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "code" $code "scalar") (serialize-qp "gcpProjectId" $gcpProjectId "scalar") (serialize-qp "product" $product "scalar") (serialize-qp "redirectUri" $redirectUri "scalar") (serialize-qp "state" $state "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/callback:generateToken" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enumerates the regions for which Connector Platform is provisioned.
#
# GET /v1/connectorPlatformRegions:enumerate
# operationId: integrations.connectorPlatformRegions.enumerate
export def "connector-platform-regions-enumerate integrationsconnectorPlatformRegionsenumerate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<regions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/connectorPlatformRegions:enumerate" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Clears the `locked_by` and `locked_at_timestamp`in the DRAFT version of this integration. It then performs the same action as the CreateDraftIntegrationVersion (i.e., copies the DRAFT version of the integration as a SNAPSHOT and then creates a new DRAFT version with the `locked_by` set to the `user_taking_over` and the `locked_at_timestamp` set to the current timestamp). Both the `locked_by` and `user_taking_over` are notified via email about the takeover. This RPC throws an exception if the integration is not in DRAFT status or if the `locked_by` and `locked_at_timestamp` fields are not set.The TakeoverEdit lock is treated the same as an edit of the integration, and hence shares ACLs with edit. Audit fields updated include last_modified_timestamp, last_modified_by.
#
# POST /v1/{integrationVersion}:takeoverEditLock
# operationId: integrations.projects.locations.products.integrations.versions.takeoverEditLock
export def "projects integrationsprojectslocationsproductsintegrationsversionstakeoverEditLock" [
  integrationVersion: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body: record
]: any -> record<integrationVersion: record<createTime: string, databasePersistencePolicy: string, description: string, errorCatcherConfigs: list<record>, integrationParameters: list<record>, integrationParametersInternal: record<parameters: list>, lastModifierEmail: string, lockHolder: string, name: string, origin: string, parentTemplateId: string, runAsServiceAccount: string, snapshotNumber: string, state: string, status: string, taskConfigs: list<record>, taskConfigsInternal: list<record>, teardown: record<teardownTaskConfigs: list>, triggerConfigs: list<record>, triggerConfigsInternal: list<record>, updateTime: string, userLabel: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($integrationVersion):takeoverEditLock" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes an sfdc channel.
#
# DELETE /v1/{name}
# operationId: integrations.projects.locations.sfdcInstances.sfdcChannels.delete
export def "projects integrationsprojectslocationssfdcInstancessfdcChannelsdelete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets an sfdc channel. If the channel doesn't exist, Code.NOT_FOUND exception will be thrown.
#
# GET /v1/{name}
# operationId: integrations.projects.locations.sfdcInstances.sfdcChannels.get
export def "projects integrationsprojectslocationssfdcInstancessfdcChannelsget" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<channelTopic: string, createTime: string, deleteTime: string, description: string, displayName: string, isActive: bool, lastReplayId: string, name: string, updateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an sfdc channel. Updates the sfdc channel in spanner. Returns the sfdc channel.
#
# PATCH /v1/{name}
# operationId: integrations.projects.locations.sfdcInstances.sfdcChannels.patch
export def "projects integrationsprojectslocationssfdcInstancessfdcChannelspatch" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --updateMask: string # Field mask specifying the fields in the above SfdcChannel that have been modified and need to be updated.
  --clientCertificatepassphrase: string # 'passphrase' should be left unset if private key is not encrypted. Note that 'passphrase' is not the password for web server, but an extra layer of security to protected private key.
  --clientCertificatesslCertificate: string # The ssl certificate encoded in PEM format. This string must include the begin header and end footer lines. For example, -----BEGIN CERTIFICATE----- MIICTTCCAbagAwIBAgIJAPT0tSKNxan/MA0GCSqGSIb3DQEBCwUAMCoxFzAVBgNV BAoTDkdvb2dsZSBURVNUSU5HMQ8wDQYDVQQDEwZ0ZXN0Q0EwHhcNMTUwMTAxMDAw MDAwWhcNMjUwMTAxMDAwMDAwWjAuMRcwFQYDVQQKEw5Hb29nbGUgVEVTVElORzET MBEGA1UEAwwKam9lQGJhbmFuYTCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEA vDYFgMgxi5W488d9J7UpCInl0NXmZQpJDEHE4hvkaRlH7pnC71H0DLt0/3zATRP1 JzY2+eqBmbGl4/sgZKYv8UrLnNyQNUTsNx1iZAfPUflf5FwgVsai8BM0pUciq1NB xD429VFcrGZNucvFLh72RuRFIKH8WUpiK/iZNFkWhZ0CAwEAAaN3MHUwDgYDVR0P AQH/BAQDAgWgMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAMBgNVHRMB Af8EAjAAMBkGA1UdDgQSBBCVgnFBCWgL/iwCqnGrhTPQMBsGA1UdIwQUMBKAEKey Um2o4k2WiEVA0ldQvNYwDQYJKoZIhvcNAQELBQADgYEAYK986R4E3L1v+Q6esBtW JrUwA9UmJRSQr0N5w3o9XzarU37/bkjOP0Fw0k/A6Vv1n3vlciYfBFaBIam1qRHr 5dMsYf4CZS6w50r7hyzqyrwDoyNxkLnd2PdcHT/sym1QmflsjEs7pejtnohO6N2H wQW6M0H7Zt8claGRla4fKkg= -----END CERTIFICATE-----
  --channelTopic: string # The Channel topic defined by salesforce once an channel is opened
  --description: string # The description for this channel
  --displayName: string # Client level unique name/alias to easily reference a channel.
  --isActive: oneof<nothing, bool> # Indicated if a channel has any active integrations referencing it. Set to false when the channel is created, and set to true if there is any integration published with the channel configured in it.
  --lastReplayId: string # Last sfdc messsage replay id for channel
  --body-name: string # Resource name of the SFDC channel projects/{project}/locations/{location}/sfdcInstances/{sfdc_instance}/sfdcChannels/{sfdc_channel}.
]: any -> record<channelTopic: string, createTime: string, deleteTime: string, description: string, displayName: string, isActive: bool, lastReplayId: string, name: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "updateMask" $updateMask "scalar") (serialize-qp "clientCertificate.passphrase" $clientCertificatepassphrase "scalar") (serialize-qp "clientCertificate.sslCertificate" $clientCertificatesslCertificate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($name)" $qp)
  let body = {channelTopic: $channelTopic, description: $description, displayName: $displayName, isActive: $isActive, lastReplayId: $lastReplayId, name: $body_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancellation of an execution
#
# POST /v1/{name}:cancel
# operationId: integrations.projects.locations.products.integrations.executions.cancel
export def "projects integrationsprojectslocationsproductsintegrationsexecutionscancel" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body: record
]: any -> record<isCanceled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($name):cancel" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Downloads an integration. Retrieves the `IntegrationVersion` for a given `integration_id` and returns the response as a string.
#
# GET /v1/{name}:download
# operationId: integrations.projects.locations.products.integrations.versions.download
export def "projects integrationsprojectslocationsproductsintegrationsversionsdownload" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --fileFormat: string@fileFormat-completer # File format for download request.
]: nothing -> record<content: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "fileFormat" $fileFormat "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($name):download" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Executes integrations synchronously by passing the trigger id in the request body. The request is not returned until the requested executions are either fulfilled or experienced an error. If the integration name is not specified (passing `-`), all of the associated integration under the given trigger_id will be executed. Otherwise only the specified integration for the given `trigger_id` is executed. This is helpful for execution the integration from UI.
#
# POST /v1/{name}:execute
# operationId: integrations.projects.locations.products.integrations.execute
# --parameterEntries item shape: {dataType?: "DATA_TYPE_UNSPECIFIED"|"STRING_VALUE"|"INT_VALUE"|"DOUBLE_VALUE"|"BOOLEAN_VALUE"|"PROTO_VALUE"|"SERIALIZED_OBJECT_VALUE"|"STRING_ARRAY"|"INT_ARRAY"|"DOUBLE_ARRAY"|"PROTO_ARRAY"|"PROTO_ENUM"|"BOOLEAN_ARRAY"|"PROTO_ENUM_ARRAY"|"BYTES"|"BYTES_ARRAY"|"NON_SERIALIZABLE_OBJECT"|"JSON_VALUE", key?: string, value?: record}
# --parameters shape: {parameters?: list}
export def "projects integrationsprojectslocationsproductsintegrationsexecute" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --doNotPropagateError: oneof<nothing, bool> # Optional. Flag to determine how to should propagate errors. If this flag is set to be true, it will not throw an exception. Instead, it will return a {@link ExecuteIntegrationsResponse} with an execution id and error messages as PostWithTriggerIdExecutionException in {@link EventParameters}. The flag is set to be false by default.
  --executionId: string # Optional. The id of the ON_HOLD execution to be resumed.
  --inputParameters: record # Optional. Input parameters used by integration execution.
  --parameterEntries: list # Optional. Parameters are a part of Event and can be used to communicate between different tasks that are part of the same integration execution. — item shape: {dataType?: "DATA_TYPE_UNSPECIFIED"|"STRING_VALUE"|"INT_VALUE"|"DOUBLE_VALUE"|"BOOLEAN_VALUE"|"PROTO_VALUE"|"SERIALIZED_OBJECT_VALUE"|"STRING_ARRAY"|"INT_ARRAY"|"DOUBLE_ARRAY"|"PROTO_ARRAY"|"PROTO_ENUM"|"BOOLEAN_ARRAY"|"PROTO_ENUM_ARRAY"|"BYTES"|"BYTES_ARRAY"|"NON_SERIALIZABLE_OBJECT"|"JSON_VALUE", key?: string, value?: record}
  --parameters: record # LINT.IfChange This message is used for processing and persisting (when applicable) key value pair parameters for each event in the event bus. Please see — shape: {parameters?: list}
  --requestId: string # Optional. This is used to de-dup incoming request: if the duplicate request was detected, the response from the previous execution is returned.
  --triggerId: string # Required. Matched against all {@link TriggerConfig}s across all integrations. i.e. TriggerConfig.trigger_id.equals(trigger_id). The trigger_id is in the format of `api_trigger/TRIGGER_NAME`.
]: any -> record<eventParameters: record<parameters: list<record>>, executionFailed: bool, executionId: string, outputParameters: record, parameterEntries: table<dataType: string, key: string, value: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($name):execute" $qp)
  let body = {doNotPropagateError: $doNotPropagateError, executionId: $executionId, inputParameters: $inputParameters, parameterEntries: $parameterEntries, parameters: $parameters, requestId: $requestId, triggerId: $triggerId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# * Lifts suspension for advanced suspension task. Fetch corresponding suspension with provided suspension Id, resolve suspension, and set up suspension result for the Suspension Task.
#
# POST /v1/{name}:lift
# operationId: integrations.projects.locations.products.integrations.executions.suspensions.lift
export def "projects integrationsprojectslocationsproductsintegrationsexecutionssuspensionslift" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --suspensionResult: string # User passed in suspension result and will be used to control workflow execution branching behavior by setting up corresponnding edge condition with suspension result. For example, if you want to lift the suspension, you can pass "Approved", or if you want to reject the suspension and terminate workfloe execution, you can pass "Rejected" and terminate the workflow execution with configuring the edge condition.
]: any -> record<eventExecutionInfoId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($name):lift" $qp)
  let body = {suspensionResult: $suspensionResult} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# This RPC throws an exception if the integration is in ARCHIVED or ACTIVE state. This RPC throws an exception if the version being published is DRAFT, and if the `locked_by` user is not the same as the user performing the Publish. Audit fields updated include last_published_timestamp, last_published_by, last_modified_timestamp, last_modified_by. Any existing lock is on this integration is released.
#
# POST /v1/{name}:publish
# operationId: integrations.projects.locations.products.integrations.versions.publish
export def "projects integrationsprojectslocationsproductsintegrationsversionspublish" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($name):publish" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# * Resolves (lifts/rejects) any number of suspensions. If the integration is already running, only the status of the suspension is updated. Otherwise, the suspended integration will begin execution again.
#
# POST /v1/{name}:resolve
# operationId: integrations.projects.locations.products.integrations.executions.suspensions.resolve
# --suspension shape: {approvalConfig?: record, audit?: record, eventExecutionInfoId?: string, integration?: string, name?: string, state?: "RESOLUTION_STATE_UNSPECIFIED"|"PENDING"|"REJECTED"|"LIFTED", suspensionConfig?: record, taskId?: string}
export def "projects integrationsprojectslocationsproductsintegrationsexecutionssuspensionsresolve" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --suspension: record # A record representing a suspension. — shape: {approvalConfig?: record, audit?: record, eventExecutionInfoId?: string, integration?: string, name?: string, state?: "RESOLUTION_STATE_UNSPECIFIED"|"PENDING"|"REJECTED"|"LIFTED", suspensionConfig?: record, taskId?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($name):resolve" $qp)
  let body = {suspension: $suspension} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Schedules an integration for execution by passing the trigger id and the scheduled time in the request body.
#
# POST /v1/{name}:schedule
# operationId: integrations.projects.locations.products.integrations.schedule
# --parameterEntries item shape: {dataType?: "DATA_TYPE_UNSPECIFIED"|"STRING_VALUE"|"INT_VALUE"|"DOUBLE_VALUE"|"BOOLEAN_VALUE"|"PROTO_VALUE"|"SERIALIZED_OBJECT_VALUE"|"STRING_ARRAY"|"INT_ARRAY"|"DOUBLE_ARRAY"|"PROTO_ARRAY"|"PROTO_ENUM"|"BOOLEAN_ARRAY"|"PROTO_ENUM_ARRAY"|"BYTES"|"BYTES_ARRAY"|"NON_SERIALIZABLE_OBJECT"|"JSON_VALUE", key?: string, value?: record}
# --parameters shape: {parameters?: list}
export def "projects integrationsprojectslocationsproductsintegrationsschedule" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --inputParameters: record # Optional. Input parameters used by integration execution.
  --parameterEntries: list # Parameters are a part of Event and can be used to communicate between different tasks that are part of the same integration execution. — item shape: {dataType?: "DATA_TYPE_UNSPECIFIED"|"STRING_VALUE"|"INT_VALUE"|"DOUBLE_VALUE"|"BOOLEAN_VALUE"|"PROTO_VALUE"|"SERIALIZED_OBJECT_VALUE"|"STRING_ARRAY"|"INT_ARRAY"|"DOUBLE_ARRAY"|"PROTO_ARRAY"|"PROTO_ENUM"|"BOOLEAN_ARRAY"|"PROTO_ENUM_ARRAY"|"BYTES"|"BYTES_ARRAY"|"NON_SERIALIZABLE_OBJECT"|"JSON_VALUE", key?: string, value?: record}
  --parameters: record # LINT.IfChange This message is used for processing and persisting (when applicable) key value pair parameters for each event in the event bus. Please see — shape: {parameters?: list}
  --requestId: string # This is used to de-dup incoming request: if the duplicate request was detected, the response from the previous execution is returned.
  --scheduleTime: string # The time that the integration should be executed. If the time is less or equal to the current time, the integration is executed immediately. (format: google-datetime)
  --triggerId: string # Matched against all {@link TriggerConfig}s across all integrations. i.e. TriggerConfig.trigger_id.equals(trigger_id)
]: any -> record<executionInfoIds: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($name):schedule" $qp)
  let body = {inputParameters: $inputParameters, parameterEntries: $parameterEntries, parameters: $parameters, requestId: $requestId, scheduleTime: $scheduleTime, triggerId: $triggerId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Execute the integration in draft state
#
# POST /v1/{name}:test
# operationId: integrations.projects.locations.products.integrations.test
# --integrationVersion shape: {databasePersistencePolicy?: "DATABASE_PERSISTENCE_POLICY_UNSPECIFIED"|"DATABASE_PERSISTENCE_DISABLED", description?: string, errorCatcherConfigs?: list, integrationParameters?: list, integrationParametersInternal?: record, lastModifierEmail?: string, lockHolder?: string, origin?: "UNSPECIFIED"|"UI"|"PIPER_V2"|"PIPER_V3"|"APPLICATION_IP_PROVISIONING", parentTemplateId?: string, runAsServiceAccount?: string, snapshotNumber?: string, taskConfigs?: list, taskConfigsInternal?: list, teardown?: record, triggerConfigs?: list, triggerConfigsInternal?: list, userLabel?: string}
# --parameters shape: {parameters?: list}
export def "projects integrationsprojectslocationsproductsintegrationstest" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --clientId: string # Required. This is used to identify the client on whose behalf the event will be executed.
  --deadlineSecondsTime: string # Optional. custom deadline of the rpc (format: google-datetime)
  --inputParameters: record # Optional. Input parameters used during integration execution.
  --integrationVersion: record # The integration version definition. — shape: {databasePersistencePolicy?: "DATABASE_PERSISTENCE_POLICY_UNSPECIFIED"|"DATABASE_PERSISTENCE_DISABLED", description?: string, errorCatcherConfigs?: list, integrationParameters?: list, integrationParametersInternal?: record, lastModifierEmail?: string, lockHolder?: string, origin?: "UNSPECIFIED"|"UI"|"PIPER_V2"|"PIPER_V3"|"APPLICATION_IP_PROVISIONING", parentTemplateId?: string, runAsServiceAccount?: string, snapshotNumber?: string, taskConfigs?: list, taskConfigsInternal?: list, teardown?: record, triggerConfigs?: list, triggerConfigsInternal?: list, userLabel?: string}
  --parameters: record # LINT.IfChange This message is used for processing and persisting (when applicable) key value pair parameters for each event in the event bus. Please see — shape: {parameters?: list}
  --testMode: oneof<nothing, bool> # Optional. Can be specified in the event request, otherwise false (default). If true, enables tasks with condition "test_mode = true". If false, disables tasks with condition "test_mode = true" if global test mode (set by platform) is also false {@link EventBusConfig}.
  --triggerId: string # Required. The trigger id of the integration trigger config. If both trigger_id and client_id is present, the integration is executed from the start tasks provided by the matching trigger config otherwise it is executed from the default start tasks.
]: any -> record<eventParameters: record<parameters: list<record>>, executionFailed: bool, executionId: string, parameterEntries: table<dataType: string, key: string, value: record>, parameters: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($name):test" $qp)
  let body = {clientId: $clientId, deadlineSecondsTime: $deadlineSecondsTime, inputParameters: $inputParameters, integrationVersion: $integrationVersion, parameters: $parameters, testMode: $testMode, triggerId: $triggerId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Sets the status of the ACTIVE integration to SNAPSHOT with a new tag "PREVIOUSLY_PUBLISHED" after validating it. The "HEAD" and "PUBLISH_REQUESTED" tags do not change. This RPC throws an exception if the version being snapshot is not ACTIVE. Audit fields added include action, action_by, action_timestamp.
#
# POST /v1/{name}:unpublish
# operationId: integrations.projects.locations.products.integrations.versions.unpublish
export def "projects integrationsprojectslocationsproductsintegrationsversionsunpublish" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($name):unpublish" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates an Apps Script project.
#
# POST /v1/{parent}/appsScriptProjects
# operationId: integrations.projects.locations.appsScriptProjects.create
export def "apps-script-projects integrationsprojectslocationsappsScriptProjectscreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --appsScriptProject: string # The name of the Apps Script project to be created.
  --authConfigId: string # The auth config id necessary to fetch the necessary credentials to create the project for external clients
]: any -> record<projectId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/appsScriptProjects" $qp)
  let body = {appsScriptProject: $appsScriptProject, authConfigId: $authConfigId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Links a existing Apps Script project.
#
# POST /v1/{parent}/appsScriptProjects:link
# operationId: integrations.projects.locations.appsScriptProjects.link
export def "apps-script-projects-link integrationsprojectslocationsappsScriptProjectslink" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --scriptId: string # The id of the Apps Script project to be linked.
]: any -> record<scriptId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/appsScriptProjects:link" $qp)
  let body = {scriptId: $scriptId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all auth configs that match the filter. Restrict to auth configs belong to the current client only.
#
# GET /v1/{parent}/authConfigs
# operationId: integrations.projects.locations.products.authConfigs.list
export def "auth-configs integrationsprojectslocationsproductsauthConfigslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # Filtering as supported in https://developers.google.com/authorized-buyers/apis/guides/v2/list-filters.
  --pageSize: int # The size of entries in the response. If unspecified, defaults to 100.
  --pageToken: string # The token returned in the previous response.
  --readMask: string # The mask which specifies fields that need to be returned in the AuthConfig's response.
]: nothing -> record<authConfigs: table<certificateId: string, createTime: string, creatorEmail: string, credentialType: string, decryptedCredential: record, description: string, displayName: string, encryptedCredential: string, expiryNotificationDuration: list, lastModifierEmail: string, name: string, overrideValidTime: string, reason: string, state: string, updateTime: string, validTime: string, visibility: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/authConfigs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates an auth config record. Fetch corresponding credentials for specific auth types, e.g. access token for OAuth 2.0, JWT token for JWT. Encrypt the auth config with Cloud KMS and store the encrypted credentials in Spanner. Returns the encrypted auth config.
#
# POST /v1/{parent}/authConfigs
# operationId: integrations.projects.locations.products.authConfigs.create
# --decryptedCredential shape: {authToken?: record, credentialType?: "CREDENTIAL_TYPE_UNSPECIFIED"|"USERNAME_AND_PASSWORD"|"API_KEY"|"OAUTH2_AUTHORIZATION_CODE"|"OAUTH2_IMPLICIT"|"OAUTH2_CLIENT_CREDENTIALS"|"OAUTH2_RESOURCE_OWNER_CREDENTIALS"|"JWT"|"AUTH_TOKEN"|"SERVICE_ACCOUNT"|"CLIENT_CERTIFICATE_ONLY"|"OIDC_TOKEN", jwt?: record, oauth2AuthorizationCode?: record, oauth2ClientCredentials?: record, oauth2ResourceOwnerCredentials?: record, oidcToken?: record, serviceAccountCredentials?: record, usernameAndPassword?: record}
export def "auth-configs integrationsprojectslocationsproductsauthConfigscreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --clientCertificateencryptedPrivateKey: string # The ssl certificate encoded in PEM format. This string must include the begin header and end footer lines. For example, -----BEGIN CERTIFICATE----- MIICTTCCAbagAwIBAgIJAPT0tSKNxan/MA0GCSqGSIb3DQEBCwUAMCoxFzAVBgNV BAoTDkdvb2dsZSBURVNUSU5HMQ8wDQYDVQQDEwZ0ZXN0Q0EwHhcNMTUwMTAxMDAw MDAwWhcNMjUwMTAxMDAwMDAwWjAuMRcwFQYDVQQKEw5Hb29nbGUgVEVTVElORzET MBEGA1UEAwwKam9lQGJhbmFuYTCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEA vDYFgMgxi5W488d9J7UpCInl0NXmZQpJDEHE4hvkaRlH7pnC71H0DLt0/3zATRP1 JzY2+eqBmbGl4/sgZKYv8UrLnNyQNUTsNx1iZAfPUflf5FwgVsai8BM0pUciq1NB xD429VFcrGZNucvFLh72RuRFIKH8WUpiK/iZNFkWhZ0CAwEAAaN3MHUwDgYDVR0P AQH/BAQDAgWgMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAMBgNVHRMB Af8EAjAAMBkGA1UdDgQSBBCVgnFBCWgL/iwCqnGrhTPQMBsGA1UdIwQUMBKAEKey Um2o4k2WiEVA0ldQvNYwDQYJKoZIhvcNAQELBQADgYEAYK986R4E3L1v+Q6esBtW JrUwA9UmJRSQr0N5w3o9XzarU37/bkjOP0Fw0k/A6Vv1n3vlciYfBFaBIam1qRHr 5dMsYf4CZS6w50r7hyzqyrwDoyNxkLnd2PdcHT/sym1QmflsjEs7pejtnohO6N2H wQW6M0H7Zt8claGRla4fKkg= -----END CERTIFICATE-----
  --clientCertificatepassphrase: string # 'passphrase' should be left unset if private key is not encrypted. Note that 'passphrase' is not the password for web server, but an extra layer of security to protected private key.
  --clientCertificatesslCertificate: string # The ssl certificate encoded in PEM format. This string must include the begin header and end footer lines. For example, -----BEGIN CERTIFICATE----- MIICTTCCAbagAwIBAgIJAPT0tSKNxan/MA0GCSqGSIb3DQEBCwUAMCoxFzAVBgNV BAoTDkdvb2dsZSBURVNUSU5HMQ8wDQYDVQQDEwZ0ZXN0Q0EwHhcNMTUwMTAxMDAw MDAwWhcNMjUwMTAxMDAwMDAwWjAuMRcwFQYDVQQKEw5Hb29nbGUgVEVTVElORzET MBEGA1UEAwwKam9lQGJhbmFuYTCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEA vDYFgMgxi5W488d9J7UpCInl0NXmZQpJDEHE4hvkaRlH7pnC71H0DLt0/3zATRP1 JzY2+eqBmbGl4/sgZKYv8UrLnNyQNUTsNx1iZAfPUflf5FwgVsai8BM0pUciq1NB xD429VFcrGZNucvFLh72RuRFIKH8WUpiK/iZNFkWhZ0CAwEAAaN3MHUwDgYDVR0P AQH/BAQDAgWgMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjAMBgNVHRMB Af8EAjAAMBkGA1UdDgQSBBCVgnFBCWgL/iwCqnGrhTPQMBsGA1UdIwQUMBKAEKey Um2o4k2WiEVA0ldQvNYwDQYJKoZIhvcNAQELBQADgYEAYK986R4E3L1v+Q6esBtW JrUwA9UmJRSQr0N5w3o9XzarU37/bkjOP0Fw0k/A6Vv1n3vlciYfBFaBIam1qRHr 5dMsYf4CZS6w50r7hyzqyrwDoyNxkLnd2PdcHT/sym1QmflsjEs7pejtnohO6N2H wQW6M0H7Zt8claGRla4fKkg= -----END CERTIFICATE-----
  --certificateId: string # Certificate id for client certificate
  --creatorEmail: string # The creator's email address. Generated based on the End User Credentials/LOAS role of the user making the call.
  --credentialType: string@credentialType-completer # Credential type of the encrypted credential.
  --decryptedCredential: record # Defines parameters for a single, canonical credential. — shape: {authToken?: record, credentialType?: "CREDENTIAL_TYPE_UNSPECIFIED"|"USERNAME_AND_PASSWORD"|"API_KEY"|"OAUTH2_AUTHORIZATION_CODE"|"OAUTH2_IMPLICIT"|"OAUTH2_CLIENT_CREDENTIALS"|"OAUTH2_RESOURCE_OWNER_CREDENTIALS"|"JWT"|"AUTH_TOKEN"|"SERVICE_ACCOUNT"|"CLIENT_CERTIFICATE_ONLY"|"OIDC_TOKEN", jwt?: record, oauth2AuthorizationCode?: record, oauth2ClientCredentials?: record, oauth2ResourceOwnerCredentials?: record, oidcToken?: record, serviceAccountCredentials?: record, usernameAndPassword?: record}
  --description: string # A description of the auth config.
  --displayName: string # The name of the auth config.
  --encryptedCredential: string # Auth credential encrypted by Cloud KMS. Can be decrypted as Credential with proper KMS key. (format: byte)
  --expiryNotificationDuration: list # User can define the time to receive notification after which the auth config becomes invalid. Support up to 30 days. Support granularity in hours.
  --lastModifierEmail: string # The last modifier's email address. Generated based on the End User Credentials/LOAS role of the user making the call.
  --name: string # Resource name of the SFDC instance projects/{project}/locations/{location}/authConfigs/{authConfig}.
  --overrideValidTime: string # User provided expiry time to override. For the example of Salesforce, username/password credentials can be valid for 6 months depending on the instance settings. (format: google-datetime)
  --reason: string # The reason / details of the current status.
  --state: string@state-completer # The status of the auth config.
  --validTime: string # The time until the auth config is valid. Empty or max value is considered the auth config won't expire. (format: google-datetime)
  --visibility: string@visibility-completer # The visibility of the auth config.
]: any -> record<certificateId: string, createTime: string, creatorEmail: string, credentialType: string, decryptedCredential: record<authToken: record<token: string, type: string>, credentialType: string, jwt: record<jwt: string, jwtHeader: string, jwtPayload: string, secret: string>, oauth2AuthorizationCode: record<accessToken: record, applyReauthPolicy: bool, authCode: string, authEndpoint: string, authParams: record, clientId: string, clientSecret: string, requestType: string, scope: string, tokenEndpoint: string, tokenParams: record>, oauth2ClientCredentials: record<accessToken: record, clientId: string, clientSecret: string, requestType: string, scope: string, tokenEndpoint: string, tokenParams: record>, oauth2ResourceOwnerCredentials: record<accessToken: record, clientId: string, clientSecret: string, password: string, requestType: string, scope: string, tokenEndpoint: string, tokenParams: record, username: string>, oidcToken: record<audience: string, serviceAccountEmail: string, token: string, tokenExpireTime: string>, serviceAccountCredentials: record<scope: string, serviceAccount: string>, usernameAndPassword: record<password: string, username: string>>, description: string, displayName: string, encryptedCredential: string, expiryNotificationDuration: list<string>, lastModifierEmail: string, name: string, overrideValidTime: string, reason: string, state: string, updateTime: string, validTime: string, visibility: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "clientCertificate.encryptedPrivateKey" $clientCertificateencryptedPrivateKey "scalar") (serialize-qp "clientCertificate.passphrase" $clientCertificatepassphrase "scalar") (serialize-qp "clientCertificate.sslCertificate" $clientCertificatesslCertificate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/authConfigs" $qp)
  let body = {certificateId: $certificateId, creatorEmail: $creatorEmail, credentialType: $credentialType, decryptedCredential: $decryptedCredential, description: $description, displayName: $displayName, encryptedCredential: $encryptedCredential, expiryNotificationDuration: $expiryNotificationDuration, lastModifierEmail: $lastModifierEmail, name: $name, overrideValidTime: $overrideValidTime, reason: $reason, state: $state, validTime: $validTime, visibility: $visibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all the certificates that match the filter. Restrict to certificate of current client only.
#
# GET /v1/{parent}/certificates
# operationId: integrations.projects.locations.products.certificates.list
export def "certificates integrationsprojectslocationsproductscertificateslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # Filtering as supported in https://developers.google.com/authorized-buyers/apis/guides/v2/list-filters.
  --pageSize: int # The size of entries in the response. If unspecified, defaults to 100.
  --pageToken: string # The token returned in the previous response.
  --readMask: string # The mask which specifies fields that need to be returned in the Certificate's response.
]: nothing -> record<certificates: table<certificateStatus: string, credentialId: string, description: string, displayName: string, name: string, rawCertificate: record, requestorId: string, validEndTime: string, validStartTime: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/certificates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new certificate. The certificate will be registered to the trawler service and will be encrypted using cloud KMS and stored in Spanner Returns the certificate.
#
# POST /v1/{parent}/certificates
# operationId: integrations.projects.locations.products.certificates.create
# --rawCertificate shape: {encryptedPrivateKey?: string, passphrase?: string, sslCertificate?: string}
export def "certificates integrationsprojectslocationsproductscertificatescreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --certificateStatus: string@certificateStatus-completer # Status of the certificate
  --credentialId: string # Immutable. Credential id that will be used to register with trawler INTERNAL_ONLY
  --description: string # Description of the certificate
  --displayName: string # Name of the certificate
  --rawCertificate: record # Contains client certificate information — shape: {encryptedPrivateKey?: string, passphrase?: string, sslCertificate?: string}
  --requestorId: string # Immutable. Requestor ID to be used to register certificate with trawler
]: any -> record<certificateStatus: string, credentialId: string, description: string, displayName: string, name: string, rawCertificate: record<encryptedPrivateKey: string, passphrase: string, sslCertificate: string>, requestorId: string, validEndTime: string, validStartTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/certificates" $qp)
  let body = {certificateStatus: $certificateStatus, credentialId: $credentialId, description: $description, displayName: $displayName, rawCertificate: $rawCertificate, requestorId: $requestorId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the metadata info for the requested client
#
# GET /v1/{parent}/clientmetadata
# operationId: integrations.projects.getClientmetadata
export def "clientmetadata integrationsprojectsgetClientmetadata" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<properties: record<ipEnablementState: string, provisionedRegions: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/clientmetadata" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the client configuration for the given project and location resource name
#
# GET /v1/{parent}/clients
# operationId: integrations.projects.locations.getClients
export def "clients integrationsprojectslocationsgetClients" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<client: record<billingType: string, clientState: string, cloudKmsConfig: record<key: string, keyVersion: string, kmsLocation: string, kmsProjectId: string, kmsRing: string>, cloudLoggingConfig: record<bucket: string, enableCloudLogging: bool>, createTime: string, description: string, id: string, p4ServiceAccount: string, projectId: string, region: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/clients" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Perform the deprovisioning steps to disable a user GCP project to use IP and purge all related data in a wipeout-compliant way.
#
# POST /v1/{parent}/clients:deprovision
# operationId: integrations.projects.locations.clients.deprovision
export def "clients-deprovision integrationsprojectslocationsclientsdeprovision" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --body: record
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/clients:deprovision" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Perform the provisioning steps to enable a user GCP project to use IP. If GCP project already registered on IP end via Apigee Integration, provisioning will fail.
#
# POST /v1/{parent}/clients:provision
# operationId: integrations.projects.locations.clients.provision
# --cloudKmsConfig shape: {key?: string, keyVersion?: string, kmsLocation?: string, kmsProjectId?: string, kmsRing?: string}
export def "clients-provision integrationsprojectslocationsclientsprovision" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cloudKmsConfig: record # Configuration information for Client's Cloud KMS information — shape: {key?: string, keyVersion?: string, kmsLocation?: string, kmsProjectId?: string, kmsRing?: string}
  --createSampleWorkflows: oneof<nothing, bool> # Optional. Indicates if sample workflow should be created along with provisioning
  --provisionGmek: oneof<nothing, bool> # Optional. Indicates provision with GMEK or CMEK
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/clients:provision" $qp)
  let body = {cloudKmsConfig: $cloudKmsConfig, createSampleWorkflows: $createSampleWorkflows, provisionGmek: $provisionGmek} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update client from GMEK to CMEK
#
# POST /v1/{parent}/clients:switch
# operationId: integrations.projects.locations.clients.switch
# --cloudKmsConfig shape: {key?: string, keyVersion?: string, kmsLocation?: string, kmsProjectId?: string, kmsRing?: string}
export def "clients-switch integrationsprojectslocationsclientsswitch" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --cloudKmsConfig: record # Configuration information for Client's Cloud KMS information — shape: {key?: string, keyVersion?: string, kmsLocation?: string, kmsProjectId?: string, kmsRing?: string}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/clients:switch" $qp)
  let body = {cloudKmsConfig: $cloudKmsConfig} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates an cloud function project.
#
# POST /v1/{parent}/cloudFunctions
# operationId: integrations.projects.locations.products.cloudFunctions.create
export def "cloud-functions integrationsprojectslocationsproductscloudFunctionscreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --functionName: string # The function name of CF to be created
  --functionRegion: string # The function region of CF to be created
  --projectId: string # Indicates the id of the GCP project that the function will be created in.
]: any -> record<triggerUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/cloudFunctions" $qp)
  let body = {functionName: $functionName, functionRegion: $functionRegion, projectId: $projectId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists Connections in a given project and location.
#
# GET /v1/{parent}/connections
# operationId: integrations.projects.locations.connections.list
export def "connections integrationsprojectslocationsconnectionslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # Filter.
  --orderBy: string # Order by parameters.
  --pageSize: int # Page size.
  --pageToken: string # Page token.
]: nothing -> record<connections: table<authConfig: record, configVariables: list, connectorVersion: string, createTime: string, description: string, destinationConfigs: list, envoyImageLocation: string, imageLocation: string, labels: record, lockConfig: record, logConfig: record, name: string, nodeConfig: record, serviceAccount: string, serviceDirectory: string, sslConfig: record, status: record, suspended: bool, updateTime: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/connections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the results of all the integration executions. The response includes the same information as the [execution log](https://cloud.google.com/application-integration/docs/viewing-logs) in the Integration UI.
#
# GET /v1/{parent}/executions
# operationId: integrations.projects.locations.products.integrations.executions.list
export def "executions integrationsprojectslocationsproductsintegrationsexecutionslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # Optional. Standard filter field, we support filtering on following fields: workflow_name: the name of the integration. CreateTimestamp: the execution created time. event_execution_state: the state of the executions. execution_id: the id of the execution. trigger_id: the id of the trigger. parameter_type: the type of the parameters involved in the execution. All fields support for EQUALS, in additional: CreateTimestamp support for LESS_THAN, GREATER_THAN ParameterType support for HAS For example: "parameter_type" HAS \"string\" Also supports operators like AND, OR, NOT For example, trigger_id=\"id1\" AND workflow_name=\"testWorkflow\"
  --filterParamscustomFilter: string # Optional user-provided custom filter.
  --filterParamsendTime: string # End timestamp.
  --filterParamseventStatuses: list # List of possible event statuses.
  --filterParamsexecutionId: string # Execution id.
  --filterParamsparameterKey: string # Param key. DEPRECATED. User parameter_pair_key instead.
  --filterParamsparameterPairKey: string # Param key in the key value pair filter.
  --filterParamsparameterPairValue: string # Param value in the key value pair filter.
  --filterParamsparameterType: string # Param type.
  --filterParamsparameterValue: string # Param value. DEPRECATED. User parameter_pair_value instead.
  --filterParamsstartTime: string # Start timestamp.
  --filterParamstaskStatuses: list # List of possible task statuses.
  --filterParamsworkflowName: string # Workflow name.
  --orderBy: string # Optional. The results would be returned in order you specified here. Currently supporting "last_modified_time" and "create_time".
  --pageSize: int # Optional. The size of entries in the response.
  --pageToken: string # Optional. The token returned in the previous response.
  --readMask: string # Optional. View mask for the response data. If set, only the field specified will be returned as part of the result. If not set, all fields in event execution info will be filled and returned.
  --refreshAcl: oneof<nothing, bool> # Optional. If true, the service will use the most recent acl information to list event execution infos and renew the acl cache. Note that fetching the most recent acl is synchronous, so it will increase RPC call latency.
  --truncateParams: oneof<nothing, bool> # Optional. If true, the service will truncate the params to only keep the first 1000 characters of string params and empty the executions in order to make response smaller. Only works for UI and when the params fields are not filtered out.
]: nothing -> record<executionInfos: table<clientId: string, createTime: string, errorCode: record, errors: list, eventExecutionDetails: record, eventExecutionInfoId: string, executionTraceInfo: record, lastModifiedTime: string, postMethod: string, product: string, requestId: string, requestParams: record, responseParams: record, snapshotNumber: string, tenant: string, triggerId: string, workflowId: string, workflowName: string, workflowRetryBackoffIntervalSeconds: string>, executions: table<createTime: string, directSubExecutions: list, eventExecutionDetails: record, executionDetails: record, executionMethod: string, name: string, requestParameters: record, requestParams: list, responseParameters: record, responseParams: list, triggerId: string, updateTime: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "filterParams.customFilter" $filterParamscustomFilter "scalar") (serialize-qp "filterParams.endTime" $filterParamsendTime "scalar") (serialize-qp "filterParams.eventStatuses" $filterParamseventStatuses "multi") (serialize-qp "filterParams.executionId" $filterParamsexecutionId "scalar") (serialize-qp "filterParams.parameterKey" $filterParamsparameterKey "scalar") (serialize-qp "filterParams.parameterPairKey" $filterParamsparameterPairKey "scalar") (serialize-qp "filterParams.parameterPairValue" $filterParamsparameterPairValue "scalar") (serialize-qp "filterParams.parameterType" $filterParamsparameterType "scalar") (serialize-qp "filterParams.parameterValue" $filterParamsparameterValue "scalar") (serialize-qp "filterParams.startTime" $filterParamsstartTime "scalar") (serialize-qp "filterParams.taskStatuses" $filterParamstaskStatuses "multi") (serialize-qp "filterParams.workflowName" $filterParamsworkflowName "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "readMask" $readMask "scalar") (serialize-qp "refreshAcl" $refreshAcl "scalar") (serialize-qp "truncateParams" $truncateParams "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/executions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the list of all integrations in the specified project.
#
# GET /v1/{parent}/integrations
# operationId: integrations.projects.locations.products.integrations.list
export def "integrations integrationsprojectslocationsproductsintegrationslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # Filter on fields of IntegrationVersion. Fields can be compared with literal values by use of ":" (containment), "=" (equality), ">" (greater), "<" (less than), >=" (greater than or equal to), "<=" (less than or equal to), and "!=" (inequality) operators. Negation, conjunction, and disjunction are written using NOT, AND, and OR keywords. For example, organization_id=\"1\" AND state=ACTIVE AND description:"test". Filtering cannot be performed on repeated fields like `task_config`.
  --orderBy: string # The results would be returned in order you specified here. Supported sort keys are: Descending sort order by "last_modified_time", "created_time", "snapshot_number". Ascending sort order by the integration name.
  --pageSize: int # The page size for the resquest.
  --pageToken: string # The page token for the resquest.
]: nothing -> record<integrations: table<active: bool, description: string, name: string, updateTime: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/integrations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the JSON schemas for the inputs and outputs of actions, filtered by action name.
#
# GET /v1/{parent}/runtimeActionSchemas
# operationId: integrations.projects.locations.connections.runtimeActionSchemas.list
export def "runtime-action-schemas integrationsprojectslocationsconnectionsruntimeActionSchemaslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # Filter. Only the action field with literal equality operator is supported.
  --pageSize: int # Page size.
  --pageToken: string # Page token.
]: nothing -> record<nextPageToken: string, runtimeActionSchemas: table<action: string, inputSchema: string, outputSchema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/runtimeActionSchemas" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the JSON schemas for the properties of runtime entities, filtered by entity name.
#
# GET /v1/{parent}/runtimeEntitySchemas
# operationId: integrations.projects.locations.connections.runtimeEntitySchemas.list
export def "runtime-entity-schemas integrationsprojectslocationsconnectionsruntimeEntitySchemaslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # Filter. Only the entity field with literal equality operator is supported.
  --pageSize: int # Page size.
  --pageToken: string # Page token.
]: nothing -> record<nextPageToken: string, runtimeEntitySchemas: table<arrayFieldSchema: string, entity: string, fieldSchema: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/runtimeEntitySchemas" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all sfdc channels that match the filter. Restrict to sfdc channels belonging to the current client only.
#
# GET /v1/{parent}/sfdcChannels
# operationId: integrations.projects.locations.sfdcInstances.sfdcChannels.list
export def "sfdc-channels integrationsprojectslocationssfdcInstancessfdcChannelslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # Filtering as supported in https://developers.google.com/authorized-buyers/apis/guides/v2/list-filters.
  --pageSize: int # The size of entries in the response. If unspecified, defaults to 100.
  --pageToken: string # The token returned in the previous response.
  --readMask: string # The mask which specifies fields that need to be returned in the SfdcChannel's response.
]: nothing -> record<nextPageToken: string, sfdcChannels: table<channelTopic: string, createTime: string, deleteTime: string, description: string, displayName: string, isActive: bool, lastReplayId: string, name: string, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/sfdcChannels" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates an sfdc channel record. Store the sfdc channel in Spanner. Returns the sfdc channel.
#
# POST /v1/{parent}/sfdcChannels
# operationId: integrations.projects.locations.sfdcInstances.sfdcChannels.create
export def "sfdc-channels integrationsprojectslocationssfdcInstancessfdcChannelscreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --channelTopic: string # The Channel topic defined by salesforce once an channel is opened
  --description: string # The description for this channel
  --displayName: string # Client level unique name/alias to easily reference a channel.
  --isActive: oneof<nothing, bool> # Indicated if a channel has any active integrations referencing it. Set to false when the channel is created, and set to true if there is any integration published with the channel configured in it.
  --lastReplayId: string # Last sfdc messsage replay id for channel
  --name: string # Resource name of the SFDC channel projects/{project}/locations/{location}/sfdcInstances/{sfdc_instance}/sfdcChannels/{sfdc_channel}.
]: any -> record<channelTopic: string, createTime: string, deleteTime: string, description: string, displayName: string, isActive: bool, lastReplayId: string, name: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/sfdcChannels" $qp)
  let body = {channelTopic: $channelTopic, description: $description, displayName: $displayName, isActive: $isActive, lastReplayId: $lastReplayId, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all sfdc instances that match the filter. Restrict to sfdc instances belonging to the current client only.
#
# GET /v1/{parent}/sfdcInstances
# operationId: integrations.projects.locations.sfdcInstances.list
export def "sfdc-instances integrationsprojectslocationssfdcInstanceslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # Filtering as supported in https://developers.google.com/authorized-buyers/apis/guides/v2/list-filters.
  --pageSize: int # The size of entries in the response. If unspecified, defaults to 100.
  --pageToken: string # The token returned in the previous response.
  --readMask: string # The mask which specifies fields that need to be returned in the SfdcInstance's response.
]: nothing -> record<nextPageToken: string, sfdcInstances: table<authConfigId: list, createTime: string, deleteTime: string, description: string, displayName: string, name: string, serviceAuthority: string, sfdcOrgId: string, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar") (serialize-qp "readMask" $readMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/sfdcInstances" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates an sfdc instance record. Store the sfdc instance in Spanner. Returns the sfdc instance.
#
# POST /v1/{parent}/sfdcInstances
# operationId: integrations.projects.locations.sfdcInstances.create
export def "sfdc-instances integrationsprojectslocationssfdcInstancescreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --authConfigId: list # A list of AuthConfigs that can be tried to open the channel to SFDC
  --description: string # A description of the sfdc instance.
  --displayName: string # User selected unique name/alias to easily reference an instance.
  --name: string # Resource name of the SFDC instance projects/{project}/locations/{location}/sfdcInstances/{sfdcInstance}.
  --serviceAuthority: string # URL used for API calls after authentication (the login authority is configured within the referenced AuthConfig).
  --sfdcOrgId: string # The SFDC Org Id. This is defined in salesforce.
]: any -> record<authConfigId: list<string>, createTime: string, deleteTime: string, description: string, displayName: string, name: string, serviceAuthority: string, sfdcOrgId: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/sfdcInstances" $qp)
  let body = {authConfigId: $authConfigId, description: $description, displayName: $displayName, name: $name, serviceAuthority: $serviceAuthority, sfdcOrgId: $sfdcOrgId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# * Lists suspensions associated with a specific execution. Only those with permissions to resolve the relevant suspensions will be able to view them.
#
# GET /v1/{parent}/suspensions
# operationId: integrations.projects.locations.products.integrations.executions.suspensions.list
export def "suspensions integrationsprojectslocationsproductsintegrationsexecutionssuspensionslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # Standard filter field.
  --orderBy: string # Field name to order by.
  --pageSize: int # Maximum number of entries in the response.
  --pageToken: string # Token to retrieve a specific page.
]: nothing -> record<nextPageToken: string, suspensions: table<approvalConfig: record, audit: record, createTime: string, eventExecutionInfoId: string, integration: string, lastModifyTime: string, name: string, state: string, suspensionConfig: record, taskId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/suspensions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the list of all integration versions in the specified project.
#
# GET /v1/{parent}/versions
# operationId: integrations.projects.locations.products.integrations.versions.list
export def "versions integrationsprojectslocationsproductsintegrationsversionslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --fieldMask: string # The field mask which specifies the particular data to be returned.
  --filter: string # Filter on fields of IntegrationVersion. Fields can be compared with literal values by use of ":" (containment), "=" (equality), ">" (greater), "<" (less than), >=" (greater than or equal to), "<=" (less than or equal to), and "!=" (inequality) operators. Negation, conjunction, and disjunction are written using NOT, AND, and OR keywords. For example, organization_id=\"1\" AND state=ACTIVE AND description:"test". Filtering cannot be performed on repeated fields like `task_config`.
  --orderBy: string # The results would be returned in order you specified here. Currently supported sort keys are: Descending sort order for "last_modified_time", "created_time", "snapshot_number" Ascending sort order for "name".
  --pageSize: int # The maximum number of versions to return. The service may return fewer than this value. If unspecified, at most 50 versions will be returned. The maximum value is 1000; values above 1000 will be coerced to 1000.
  --pageToken: string # A page token, received from a previous `ListIntegrationVersions` call. Provide this to retrieve the subsequent page. When paginating, all other parameters provided to `ListIntegrationVersions` must match the call that provided the page token.
]: nothing -> record<integrationVersions: table<createTime: string, databasePersistencePolicy: string, description: string, errorCatcherConfigs: list, integrationParameters: list, integrationParametersInternal: record, lastModifierEmail: string, lockHolder: string, name: string, origin: string, parentTemplateId: string, runAsServiceAccount: string, snapshotNumber: string, state: string, status: string, taskConfigs: list, taskConfigsInternal: list, teardown: record, triggerConfigs: list, triggerConfigsInternal: list, updateTime: string, userLabel: string>, nextPageToken: string, noPermission: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "fieldMask" $fieldMask "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/versions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a integration with a draft version in the specified project.
#
# POST /v1/{parent}/versions
# operationId: integrations.projects.locations.products.integrations.versions.create
# --errorCatcherConfigs item shape: {description?: string, errorCatcherId?: string, errorCatcherNumber?: string, label?: string, position?: record, startErrorTasks?: list}
# --integrationParameters item shape: {dataType?: "INTEGRATION_PARAMETER_DATA_TYPE_UNSPECIFIED"|"STRING_VALUE"|"INT_VALUE"|"DOUBLE_VALUE"|"BOOLEAN_VALUE"|"STRING_ARRAY"|"INT_ARRAY"|"DOUBLE_ARRAY"|"BOOLEAN_ARRAY"|"JSON_VALUE"|"PROTO_VALUE"|"PROTO_ARRAY", defaultValue?: record, displayName?: string, inputOutputType?: "IN_OUT_TYPE_UNSPECIFIED"|"IN"|"OUT"|"IN_OUT", isTransient?: bool, jsonSchema?: string, key?: string, producer?: string, searchable?: bool}
# --integrationParametersInternal shape: {parameters?: list}
# --taskConfigs item shape: {description?: string, displayName?: string, errorCatcherId?: string, externalTaskType?: "EXTERNAL_TASK_TYPE_UNSPECIFIED"|"NORMAL_TASK"|"ERROR_TASK", failurePolicy?: record, jsonValidationOption?: "JSON_VALIDATION_OPTION_UNSPECIFIED"|"SKIP"|"PRE_EXECUTION"|"POST_EXECUTION"|"PRE_POST_EXECUTION", nextTasks?: list, nextTasksExecutionPolicy?: "NEXT_TASKS_EXECUTION_POLICY_UNSPECIFIED"|"RUN_ALL_MATCH"|"RUN_FIRST_MATCH", parameters?: record, position?: record, successPolicy?: record, synchronousCallFailurePolicy?: record, task?: string, taskExecutionStrategy?: "TASK_EXECUTION_STRATEGY_UNSPECIFIED"|"WHEN_ALL_SUCCEED"|"WHEN_ANY_SUCCEED"|"WHEN_ALL_TASKS_AND_CONDITIONS_SUCCEED", taskId?: string, taskTemplate?: string}
# --taskConfigsInternal item shape: {alertConfigs?: list, createTime?: string, creatorEmail?: string, description?: string, disableStrictTypeValidation?: bool, errorCatcherId?: string, externalTaskType?: "EXTERNAL_TASK_TYPE_UNSPECIFIED"|"NORMAL_TASK"|"ERROR_TASK", failurePolicy?: record, incomingEdgeCount?: int, jsonValidationOption?: "UNSPECIFIED_JSON_VALIDATION_OPTION"|"SKIP"|"PRE_EXECUTION"|"POST_EXECUTION"|"PRE_POST_EXECUTION", label?: string, lastModifiedTime?: string, nextTasks?: list, nextTasksExecutionPolicy?: "UNSPECIFIED"|"RUN_ALL_MATCH"|"RUN_FIRST_MATCH", parameters?: record, position?: record, precondition?: string, preconditionLabel?: string, rollbackStrategy?: record, successPolicy?: record, synchronousCallFailurePolicy?: record, taskEntity?: record, taskExecutionStrategy?: "WHEN_ALL_SUCCEED"|"WHEN_ANY_SUCCEED"|"WHEN_ALL_TASKS_AND_CONDITIONS_SUCCEED", taskName?: string, taskNumber?: string, taskSpec?: string, taskTemplateName?: string, taskType?: "TASK"|"ASIS_TEMPLATE"|"IO_TEMPLATE"}
# --teardown shape: {teardownTaskConfigs?: list}
# --triggerConfigs item shape: {alertConfig?: list, cloudSchedulerConfig?: record, description?: string, errorCatcherId?: string, label?: string, nextTasksExecutionPolicy?: "NEXT_TASKS_EXECUTION_POLICY_UNSPECIFIED"|"RUN_ALL_MATCH"|"RUN_FIRST_MATCH", position?: record, properties?: record, startTasks?: list, triggerId?: string, triggerNumber?: string, triggerType?: "TRIGGER_TYPE_UNSPECIFIED"|"CRON"|"API"|"SFDC_CHANNEL"|"CLOUD_PUBSUB_EXTERNAL"|"SFDC_CDC_CHANNEL"|"CLOUD_SCHEDULER"}
# --triggerConfigsInternal item shape: {alertConfig?: list, cloudSchedulerConfig?: record, description?: string, enabledClients?: list, errorCatcherId?: string, label?: string, nextTasksExecutionPolicy?: "UNSPECIFIED"|"RUN_ALL_MATCH"|"RUN_FIRST_MATCH", pauseWorkflowExecutions?: bool, position?: record, properties?: record, startTasks?: list, triggerCriteria?: record, triggerId?: string, triggerNumber?: string, triggerType?: "UNKNOWN"|"CLOUD_PUBSUB"|"GOOPS"|"SFDC_SYNC"|"CRON"|"API"|"MANIFOLD_TRIGGER"|"DATALAYER_DATA_CHANGE"|"SFDC_CHANNEL"|"CLOUD_PUBSUB_EXTERNAL"|"SFDC_CDC_CHANNEL"|"SFDC_PLATFORM_EVENTS_CHANNEL"|"CLOUD_SCHEDULER"}
export def "versions integrationsprojectslocationsproductsintegrationsversionscreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --newIntegration: oneof<nothing, bool> # Set this flag to true, if draft version is to be created for a brand new integration. False, if the request is for an existing integration. For backward compatibility reasons, even if this flag is set to `false` and no existing integration is found, a new draft integration will still be created.
  --databasePersistencePolicy: string@databasePersistencePolicy-completer # Optional. Flag to disable database persistence for execution data, including event execution info, execution export info, execution metadata index and execution param index.
  --description: string # Optional. The integration description.
  --errorCatcherConfigs: list # Optional. Error Catch Task configuration for the integration. It's optional. — item shape: {description?: string, errorCatcherId?: string, errorCatcherNumber?: string, label?: string, position?: record, startErrorTasks?: list}
  --integrationParameters: list # Optional. Parameters that are expected to be passed to the integration when an event is triggered. This consists of all the parameters that are expected in the integration execution. This gives the user the ability to provide default values, add information like PII and also provide data types of each parameter. — item shape: {dataType?: "INTEGRATION_PARAMETER_DATA_TYPE_UNSPECIFIED"|"STRING_VALUE"|"INT_VALUE"|"DOUBLE_VALUE"|"BOOLEAN_VALUE"|"STRING_ARRAY"|"INT_ARRAY"|"DOUBLE_ARRAY"|"BOOLEAN_ARRAY"|"JSON_VALUE"|"PROTO_VALUE"|"PROTO_ARRAY", defaultValue?: record, displayName?: string, inputOutputType?: "IN_OUT_TYPE_UNSPECIFIED"|"IN"|"OUT"|"IN_OUT", isTransient?: bool, jsonSchema?: string, key?: string, producer?: string, searchable?: bool}
  --integrationParametersInternal: record # LINT.IfChange This is the frontend version of WorkflowParameters. It's exactly like the backend version except that instead of flattening protobuf parameters and treating every field and subfield of a protobuf parameter as a separate parameter, the fields/subfields of a protobuf parameter will be nested as "children" (see 'children' field below) parameters of the parent parameter. Please refer to enterprise/crm/eventbus/proto/workflow_parameters.proto for more information about WorkflowParameters. — shape: {parameters?: list}
  --lastModifierEmail: string # Optional. The last modifier's email address. Generated based on the End User Credentials/LOAS role of the user making the call.
  --lockHolder: string # Optional. The edit lock holder's email address. Generated based on the End User Credentials/LOAS role of the user making the call.
  --origin: string@origin-completer # Optional. The origin that indicates where this integration is coming from.
  --parentTemplateId: string # Optional. The id of the template which was used to create this integration_version.
  --runAsServiceAccount: string # Optional. The run-as service account email, if set and auth config is not configured, that will be used to generate auth token to be used in Connector task, Rest caller task and Cloud function task.
  --snapshotNumber: string # Optional. An increasing sequence that is set when a new snapshot is created. The last created snapshot can be identified by [workflow_name, org_id latest(snapshot_number)]. However, last created snapshot need not be same as the HEAD. So users should always use "HEAD" tag to identify the head. (format: int64)
  --taskConfigs: list # Optional. Task configuration for the integration. It's optional, but the integration doesn't do anything without task_configs. — item shape: {description?: string, displayName?: string, errorCatcherId?: string, externalTaskType?: "EXTERNAL_TASK_TYPE_UNSPECIFIED"|"NORMAL_TASK"|"ERROR_TASK", failurePolicy?: record, jsonValidationOption?: "JSON_VALIDATION_OPTION_UNSPECIFIED"|"SKIP"|"PRE_EXECUTION"|"POST_EXECUTION"|"PRE_POST_EXECUTION", nextTasks?: list, nextTasksExecutionPolicy?: "NEXT_TASKS_EXECUTION_POLICY_UNSPECIFIED"|"RUN_ALL_MATCH"|"RUN_FIRST_MATCH", parameters?: record, position?: record, successPolicy?: record, synchronousCallFailurePolicy?: record, task?: string, taskExecutionStrategy?: "TASK_EXECUTION_STRATEGY_UNSPECIFIED"|"WHEN_ALL_SUCCEED"|"WHEN_ANY_SUCCEED"|"WHEN_ALL_TASKS_AND_CONDITIONS_SUCCEED", taskId?: string, taskTemplate?: string}
  --taskConfigsInternal: list # Optional. Task configuration for the integration. It's optional, but the integration doesn't do anything without task_configs. — item shape: {alertConfigs?: list, createTime?: string, creatorEmail?: string, description?: string, disableStrictTypeValidation?: bool, errorCatcherId?: string, externalTaskType?: "EXTERNAL_TASK_TYPE_UNSPECIFIED"|"NORMAL_TASK"|"ERROR_TASK", failurePolicy?: record, incomingEdgeCount?: int, jsonValidationOption?: "UNSPECIFIED_JSON_VALIDATION_OPTION"|"SKIP"|"PRE_EXECUTION"|"POST_EXECUTION"|"PRE_POST_EXECUTION", label?: string, lastModifiedTime?: string, nextTasks?: list, nextTasksExecutionPolicy?: "UNSPECIFIED"|"RUN_ALL_MATCH"|"RUN_FIRST_MATCH", parameters?: record, position?: record, precondition?: string, preconditionLabel?: string, rollbackStrategy?: record, successPolicy?: record, synchronousCallFailurePolicy?: record, taskEntity?: record, taskExecutionStrategy?: "WHEN_ALL_SUCCEED"|"WHEN_ANY_SUCCEED"|"WHEN_ALL_TASKS_AND_CONDITIONS_SUCCEED", taskName?: string, taskNumber?: string, taskSpec?: string, taskTemplateName?: string, taskType?: "TASK"|"ASIS_TEMPLATE"|"IO_TEMPLATE"}
  --teardown: record # shape: {teardownTaskConfigs?: list}
  --triggerConfigs: list # Optional. Trigger configurations. — item shape: {alertConfig?: list, cloudSchedulerConfig?: record, description?: string, errorCatcherId?: string, label?: string, nextTasksExecutionPolicy?: "NEXT_TASKS_EXECUTION_POLICY_UNSPECIFIED"|"RUN_ALL_MATCH"|"RUN_FIRST_MATCH", position?: record, properties?: record, startTasks?: list, triggerId?: string, triggerNumber?: string, triggerType?: "TRIGGER_TYPE_UNSPECIFIED"|"CRON"|"API"|"SFDC_CHANNEL"|"CLOUD_PUBSUB_EXTERNAL"|"SFDC_CDC_CHANNEL"|"CLOUD_SCHEDULER"}
  --triggerConfigsInternal: list # Optional. Trigger configurations. — item shape: {alertConfig?: list, cloudSchedulerConfig?: record, description?: string, enabledClients?: list, errorCatcherId?: string, label?: string, nextTasksExecutionPolicy?: "UNSPECIFIED"|"RUN_ALL_MATCH"|"RUN_FIRST_MATCH", pauseWorkflowExecutions?: bool, position?: record, properties?: record, startTasks?: list, triggerCriteria?: record, triggerId?: string, triggerNumber?: string, triggerType?: "UNKNOWN"|"CLOUD_PUBSUB"|"GOOPS"|"SFDC_SYNC"|"CRON"|"API"|"MANIFOLD_TRIGGER"|"DATALAYER_DATA_CHANGE"|"SFDC_CHANNEL"|"CLOUD_PUBSUB_EXTERNAL"|"SFDC_CDC_CHANNEL"|"SFDC_PLATFORM_EVENTS_CHANNEL"|"CLOUD_SCHEDULER"}
  --userLabel: string # Optional. A user-defined label that annotates an integration version. Typically, this is only set when the integration version is created.
]: any -> record<createTime: string, databasePersistencePolicy: string, description: string, errorCatcherConfigs: table<description: string, errorCatcherId: string, errorCatcherNumber: string, label: string, position: record, startErrorTasks: list>, integrationParameters: table<dataType: string, defaultValue: record, displayName: string, inputOutputType: string, isTransient: bool, jsonSchema: string, key: string, producer: string, searchable: bool>, integrationParametersInternal: record<parameters: list<record>>, lastModifierEmail: string, lockHolder: string, name: string, origin: string, parentTemplateId: string, runAsServiceAccount: string, snapshotNumber: string, state: string, status: string, taskConfigs: table<description: string, displayName: string, errorCatcherId: string, externalTaskType: string, failurePolicy: record, jsonValidationOption: string, nextTasks: list, nextTasksExecutionPolicy: string, parameters: record, position: record, successPolicy: record, synchronousCallFailurePolicy: record, task: string, taskExecutionStrategy: string, taskId: string, taskTemplate: string>, taskConfigsInternal: table<alertConfigs: list, createTime: string, creatorEmail: string, description: string, disableStrictTypeValidation: bool, errorCatcherId: string, externalTaskType: string, failurePolicy: record, incomingEdgeCount: int, jsonValidationOption: string, label: string, lastModifiedTime: string, nextTasks: list, nextTasksExecutionPolicy: string, parameters: record, position: record, precondition: string, preconditionLabel: string, rollbackStrategy: record, successPolicy: record, synchronousCallFailurePolicy: record, taskEntity: record, taskExecutionStrategy: string, taskName: string, taskNumber: string, taskSpec: string, taskTemplateName: string, taskType: string>, teardown: record<teardownTaskConfigs: list<record>>, triggerConfigs: table<alertConfig: list, cloudSchedulerConfig: record, description: string, errorCatcherId: string, label: string, nextTasksExecutionPolicy: string, position: record, properties: record, startTasks: list, triggerId: string, triggerNumber: string, triggerType: string>, triggerConfigsInternal: table<alertConfig: list, cloudSchedulerConfig: record, description: string, enabledClients: list, errorCatcherId: string, label: string, nextTasksExecutionPolicy: string, pauseWorkflowExecutions: bool, position: record, properties: record, startTasks: list, triggerCriteria: record, triggerId: string, triggerNumber: string, triggerType: string>, updateTime: string, userLabel: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "newIntegration" $newIntegration "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/versions" $qp)
  let body = {databasePersistencePolicy: $databasePersistencePolicy, description: $description, errorCatcherConfigs: $errorCatcherConfigs, integrationParameters: $integrationParameters, integrationParametersInternal: $integrationParametersInternal, lastModifierEmail: $lastModifierEmail, lockHolder: $lockHolder, origin: $origin, parentTemplateId: $parentTemplateId, runAsServiceAccount: $runAsServiceAccount, snapshotNumber: $snapshotNumber, taskConfigs: $taskConfigs, taskConfigsInternal: $taskConfigsInternal, teardown: $teardown, triggerConfigs: $triggerConfigs, triggerConfigsInternal: $triggerConfigsInternal, userLabel: $userLabel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Uploads an integration. The content can be a previously downloaded integration. Performs the same function as CreateDraftIntegrationVersion, but accepts input in a string format, which holds the complete representation of the IntegrationVersion content.
#
# POST /v1/{parent}/versions:upload
# operationId: integrations.projects.locations.products.integrations.versions.upload
export def "versions-upload integrationsprojectslocationsproductsintegrationsversionsupload" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --content: string # The textproto of the integration_version.
  --fileFormat: string@fileFormat-completer # File format for upload request.
]: any -> record<integrationVersion: record<createTime: string, databasePersistencePolicy: string, description: string, errorCatcherConfigs: list<record>, integrationParameters: list<record>, integrationParametersInternal: record<parameters: list>, lastModifierEmail: string, lockHolder: string, name: string, origin: string, parentTemplateId: string, runAsServiceAccount: string, snapshotNumber: string, state: string, status: string, taskConfigs: list<record>, taskConfigsInternal: list<record>, teardown: record<teardownTaskConfigs: list>, triggerConfigs: list<record>, triggerConfigsInternal: list<record>, updateTime: string, userLabel: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/($parent)/versions:upload" $qp)
  let body = {content: $content, fileFormat: $fileFormat} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
