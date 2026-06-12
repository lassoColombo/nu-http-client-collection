# Auto-generated client for Stytch API v2.0.0
# Source: https://raw.githubusercontent.com/stytchauth/stytch-openapi/main/openapi.yml
# Auth: --token flag or $env.STYTCH_API_TOKEN

const BASE_URL = "https://api.stytch.com"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o STYTCH_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.stytch.com" "https://test.stytch.com" "https://telemetry.stytch.com"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def client-type-completer [] { ["first_party" "first_party_public" "third_party" "third_party_public"] }
def identity-provider-completer [] { ["cyberark" "generic" "jumpcloud" "microsoft-entra" "okta" "onelogin" "pingfederate" "rippling"] }
def first-party-connected-apps-allowed-type-completer [] { ["ALL_ALLOWED" "NOT_ALLOWED" "RESTRICTED"] }
def third-party-connected-apps-allowed-type-completer [] { ["ALL_ALLOWED" "NOT_ALLOWED" "RESTRICTED"] }
def locale-completer [] { ["en" "es" "fr" "pt-br"] }
def delivery-method-completer [] { ["EMAIL_MAGIC_LINK" "EMAIL_OTP"] }
def locale-completer-1 [] { ["ca-ES" "de-DE" "en" "es" "fr" "it" "pt-br" "zh-Hans"] }
def action-completer [] { ["ALLOW" "BLOCK" "CHALLENGE" "NONE"] }
def override-action-completer [] { ["ALLOW" "BLOCK" "CHALLENGE" "NONE"] }
def status-completer [] { ["active" "inactive"] }
def hash-type-completer [] { ["argon_2i" "argon_2id" "bcrypt" "md_5" "pbkdf_2" "phpass" "scrypt" "sha_1" "sha_512"] }
def identity-provider-completer-1 [] { ["classlink" "cyberark" "duo" "generic" "google-workspace" "jumpcloud" "keycloak" "microsoft-entra" "miniorange" "okta" "onelogin" "pingfederate" "rippling" "salesforce" "shibboleth"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "connected-apps-clients Get" } } | get name | first)
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

# Get
#
# GET /v1/connected_apps/clients/{client_id}
# operationId: api_connectedapps_v1_connected_apps_clients_Get
export def "connected-apps-clients Get" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<request_id: string, connected_app: record<client_id: string, client_name: string, client_description: string, status: string, full_access_allowed: bool, client_type: string, redirect_urls: list<string>, access_token_expiry_minutes: int, access_token_template_content: string, post_logout_redirect_urls: list<string>, bypass_consent_for_offline_access: bool, creation_method: string, client_secret_last_four: string, next_client_secret_last_four: string, access_token_custom_audience: string, logo_url: string, client_id_metadata_url: string>, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/connected_apps/clients/($client_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update
#
# PUT /v1/connected_apps/clients/{client_id}
# operationId: api_connectedapps_v1_connected_apps_clients_Update
export def "connected-apps-clients Update" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-name: string # A human-readable name for the client.
  --client-description: string # A human-readable description for the client.
  --redirect-urls: list # Array of redirect URI values for use in OAuth Authorization flows.
  --full-access-allowed: oneof<nothing, bool> # Valid for first party clients only. If `true`, an authorization token granted to this Client can be exchanged for a full Stytch session.
  --access-token-expiry-minutes: int # The number of minutes before the access token expires. The default is 60 minutes. (format: int32)
  --access-token-custom-audience: string # The custom audience for the access token.
  --access-token-template-content: string # The content of the access token custom claims template. The template must be a valid JSON object.
  --post-logout-redirect-urls: list # Array of redirect URI values for use in OIDC Logout flows.
  --logo-url: string # The logo URL of the Connected App, if any.
  --bypass-consent-for-offline-access: oneof<nothing, bool> # Valid for first party clients only. If true, the client does not need to request explicit user consent for the `offline_access` scope.
]: any -> record<request_id: string, connected_app: record<client_id: string, client_name: string, client_description: string, status: string, full_access_allowed: bool, client_type: string, redirect_urls: list<string>, access_token_expiry_minutes: int, access_token_template_content: string, post_logout_redirect_urls: list<string>, bypass_consent_for_offline_access: bool, creation_method: string, client_secret_last_four: string, next_client_secret_last_four: string, access_token_custom_audience: string, logo_url: string, client_id_metadata_url: string>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/connected_apps/clients/($client_id)")
  let body = {client_name: $client_name, client_description: $client_description, redirect_urls: $redirect_urls, full_access_allowed: $full_access_allowed, access_token_expiry_minutes: $access_token_expiry_minutes, access_token_custom_audience: $access_token_custom_audience, access_token_template_content: $access_token_template_content, post_logout_redirect_urls: $post_logout_redirect_urls, logo_url: $logo_url, bypass_consent_for_offline_access: $bypass_consent_for_offline_access} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /v1/connected_apps/clients/{client_id}
# operationId: api_connectedapps_v1_connected_apps_clients_Delete
export def "connected-apps-clients Delete" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<request_id: string, client_id: string, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/connected_apps/clients/($client_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search
#
# POST /v1/connected_apps/clients/search
# operationId: api_connectedapps_v1_connected_apps_clients_Search
export def "connected-apps-clients-search Search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # The `cursor` field allows you to paginate through your results. Each result array is limited to 1000 results. If your query returns more than 1000 results, you will need to paginate the responses using the `cursor`. If you receive a response that includes a non-null `next_cursor` in the `results_metadata` object, repeat the search call with the `next_cursor` value set to the `cursor` field to retrieve the next page of results. Continue to make search calls until the `next_cursor` in the response is null.
  --limit: int # The number of search results to return per page. The default limit is 100. A maximum of 1000 results can be returned by a single search request. If the total size of your result set is greater than one page size, you must paginate the response. See the `cursor` field. (format: int32)
]: any -> record<request_id: string, connected_apps: table<client_id: string, client_name: string, client_description: string, status: string, full_access_allowed: bool, client_type: string, redirect_urls: list, access_token_expiry_minutes: int, access_token_template_content: string, post_logout_redirect_urls: list, bypass_consent_for_offline_access: bool, creation_method: string, client_secret_last_four: string, next_client_secret_last_four: string, access_token_custom_audience: string, logo_url: string, client_id_metadata_url: string>, results_metadata: record<total: int, next_cursor: string>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connected_apps/clients/search")
  let body = {cursor: $cursor, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create
#
# POST /v1/connected_apps/clients
# operationId: api_connectedapps_v1_connected_apps_clients_Create
export def "connected-apps-clients Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  client_type: string@client-type-completer
  --client-name: string # A human-readable name for the client.
  --client-description: string # A human-readable description for the client.
  --redirect-urls: list # Array of redirect URI values for use in OAuth Authorization flows.
  --full-access-allowed: oneof<nothing, bool> # Valid for first party clients only. If `true`, an authorization token granted to this Client can be exchanged for a full Stytch session.
  --access-token-expiry-minutes: int # The number of minutes before the access token expires. The default is 60 minutes. (format: int32)
  --access-token-custom-audience: string # The custom audience for the access token.
  --access-token-template-content: string # The content of the access token custom claims template. The template must be a valid JSON object.
  --post-logout-redirect-urls: list # Array of redirect URI values for use in OIDC Logout flows.
  --logo-url: string # The logo URL of the Connected App, if any.
  --bypass-consent-for-offline-access: oneof<nothing, bool> # Valid for first party clients only. If true, the client does not need to request explicit user consent for the `offline_access` scope.
]: any -> record<request_id: string, connected_app: record<client_id: string, client_name: string, client_description: string, status: string, full_access_allowed: bool, client_type: string, redirect_urls: list<string>, access_token_expiry_minutes: int, access_token_template_content: string, post_logout_redirect_urls: list<string>, bypass_consent_for_offline_access: bool, client_secret_last_four: string, next_client_secret_last_four: string, client_secret: string, access_token_custom_audience: string, logo_url: string, client_id_metadata_url: string>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/connected_apps/clients")
  let body = {client_type: $client_type, client_name: $client_name, client_description: $client_description, redirect_urls: $redirect_urls, full_access_allowed: $full_access_allowed, access_token_expiry_minutes: $access_token_expiry_minutes, access_token_custom_audience: $access_token_custom_audience, access_token_template_content: $access_token_template_content, post_logout_redirect_urls: $post_logout_redirect_urls, logo_url: $logo_url, bypass_consent_for_offline_access: $bypass_consent_for_offline_access} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rotatestart
#
# POST /v1/connected_apps/clients/{client_id}/secrets/rotate/start
# operationId: api_connectedapps_v1_connected_apps_clients_secrets_RotateStart
export def "connected-apps-clients-secrets-rotate-start RotateStart" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<request_id: string, connected_app: record<client_id: string, client_name: string, client_description: string, status: string, client_secret_last_four: string, full_access_allowed: bool, client_type: string, redirect_urls: list<string>, next_client_secret: string, access_token_expiry_minutes: int, access_token_template_content: string, post_logout_redirect_urls: list<string>, bypass_consent_for_offline_access: bool, next_client_secret_last_four: string, access_token_custom_audience: string, logo_url: string, client_id_metadata_url: string>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/connected_apps/clients/($client_id)/secrets/rotate/start")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rotatecancel
#
# POST /v1/connected_apps/clients/{client_id}/secrets/rotate/cancel
# operationId: api_connectedapps_v1_connected_apps_clients_secrets_RotateCancel
export def "connected-apps-clients-secrets-rotate-cancel RotateCancel" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<request_id: string, connected_app: record<client_id: string, client_name: string, client_description: string, status: string, full_access_allowed: bool, client_type: string, redirect_urls: list<string>, access_token_expiry_minutes: int, access_token_template_content: string, post_logout_redirect_urls: list<string>, bypass_consent_for_offline_access: bool, creation_method: string, client_secret_last_four: string, next_client_secret_last_four: string, access_token_custom_audience: string, logo_url: string, client_id_metadata_url: string>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/connected_apps/clients/($client_id)/secrets/rotate/cancel")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rotate
#
# POST /v1/connected_apps/clients/{client_id}/secrets/rotate
# operationId: api_connectedapps_v1_connected_apps_clients_secrets_Rotate
export def "connected-apps-clients-secrets-rotate Rotate" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<request_id: string, connected_app: record<client_id: string, client_name: string, client_description: string, status: string, full_access_allowed: bool, client_type: string, redirect_urls: list<string>, access_token_expiry_minutes: int, access_token_template_content: string, post_logout_redirect_urls: list<string>, bypass_consent_for_offline_access: bool, creation_method: string, client_secret_last_four: string, next_client_secret_last_four: string, access_token_custom_audience: string, logo_url: string, client_id_metadata_url: string>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/connected_apps/clients/($client_id)/secrets/rotate")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update
#
# PUT /v1/b2b/scim/{organization_id}/connection/{connection_id}
# operationId: api_b2b_scim_v1_b2b_scim_connection_Update
# --scim_group_implicit_role_assignments item shape: {role_id: string, group_id: string, group_name: string}
export def "b2b-scim-connection Update" [
  organization_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
  --display-name: string # A human-readable display name for the connection.
  --identity-provider: string@identity-provider-completer
  --scim-group-implicit-role-assignments: list # An array of SCIM group implicit role assignments. Each object in the array must contain a `group_id` and a `role_id`. — item shape: {role_id: string, group_id: string, group_name: string}
]: any -> record<request_id: string, status_code: int, connection: record<organization_id: string, connection_id: string, status: string, display_name: string, identity_provider: string, base_url: string, bearer_token_last_four: string, scim_group_implicit_role_assignments: list<record>, next_bearer_token_last_four: string, bearer_token_expires_at: string, next_bearer_token_expires_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/scim/($organization_id)/connection/($connection_id)")
  let body = {display_name: $display_name, identity_provider: $identity_provider, scim_group_implicit_role_assignments: $scim_group_implicit_role_assignments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /v1/b2b/scim/{organization_id}/connection/{connection_id}
# operationId: api_b2b_scim_v1_b2b_scim_connection_Delete
export def "b2b-scim-connection Delete" [
  organization_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
]: nothing -> record<request_id: string, connection_id: string, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/scim/($organization_id)/connection/($connection_id)")
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Getgroups
#
# GET /v1/b2b/scim/{organization_id}/connection/{connection_id}
# operationId: api_b2b_scim_v1_b2b_scim_connection_GetGroups
export def "b2b-scim-connection GetGroups" [
  organization_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string
  --limit: int # format: int32
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
]: nothing -> record<scim_groups: table<group_id: string, group_name: string, organization_id: string, connection_id: string>, status_code: int, next_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cursor" $cursor "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/b2b/scim/($organization_id)/connection/($connection_id)" $qp)
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rotatestart
#
# POST /v1/b2b/scim/{organization_id}/connection/{connection_id}/rotate/start
# operationId: api_b2b_scim_v1_b2b_scim_connection_RotateStart
export def "b2b-scim-connection-rotate-start RotateStart" [
  organization_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
  --body: record
]: any -> record<request_id: string, status_code: int, connection: record<organization_id: string, connection_id: string, status: string, display_name: string, base_url: string, identity_provider: string, bearer_token_last_four: string, next_bearer_token: string, scim_group_implicit_role_assignments: list<record>, bearer_token_expires_at: string, next_bearer_token_expires_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/scim/($organization_id)/connection/($connection_id)/rotate/start")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rotatecomplete
#
# POST /v1/b2b/scim/{organization_id}/connection/{connection_id}/rotate/complete
# operationId: api_b2b_scim_v1_b2b_scim_connection_RotateComplete
export def "b2b-scim-connection-rotate-complete RotateComplete" [
  organization_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
  --body: record
]: any -> record<request_id: string, status_code: int, connection: record<organization_id: string, connection_id: string, status: string, display_name: string, identity_provider: string, base_url: string, bearer_token_last_four: string, scim_group_implicit_role_assignments: list<record>, next_bearer_token_last_four: string, bearer_token_expires_at: string, next_bearer_token_expires_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/scim/($organization_id)/connection/($connection_id)/rotate/complete")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rotatecancel
#
# POST /v1/b2b/scim/{organization_id}/connection/{connection_id}/rotate/cancel
# operationId: api_b2b_scim_v1_b2b_scim_connection_RotateCancel
export def "b2b-scim-connection-rotate-cancel RotateCancel" [
  organization_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
  --body: record
]: any -> record<request_id: string, status_code: int, connection: record<organization_id: string, connection_id: string, status: string, display_name: string, identity_provider: string, base_url: string, bearer_token_last_four: string, scim_group_implicit_role_assignments: list<record>, next_bearer_token_last_four: string, bearer_token_expires_at: string, next_bearer_token_expires_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/scim/($organization_id)/connection/($connection_id)/rotate/cancel")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create
#
# POST /v1/b2b/scim/{organization_id}/connection
# operationId: api_b2b_scim_v1_b2b_scim_connection_Create
export def "b2b-scim-connection Create" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
  --display-name: string # A human-readable display name for the connection.
  --identity-provider: string@identity-provider-completer
]: any -> record<request_id: string, status_code: int, connection: record<organization_id: string, connection_id: string, status: string, display_name: string, identity_provider: string, base_url: string, bearer_token: string, scim_group_implicit_role_assignments: list<record>, bearer_token_expires_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/scim/($organization_id)/connection")
  let body = {display_name: $display_name, identity_provider: $identity_provider} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get
#
# GET /v1/b2b/scim/{organization_id}/connection
# operationId: api_b2b_scim_v1_b2b_scim_connection_Get
export def "b2b-scim-connection Get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
]: nothing -> record<request_id: string, status_code: int, connection: record<organization_id: string, connection_id: string, status: string, display_name: string, identity_provider: string, base_url: string, bearer_token_last_four: string, scim_group_implicit_role_assignments: list<record>, next_bearer_token_last_four: string, bearer_token_expires_at: string, next_bearer_token_expires_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/scim/($organization_id)/connection")
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create
#
# POST /v1/b2b/organizations
# operationId: api_organization_v1_Create
# --rbac_email_implicit_role_assignments item shape: {domain: string, role_id: string}
export def "b2b-organizations Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organization_name: string # The name of the Organization. Must be between 1 and 128 characters in length.
  --organization-slug: string # The unique URL slug of the Organization. The slug only accepts alphanumeric characters and the following reserved characters: `-` `.` `_` `~`. Must be between 2 and 128 characters in length. Wherever an organization_id is expected in a path or request parameter, you may also use the organization_slug as a convenience.
  --organization-logo-url: string # The image URL of the Organization logo.
  --trusted-metadata: record # An arbitrary JSON object for storing application-specific data or identity-provider-specific data.
  --organization-external-id: string # An identifier that can be used in API calls wherever a organization_id is expected. This is a string consisting of alphanumeric, `.`, `_`, `-`, or `|` characters with a maximum length of 128 characters. External IDs must be unique within a project, but may be reused across different projects in the same workspace.
  --sso-jit-provisioning: string # The authentication setting that controls the JIT provisioning of Members when authenticating via SSO. The accepted values are:     `ALL_ALLOWED` – the default setting, new Members will be automatically provisioned upon successful authentication via any of the Organization's `sso_active_connections`.     `RESTRICTED` – only new Members with SSO logins that comply with `sso_jit_provisioning_allowed_connections` can be provisioned upon authentication.     `NOT_ALLOWED` – disable JIT provisioning via SSO.   
  --email-allowed-domains: list # An array of email domains that allow invites or JIT provisioning for new Members. This list is enforced when either `email_invites` or `email_jit_provisioning` is set to `RESTRICTED`.             Common domains such as `gmail.com` are not allowed. See the [common email domains resource](https://stytch.com/docs/b2b/api/common-email-domains) for the full list.
  --email-jit-provisioning: string # The authentication setting that controls how a new Member can be provisioned by authenticating via Email Magic Link or OAuth. The accepted values are:     `RESTRICTED` – only new Members with verified emails that comply with `email_allowed_domains` can be provisioned upon authentication via Email Magic Link or OAuth.     `NOT_ALLOWED` – the default setting, disables JIT provisioning via Email Magic Link and OAuth.   
  --email-invites: string # The authentication setting that controls how a new Member can be invited to an organization by email. The accepted values are:     `ALL_ALLOWED` – any new Member can be invited to join via email.     `RESTRICTED` – only new Members with verified emails that comply with `email_allowed_domains` can be invited via email.     `NOT_ALLOWED` – disable email invites.   
  --auth-methods: string # The setting that controls which authentication methods can be used by Members of an Organization. The accepted values are:     `ALL_ALLOWED` – the default setting which allows all authentication methods to be used.     `RESTRICTED` – only methods that comply with `allowed_auth_methods` can be used for authentication. This setting does not apply to Members with `is_breakglass` set to `true`.   
  --allowed-auth-methods: list # An array of allowed authentication methods. This list is enforced when `auth_methods` is set to `RESTRICTED`.   The list's accepted values are: `sso`, `magic_link`, `email_otp`, `password`, `google_oauth`, `microsoft_oauth`, `slack_oauth`, `github_oauth`, and `hubspot_oauth`.   
  --mfa-policy: string # The setting that controls the MFA policy for all Members in the Organization. The accepted values are:     `REQUIRED_FOR_ALL` – All Members within the Organization will be required to complete MFA every time they wish to log in. However, any active Session that existed prior to this setting change will remain valid.     `OPTIONAL` – The default value. The Organization does not require MFA by default for all Members. Members will be required to complete MFA only if their `mfa_enrolled` status is set to true.   
  --rbac-email-implicit-role-assignments: list # Implicit role assignments based off of email domains.   For each domain-Role pair, all Members whose email addresses have the specified email domain will be granted the   associated Role, regardless of their login method. See the [RBAC guide](https://stytch.com/docs/b2b/guides/rbac/role-assignment)   for more information about role assignment. — item shape: {domain: string, role_id: string}
  --mfa-methods: string # The setting that controls which MFA methods can be used by Members of an Organization. The accepted values are:     `ALL_ALLOWED` – the default setting which allows all authentication methods to be used.     `RESTRICTED` – only methods that comply with `allowed_mfa_methods` can be used for authentication. This setting does not apply to Members with `is_breakglass` set to `true`.   
  --allowed-mfa-methods: list # An array of allowed MFA authentication methods. This list is enforced when `mfa_methods` is set to `RESTRICTED`.   The list's accepted values are: `sms_otp` and `totp`.   
  --oauth-tenant-jit-provisioning: string # The authentication setting that controls how a new Member can JIT provision into an organization by tenant. The accepted values are:     `RESTRICTED` – only new Members with tenants in `allowed_oauth_tenants` can JIT provision via tenant.     `NOT_ALLOWED` – the default setting, disables JIT provisioning by OAuth Tenant.   
  --allowed-oauth-tenants: record # A map of allowed OAuth tenants. If this field is not passed in, the Organization will not allow JIT provisioning by OAuth Tenant. Allowed keys are "slack", "hubspot", and "github".
  --claimed-email-domains: list # A list of email domains that are claimed by the Organization.
  --first-party-connected-apps-allowed-type: string@first-party-connected-apps-allowed-type-completer
  --allowed-first-party-connected-apps: list # An array of first party Connected App IDs that are allowed for the Organization. Only used when the Organization's `first_party_connected_apps_allowed_type` is `RESTRICTED`.
  --third-party-connected-apps-allowed-type: string@third-party-connected-apps-allowed-type-completer
  --allowed-third-party-connected-apps: list # An array of third party Connected App IDs that are allowed for the Organization. Only used when the Organization's `third_party_connected_apps_allowed_type` is `RESTRICTED`.
]: any -> record<request_id: string, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/organizations")
  let body = {organization_name: $organization_name, organization_slug: $organization_slug, organization_logo_url: $organization_logo_url, trusted_metadata: $trusted_metadata, organization_external_id: $organization_external_id, sso_jit_provisioning: $sso_jit_provisioning, email_allowed_domains: $email_allowed_domains, email_jit_provisioning: $email_jit_provisioning, email_invites: $email_invites, auth_methods: $auth_methods, allowed_auth_methods: $allowed_auth_methods, mfa_policy: $mfa_policy, rbac_email_implicit_role_assignments: $rbac_email_implicit_role_assignments, mfa_methods: $mfa_methods, allowed_mfa_methods: $allowed_mfa_methods, oauth_tenant_jit_provisioning: $oauth_tenant_jit_provisioning, allowed_oauth_tenants: $allowed_oauth_tenants, claimed_email_domains: $claimed_email_domains, first_party_connected_apps_allowed_type: $first_party_connected_apps_allowed_type, allowed_first_party_connected_apps: $allowed_first_party_connected_apps, third_party_connected_apps_allowed_type: $third_party_connected_apps_allowed_type, allowed_third_party_connected_apps: $allowed_third_party_connected_apps} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get
#
# GET /v1/b2b/organizations/{organization_id}
# operationId: api_organization_v1_Get
export def "b2b-organizations Get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<request_id: string, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/organizations/($organization_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update
#
# PUT /v1/b2b/organizations/{organization_id}
# operationId: api_organization_v1_Update
# --rbac_email_implicit_role_assignments item shape: {domain: string, role_id: string}
export def "b2b-organizations Update" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
  --organization-name: string # The name of the Organization. Must be between 1 and 128 characters in length.  If this field is provided and a session header is passed into the request, the Member Session must have permission to perform the `update.info.name` action on the `stytch.organization` Resource.
  --organization-slug: string # The unique URL slug of the Organization. The slug only accepts alphanumeric characters and the following reserved characters: `-` `.` `_` `~`. Must be between 2 and 128 characters in length. Wherever an organization_id is expected in a path or request parameter, you may also use the organization_slug as a convenience.  If this field is provided and a session header is passed into the request, the Member Session must have permission to perform the `update.info.slug` action on the `stytch.organization` Resource.
  --organization-logo-url: string # The image URL of the Organization logo.  If this field is provided and a session header is passed into the request, the Member Session must have permission to perform the `update.info.logo-url` action on the `stytch.organization` Resource.
  --trusted-metadata: record # An arbitrary JSON object for storing application-specific data or identity-provider-specific data.           If a session header is passed into the request, this field may **not** be passed into the request. You cannot           update trusted metadata when acting as a Member.
  --organization-external-id: string # An identifier that can be used in API calls wherever a organization_id is expected. This is a string consisting of alphanumeric, `.`, `_`, `-`, or `|` characters with a maximum length of 128 characters. External IDs must be unique within a project, but may be reused across different projects in the same workspace.
  --sso-default-connection-id: string # The default connection used for SSO when there are multiple active connections.  If this field is provided and a session header is passed into the request, the Member Session must have permission to perform the `update.settings.default-sso-connection` action on the `stytch.organization` Resource.
  --sso-jit-provisioning: string # The authentication setting that controls the JIT provisioning of Members when authenticating via SSO. The accepted values are:     `ALL_ALLOWED` – the default setting, new Members will be automatically provisioned upon successful authentication via any of the Organization's `sso_active_connections`.     `RESTRICTED` – only new Members with SSO logins that comply with `sso_jit_provisioning_allowed_connections` can be provisioned upon authentication.     `NOT_ALLOWED` – disable JIT provisioning via SSO.     If this field is provided and a session header is passed into the request, the Member Session must have permission to perform the `update.settings.sso-jit-provisioning` action on the `stytch.organization` Resource.
  --sso-jit-provisioning-allowed-connections: list # An array of `connection_id`s that reference [SAML Connection objects](https://stytch.com/docs/b2b/api/saml-connection-object).   Only these connections will be allowed to JIT provision Members via SSO when `sso_jit_provisioning` is set to `RESTRICTED`.  If this field is provided and a session header is passed into the request, the Member Session must have permission to perform the `update.settings.sso-jit-provisioning` action on the `stytch.organization` Resource.
  --email-allowed-domains: list # An array of email domains that allow invites or JIT provisioning for new Members. This list is enforced when either `email_invites` or `email_jit_provisioning` is set to `RESTRICTED`.             Common domains such as `gmail.com` are not allowed. See the [common email domains resource](https://stytch.com/docs/b2b/api/common-email-domains) for the full list.  If this field is provided and a session header is passed into the request, the Member Session must have permission to perform the `update.settings.allowed-domains` action on the `stytch.organization` Resource.
  --email-jit-provisioning: string # The authentication setting that controls how a new Member can be provisioned by authenticating via Email Magic Link or OAuth. The accepted values are:     `RESTRICTED` – only new Members with verified emails that comply with `email_allowed_domains` can be provisioned upon authentication via Email Magic Link or OAuth.     `NOT_ALLOWED` – the default setting, disables JIT provisioning via Email Magic Link and OAuth.     If this field is provided and a session header is passed into the request, the Member Session must have permission to perform the `update.settings.email-jit-provisioning` action on the `stytch.organization` Resource.
  --email-invites: string # The authentication setting that controls how a new Member can be invited to an organization by email. The accepted values are:     `ALL_ALLOWED` – any new Member can be invited to join via email.     `RESTRICTED` – only new Members with verified emails that comply with `email_allowed_domains` can be invited via email.     `NOT_ALLOWED` – disable email invites.     If this field is provided and a session header is passed into the request, the Member Session must have permission to perform the `update.settings.email-invites` action on the `stytch.organization` Resource.
  --auth-methods: string # The setting that controls which authentication methods can be used by Members of an Organization. The accepted values are:     `ALL_ALLOWED` – the default setting which allows all authentication methods to be used.     `RESTRICTED` – only methods that comply with `allowed_auth_methods` can be used for authentication. This setting does not apply to Members with `is_breakglass` set to `true`.     If this field is provided and a session header is passed into the request, the Member Session must have permission to perform the `update.settings.allowed-auth-methods` action on the `stytch.organization` Resource.
  --allowed-auth-methods: list # An array of allowed authentication methods. This list is enforced when `auth_methods` is set to `RESTRICTED`.   The list's accepted values are: `sso`, `magic_link`, `email_otp`, `password`, `google_oauth`, `microsoft_oauth`, `slack_oauth`, `github_oauth`, and `hubspot_oauth`.     If this field is provided and a session header is passed into the request, the Member Session must have permission to perform the `update.settings.allowed-auth-methods` action on the `stytch.organization` Resource.
  --mfa-policy: string # The setting that controls the MFA policy for all Members in the Organization. The accepted values are:     `REQUIRED_FOR_ALL` – All Members within the Organization will be required to complete MFA every time they wish to log in. However, any active Session that existed prior to this setting change will remain valid.     `OPTIONAL` – The default value. The Organization does not require MFA by default for all Members. Members will be required to complete MFA only if their `mfa_enrolled` status is set to true.     If this field is provided and a session header is passed into the request, the Member Session must have permission to perform the `update.settings.mfa-policy` action on the `stytch.organization` Resource.
  --rbac-email-implicit-role-assignments: list # Implicit role assignments based off of email domains.   For each domain-Role pair, all Members whose email addresses have the specified email domain will be granted the   associated Role, regardless of their login method. See the [RBAC guide](https://stytch.com/docs/b2b/guides/rbac/role-assignment)   for more information about role assignment.  If this field is provided and a session header is passed into the request, the Member Session must have permission to perform the `update.settings.implicit-roles` action on the `stytch.organization` Resource. — item shape: {domain: string, role_id: string}
  --mfa-methods: string # The setting that controls which MFA methods can be used by Members of an Organization. The accepted values are:     `ALL_ALLOWED` – the default setting which allows all authentication methods to be used.     `RESTRICTED` – only methods that comply with `allowed_mfa_methods` can be used for authentication. This setting does not apply to Members with `is_breakglass` set to `true`.     If this field is provided and a session header is passed into the request, the Member Session must have permission to perform the `update.settings.allowed-mfa-methods` action on the `stytch.organization` Resource.
  --allowed-mfa-methods: list # An array of allowed MFA authentication methods. This list is enforced when `mfa_methods` is set to `RESTRICTED`.   The list's accepted values are: `sms_otp` and `totp`.     If this field is provided and a session header is passed into the request, the Member Session must have permission to perform the `update.settings.allowed-mfa-methods` action on the `stytch.organization` Resource.
  --oauth-tenant-jit-provisioning: string # The authentication setting that controls how a new Member can JIT provision into an organization by tenant. The accepted values are:     `RESTRICTED` – only new Members with tenants in `allowed_oauth_tenants` can JIT provision via tenant.     `NOT_ALLOWED` – the default setting, disables JIT provisioning by OAuth Tenant.     If this field is provided and a session header is passed into the request, the Member Session must have permission to perform the `update.settings.oauth-tenant-jit-provisioning` action on the `stytch.organization` Resource.
  --allowed-oauth-tenants: record # A map of allowed OAuth tenants. If this field is not passed in, the Organization will not allow JIT provisioning by OAuth Tenant. Allowed keys are "slack", "hubspot", and "github".  If this field is provided and a session header is passed into the request, the Member Session must have permission to perform the `update.settings.allowed-oauth-tenants` action on the `stytch.organization` Resource.
  --claimed-email-domains: list # A list of email domains that are claimed by the Organization.
  --first-party-connected-apps-allowed-type: string@first-party-connected-apps-allowed-type-completer
  --allowed-first-party-connected-apps: list # An array of first party Connected App IDs that are allowed for the Organization. Only used when the Organization's `first_party_connected_apps_allowed_type` is `RESTRICTED`.
  --third-party-connected-apps-allowed-type: string@third-party-connected-apps-allowed-type-completer
  --allowed-third-party-connected-apps: list # An array of third party Connected App IDs that are allowed for the Organization. Only used when the Organization's `third_party_connected_apps_allowed_type` is `RESTRICTED`.
]: any -> record<request_id: string, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/organizations/($organization_id)")
  let body = {organization_name: $organization_name, organization_slug: $organization_slug, organization_logo_url: $organization_logo_url, trusted_metadata: $trusted_metadata, organization_external_id: $organization_external_id, sso_default_connection_id: $sso_default_connection_id, sso_jit_provisioning: $sso_jit_provisioning, sso_jit_provisioning_allowed_connections: $sso_jit_provisioning_allowed_connections, email_allowed_domains: $email_allowed_domains, email_jit_provisioning: $email_jit_provisioning, email_invites: $email_invites, auth_methods: $auth_methods, allowed_auth_methods: $allowed_auth_methods, mfa_policy: $mfa_policy, rbac_email_implicit_role_assignments: $rbac_email_implicit_role_assignments, mfa_methods: $mfa_methods, allowed_mfa_methods: $allowed_mfa_methods, oauth_tenant_jit_provisioning: $oauth_tenant_jit_provisioning, allowed_oauth_tenants: $allowed_oauth_tenants, claimed_email_domains: $claimed_email_domains, first_party_connected_apps_allowed_type: $first_party_connected_apps_allowed_type, allowed_first_party_connected_apps: $allowed_first_party_connected_apps, third_party_connected_apps_allowed_type: $third_party_connected_apps_allowed_type, allowed_third_party_connected_apps: $allowed_third_party_connected_apps} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /v1/b2b/organizations/{organization_id}
# operationId: api_organization_v1_Delete
export def "b2b-organizations Delete" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
]: nothing -> record<request_id: string, organization_id: string, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/organizations/($organization_id)")
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search
#
# POST /v1/b2b/organizations/search
# operationId: api_organization_v1_Search
# --query shape: {operator: "OR"|"AND", operands: list}
export def "b2b-organizations-search Search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # The `cursor` field allows you to paginate through your results. Each result array is limited to 1000 results. If your query returns more than 1000 results, you will need to paginate the responses using the `cursor`. If you receive a response that includes a non-null `next_cursor` in the `results_metadata` object, repeat the search call with the `next_cursor` value set to the `cursor` field to retrieve the next page of results. Continue to make search calls until the `next_cursor` in the response is null.
  --limit: int # The number of search results to return per page. The default limit is 100. A maximum of 1000 results can be returned by a single search request. If the total size of your result set is greater than one page size, you must paginate the response. See the `cursor` field. (format: int32)
  --body-query: record # shape: {operator: "OR"|"AND", operands: list}
]: any -> record<request_id: string, organizations: table<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list, sso_active_connections: list, email_allowed_domains: list, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list, mfa_policy: string, rbac_email_implicit_role_assignments: list, mfa_methods: string, allowed_mfa_methods: list, oauth_tenant_jit_provisioning: string, claimed_email_domains: list, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list, custom_roles: list, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record, allowed_oauth_tenants: record>, results_metadata: record<total: int, next_cursor: string>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/organizations/search")
  let body = {cursor: $cursor, limit: $limit, query: $body_query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Metrics
#
# GET /v1/b2b/organizations/{organization_id}/metrics
# operationId: api_organization_v1_Metrics
export def "b2b-organizations-metrics Metrics" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<request_id: string, member_count: int, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/organizations/($organization_id)/metrics")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Connectedapps
#
# GET /v1/b2b/organizations/{organization_id}/connected_apps
# operationId: api_organization_v1_ConnectedApps
export def "b2b-organizations-connected-apps ConnectedApps" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
]: nothing -> record<request_id: string, connected_apps: table<connected_app_id: string, name: string, description: string, client_type: string, logo_url: string>, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/organizations/($organization_id)/connected_apps")
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Getconnectedapp
#
# GET /v1/b2b/organizations/{organization_id}/connected_apps/{connected_app_id}
# operationId: api_organization_v1_GetConnectedApp
export def "b2b-organizations-connected-apps GetConnectedApp" [
  organization_id: string
  connected_app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
]: nothing -> record<connected_app_id: string, name: string, description: string, client_type: string, active_members: table<member_id: string, granted_scopes: list>, status_code: int, logo_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/organizations/($organization_id)/connected_apps/($connected_app_id)")
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deleteexternalid
#
# DELETE /v1/b2b/organizations/{organization_id}/external_id
# operationId: api_organization_v1_DeleteExternalId
export def "b2b-organizations-external-id DeleteExternalId" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
]: nothing -> record<request_id: string, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/organizations/($organization_id)/external_id")
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update
#
# PUT /v1/b2b/organizations/{organization_id}/members/{member_id}
# operationId: api_organization_v1_organizations_members_Update
export def "b2b-organizations-members Update" [
  organization_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
  --name: string # The name of the Member.  If this field is provided and a session header is passed into the request, the Member Session must have permission to perform the `update.info.name` action on the `stytch.member` Resource. Alternatively, if the Member Session matches the Member associated with the `member_id` passed in the request, the authorization check will also allow a Member Session that has permission to perform the `update.info.name` action on the `stytch.self` Resource.
  --trusted-metadata: record # An arbitrary JSON object for storing application-specific data or identity-provider-specific data.           If a session header is passed into the request, this field may **not** be passed into the request. You cannot           update trusted metadata when acting as a Member.
  --untrusted-metadata: record # An arbitrary JSON object of application-specific data. These fields can be edited directly by the   frontend SDK, and should not be used to store critical information. See the [Metadata resource](https://stytch.com/docs/b2b/api/metadata)   for complete field behavior details.  If this field is provided and a session header is passed into the request, the Member Session must have permission to perform the `update.info.untrusted-metadata` action on the `stytch.member` Resource. Alternatively, if the Member Session matches the Member associated with the `member_id` passed in the request, the authorization check will also allow a Member Session that has permission to perform the `update.info.untrusted-metadata` action on the `stytch.self` Resource.
  --is-breakglass: oneof<nothing, bool> # Identifies the Member as a break glass user - someone who has permissions to authenticate into an Organization by bypassing the Organization's settings. A break glass account is typically used for emergency purposes to gain access outside of normal authentication procedures. Refer to the [Organization object](https://stytch.com/docs/b2b/api/organization-object) and its `auth_methods` and `allowed_auth_methods` fields for more details.  If this field is provided and a session header is passed into the request, the Member Session must have permission to perform the `update.settings.is-breakglass` action on the `stytch.member` Resource.
  --mfa-phone-number: string # Sets the Member's phone number. Throws an error if the Member already has a phone number. To change the Member's phone number, use the [Delete member phone number endpoint](https://stytch.com/docs/b2b/api/delete-member-mfa-phone-number) to delete the Member's existing phone number first.  If this field is provided and a session header is passed into the request, the Member Session must have permission to perform the `update.info.mfa-phone` action on the `stytch.member` Resource. Alternatively, if the Member Session matches the Member associated with the `member_id` passed in the request, the authorization check will also allow a Member Session that has permission to perform the `update.info.mfa-phone` action on the `stytch.self` Resource.
  --mfa-enrolled: oneof<nothing, bool> # Sets whether the Member is enrolled in MFA. If true, the Member must complete an MFA step whenever they wish to log in to their Organization. If false, the Member only needs to complete an MFA step if the Organization's MFA policy is set to `REQUIRED_FOR_ALL`.  If this field is provided and a session header is passed into the request, the Member Session must have permission to perform the `update.settings.mfa-enrolled` action on the `stytch.member` Resource. Alternatively, if the Member Session matches the Member associated with the `member_id` passed in the request, the authorization check will also allow a Member Session that has permission to perform the `update.settings.mfa-enrolled` action on the `stytch.self` Resource.
  --roles: list # Roles to explicitly assign to this Member.  Will completely replace any existing explicitly assigned roles. See the  [RBAC guide](https://stytch.com/docs/b2b/guides/rbac/role-assignment) for more information about role assignment.     If a Role is removed from a Member, and the Member is also implicitly assigned this Role from an SSO connection    or an SSO group, we will by default revoke any existing sessions for the Member that contain any SSO    authentication factors with the affected connection ID. You can preserve these sessions by passing in the    `preserve_existing_sessions` parameter with a value of `true`.  If this field is provided and a session header is passed into the request, the Member Session must have permission to perform the `update.settings.roles` action on the `stytch.member` Resource.
  --preserve-existing-sessions: oneof<nothing, bool> # Whether to preserve existing sessions when explicit Roles that are revoked are also implicitly assigned   by SSO connection or SSO group. Defaults to `false` - that is, existing Member Sessions that contain SSO   authentication factors with the affected SSO connection IDs will be revoked.
  --default-mfa-method: string # The Member's default MFA method. This value is used to determine which secondary MFA method to use in the case of multiple methods registered for a Member. The current possible values are `sms_otp` and `totp`.  If this field is provided and a session header is passed into the request, the Member Session must have permission to perform the `update.settings.default-mfa-method` action on the `stytch.member` Resource. Alternatively, if the Member Session matches the Member associated with the `member_id` passed in the request, the authorization check will also allow a Member Session that has permission to perform the `update.settings.default-mfa-method` action on the `stytch.self` Resource.
  --email-address: string # Updates the Member's `email_address`, if provided. This will clear any existing passwords and require re-verification of the new email address.         If a Member's email address is changed, other Members in the same Organization cannot use the old email address, although the Member may update back to their old email address.         A Member's email address can only be useable again by other Members if the Member is deleted.  If this field is provided and a session header is passed into the request, the Member Session must have permission to perform the `update.info.email` action on the `stytch.member` Resource. Members cannot update their own email address.
  --external-id: string # An identifier that can be used in most API calls where a `member_id` is expected. This is a string consisting of alphanumeric, `.`, `_`, `-`, or `|` characters with a maximum length of 128 characters. External IDs must be unique within an organization, but may be reused across different organizations in the same project.
  --unlink-email: oneof<nothing, bool> # If `unlink_email` is `true` and an `email_address` is provided, the Member's previous email will be deleted instead of retired. Defaults to `false`.
]: any -> record<request_id: string, member_id: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/organizations/($organization_id)/members/($member_id)")
  let body = {name: $name, trusted_metadata: $trusted_metadata, untrusted_metadata: $untrusted_metadata, is_breakglass: $is_breakglass, mfa_phone_number: $mfa_phone_number, mfa_enrolled: $mfa_enrolled, roles: $roles, preserve_existing_sessions: $preserve_existing_sessions, default_mfa_method: $default_mfa_method, email_address: $email_address, external_id: $external_id, unlink_email: $unlink_email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /v1/b2b/organizations/{organization_id}/members/{member_id}
# operationId: api_organization_v1_organizations_members_Delete
export def "b2b-organizations-members Delete" [
  organization_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
]: nothing -> record<request_id: string, member_id: string, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/organizations/($organization_id)/members/($member_id)")
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reactivate
#
# PUT /v1/b2b/organizations/{organization_id}/members/{member_id}/reactivate
# operationId: api_organization_v1_organizations_members_Reactivate
export def "b2b-organizations-members-reactivate Reactivate" [
  organization_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
  --body: record
]: any -> record<request_id: string, member_id: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/organizations/($organization_id)/members/($member_id)/reactivate")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletemfaphonenumber
#
# DELETE /v1/b2b/organizations/{organization_id}/members/mfa_phone_numbers/{member_id}
# operationId: api_organization_v1_organizations_members_DeleteMFAPhoneNumber
export def "b2b-organizations-members-mfa-phone-numbers DeleteMFAPhoneNumber" [
  organization_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
]: nothing -> record<request_id: string, member_id: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/organizations/($organization_id)/members/mfa_phone_numbers/($member_id)")
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletetotp
#
# DELETE /v1/b2b/organizations/{organization_id}/members/{member_id}/totp
# operationId: api_organization_v1_organizations_members_DeleteTOTP
export def "b2b-organizations-members-totp DeleteTOTP" [
  organization_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
]: nothing -> record<request_id: string, member_id: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/organizations/($organization_id)/members/($member_id)/totp")
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search
#
# POST /v1/b2b/organizations/members/search
# operationId: api_organization_v1_organizations_members_Search
# --query shape: {operator: "OR"|"AND", operands: list}
export def "b2b-organizations-members-search Search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
  organization_ids: list # An array of organization_ids. At least one value is required.
  --cursor: string # The `cursor` field allows you to paginate through your results. Each result array is limited to 1000 results. If your query returns more than 1000 results, you will need to paginate the responses using the `cursor`. If you receive a response that includes a non-null `next_cursor` in the `results_metadata` object, repeat the search call with the `next_cursor` value set to the `cursor` field to retrieve the next page of results. Continue to make search calls until the `next_cursor` in the response is null.
  --limit: int # The number of search results to return per page. The default limit is 100. A maximum of 1000 results can be returned by a single search request. If the total size of your result set is greater than one page size, you must paginate the response. See the `cursor` field. (format: int32)
  --body-query: record # shape: {operator: "OR"|"AND", operands: list}
]: any -> record<request_id: string, members: table<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list, is_breakglass: bool, member_password_id: string, oauth_registrations: list, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record, external_id: string, lock_created_at: string, lock_expires_at: string>, results_metadata: record<total: int, next_cursor: string>, organizations: record, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/organizations/members/search")
  let body = {organization_ids: $organization_ids, cursor: $cursor, limit: $limit, query: $body_query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletepassword
#
# DELETE /v1/b2b/organizations/{organization_id}/members/passwords/{member_password_id}
# operationId: api_organization_v1_organizations_members_DeletePassword
export def "b2b-organizations-members-passwords DeletePassword" [
  organization_id: string
  member_password_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
]: nothing -> record<request_id: string, member_id: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/organizations/($organization_id)/members/passwords/($member_password_id)")
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Dangerouslyget
#
# GET /v1/b2b/organizations/members/dangerously_get/{member_id}
# operationId: api_organization_v1_organizations_members_DangerouslyGet
export def "b2b-organizations-members-dangerously-get DangerouslyGet" [
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-deleted: oneof<nothing, bool>
]: nothing -> record<request_id: string, member_id: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_deleted" $include_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/b2b/organizations/members/dangerously_get/($member_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Oidcproviders
#
# GET /v1/b2b/organizations/{organization_id}/members/{member_id}/oidc_providers
# operationId: api_organization_v1_organizations_members_OIDCProviders
export def "b2b-organizations-members-oidc-providers OIDCProviders" [
  organization_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-refresh-token: oneof<nothing, bool>
]: nothing -> record<request_id: string, registrations: table<provider_subject: string, id_token: string, access_token: string, access_token_expires_in: int, scopes: list, connection_id: string, refresh_token: string>, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_refresh_token" $include_refresh_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/b2b/organizations/($organization_id)/members/($member_id)/oidc_providers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unlinkretiredemail
#
# POST /v1/b2b/organizations/{organization_id}/members/{member_id}/unlink_retired_email
# operationId: api_organization_v1_organizations_members_UnlinkRetiredEmail
export def "b2b-organizations-members-unlink-retired-email UnlinkRetiredEmail" [
  organization_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
  --email-id: string # The globally unique UUID of a Member's email.
  --email-address: string # The email address of the Member.
]: any -> record<request_id: string, member_id: string, organization_id: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/organizations/($organization_id)/members/($member_id)/unlink_retired_email")
  let body = {email_id: $email_id, email_address: $email_address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Startemailupdate
#
# POST /v1/b2b/organizations/{organization_id}/members/{member_id}/start_email_update
# operationId: api_organization_v1_organizations_members_StartEmailUpdate
export def "b2b-organizations-members-start-email-update StartEmailUpdate" [
  organization_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
  email_address: string # The new email address for the Member.
  --login-redirect-url: string # The URL that the Member clicks from the login Email Magic Link. This URL should be an endpoint in the backend server that   verifies the request by querying Stytch's authenticate endpoint and finishes the login. If this value is not passed, the default login   redirect URL that you set in your Dashboard is used. If you have not set a default login redirect URL, an error is returned.
  --locale: string@locale-completer
  --login-template-id: string # Use a custom template for login emails. By default, it will use your default email template. Templates can be added in the [Stytch dashboard](https://stytch.com/dashboard/templates) using our built-in customization options or custom HTML templates with type “Magic Links - Login”.
  --delivery-method: string@delivery-method-completer
]: any -> record<request_id: string, member_id: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/organizations/($organization_id)/members/($member_id)/start_email_update")
  let body = {email_address: $email_address, login_redirect_url: $login_redirect_url, locale: $locale, login_template_id: $login_template_id, delivery_method: $delivery_method} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Getconnectedapps
#
# GET /v1/b2b/organizations/{organization_id}/members/{member_id}/connected_apps
# operationId: api_organization_v1_organizations_members_GetConnectedApps
export def "b2b-organizations-members-connected-apps GetConnectedApps" [
  organization_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
]: nothing -> record<request_id: string, connected_apps: table<connected_app_id: string, name: string, description: string, client_type: string, scopes_granted: string, logo_url: string>, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/organizations/($organization_id)/members/($member_id)/connected_apps")
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deleteexternalid
#
# DELETE /v1/b2b/organizations/{organization_id}/members/{member_id}/external_id
# operationId: api_organization_v1_organizations_members_DeleteExternalId
export def "b2b-organizations-members-external-id DeleteExternalId" [
  organization_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
]: nothing -> record<request_id: string, member_id: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/organizations/($organization_id)/members/($member_id)/external_id")
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create
#
# POST /v1/b2b/organizations/{organization_id}/members
# operationId: api_organization_v1_organizations_members_Create
export def "b2b-organizations-members Create" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
  email_address: string # The email address of the Member.
  --name: string # The name of the Member.
  --trusted-metadata: record # An arbitrary JSON object for storing application-specific data or identity-provider-specific data.
  --untrusted-metadata: record # An arbitrary JSON object of application-specific data. These fields can be edited directly by the   frontend SDK, and should not be used to store critical information. See the [Metadata resource](https://stytch.com/docs/b2b/api/metadata)   for complete field behavior details.
  --create-member-as-pending: oneof<nothing, bool> # Flag for whether or not to save a Member as `pending` or `active` in Stytch. It defaults to false. If true, new Members will be created with status `pending` in Stytch's backend. Their status will remain `pending` and they will continue to receive signup email templates for every Email Magic Link until that Member authenticates and becomes `active`. If false, new Members will be created with status `active`.
  --is-breakglass: oneof<nothing, bool> # Identifies the Member as a break glass user - someone who has permissions to authenticate into an Organization by bypassing the Organization's settings. A break glass account is typically used for emergency purposes to gain access outside of normal authentication procedures. Refer to the [Organization object](https://stytch.com/docs/b2b/api/organization-object) and its `auth_methods` and `allowed_auth_methods` fields for more details.
  --mfa-phone-number: string # The Member's phone number. A Member may only have one phone number. The phone number should be in E.164 format (i.e. +1XXXXXXXXXX).
  --mfa-enrolled: oneof<nothing, bool> # Sets whether the Member is enrolled in MFA. If true, the Member must complete an MFA step whenever they wish to log in to their Organization. If false, the Member only needs to complete an MFA step if the Organization's MFA policy is set to `REQUIRED_FOR_ALL`.
  --roles: list # Roles to explicitly assign to this Member. See the [RBAC guide](https://stytch.com/docs/b2b/guides/rbac/role-assignment)    for more information about role assignment.
  --external-id: string # An identifier that can be used in most API calls where a `member_id` is expected. This is a string consisting of alphanumeric, `.`, `_`, `-`, or `|` characters with a maximum length of 128 characters. External IDs must be unique within an organization, but may be reused across different organizations in the same project.
]: any -> record<request_id: string, member_id: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/organizations/($organization_id)/members")
  let body = {email_address: $email_address, name: $name, trusted_metadata: $trusted_metadata, untrusted_metadata: $untrusted_metadata, create_member_as_pending: $create_member_as_pending, is_breakglass: $is_breakglass, mfa_phone_number: $mfa_phone_number, mfa_enrolled: $mfa_enrolled, roles: $roles, external_id: $external_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get
#
# GET /v1/b2b/organizations/{organization_id}/member
# operationId: api_organization_v1_organizations_members_Get
export def "b2b-organizations-member Get" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --member-id: string
  --email-address: string
]: nothing -> record<request_id: string, member_id: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "member_id" $member_id "scalar") (serialize-qp "email_address" $email_address "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/b2b/organizations/($organization_id)/member" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Google
#
# GET /v1/b2b/organizations/{organization_id}/members/{member_id}/oauth_providers/google
# operationId: api_organization_v1_organizations_members_oauth_providers_Google
export def "b2b-organizations-members-oauth-providers-google Google" [
  organization_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-refresh-token: oneof<nothing, bool>
]: nothing -> record<request_id: string, provider_type: string, provider_subject: string, id_token: string, scopes: list<string>, status_code: int, access_token: string, access_token_expires_in: int, refresh_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_refresh_token" $include_refresh_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/b2b/organizations/($organization_id)/members/($member_id)/oauth_providers/google" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Microsoft
#
# GET /v1/b2b/organizations/{organization_id}/members/{member_id}/oauth_providers/microsoft
# operationId: api_organization_v1_organizations_members_oauth_providers_Microsoft
export def "b2b-organizations-members-oauth-providers-microsoft Microsoft" [
  organization_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-refresh-token: oneof<nothing, bool>
]: nothing -> record<request_id: string, provider_type: string, provider_subject: string, access_token: string, access_token_expires_in: int, id_token: string, scopes: list<string>, status_code: int, refresh_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_refresh_token" $include_refresh_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/b2b/organizations/($organization_id)/members/($member_id)/oauth_providers/microsoft" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Slack
#
# GET /v1/b2b/organizations/{organization_id}/members/{member_id}/oauth_providers/slack
# operationId: api_organization_v1_organizations_members_oauth_providers_Slack
export def "b2b-organizations-members-oauth-providers-slack Slack" [
  organization_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<request_id: string, provider_type: string, registrations: table<provider_subject: string, provider_tenant_id: string, access_token: string, scopes: list, bot_access_token: string, bot_scopes: list>, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/organizations/($organization_id)/members/($member_id)/oauth_providers/slack")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Hubspot
#
# GET /v1/b2b/organizations/{organization_id}/members/{member_id}/oauth_providers/hubspot
# operationId: api_organization_v1_organizations_members_oauth_providers_Hubspot
export def "b2b-organizations-members-oauth-providers-hubspot Hubspot" [
  organization_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-refresh-token: oneof<nothing, bool>
]: nothing -> record<request_id: string, provider_type: string, registrations: table<provider_subject: string, provider_tenant_id: string, access_token: string, access_token_expires_in: int, scopes: list, refresh_token: string>, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_refresh_token" $include_refresh_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/b2b/organizations/($organization_id)/members/($member_id)/oauth_providers/hubspot" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Github
#
# GET /v1/b2b/organizations/{organization_id}/members/{member_id}/oauth_providers/github
# operationId: api_organization_v1_organizations_members_oauth_providers_Github
export def "b2b-organizations-members-oauth-providers-github Github" [
  organization_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --include-refresh-token: oneof<nothing, bool>
]: nothing -> record<request_id: string, provider_type: string, registrations: table<provider_subject: string, provider_tenant_ids: list, access_token: string, scopes: list>, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include_refresh_token" $include_refresh_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/b2b/organizations/($organization_id)/members/($member_id)/oauth_providers/github" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revoke
#
# POST /v1/b2b/organizations/{organization_id}/members/{member_id}/connected_apps/{connected_app_id}/revoke
# operationId: api_organization_v1_organizations_members_connected_apps_Revoke
export def "b2b-organizations-members-connected-apps-revoke Revoke" [
  organization_id: string
  member_id: string
  connected_app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
  --body: record
]: any -> record<request_id: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/organizations/($organization_id)/members/($member_id)/connected_apps/($connected_app_id)/revoke")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authorizestart
#
# POST /v1/b2b/idp/oauth/authorize/start
# operationId: api_b2b_idp_v1_b2b_idp_oauth_AuthorizeStart
export def "b2b-idp-oauth-authorize-start AuthorizeStart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  client_id: string # The ID of the Connected App client.
  redirect_uri: string # The callback URI used to redirect the user after authentication. This is the same URI provided at the start of the OAuth flow.  This field is required when using the `authorization_code` grant.
  response_type: string # The OAuth 2.0 response type. For authorization code flows this value is `code`.
  scopes: list # An array of scopes requested by the client.
  --organization-id: string # Globally unique UUID that identifies a specific Organization. The `organization_id` is critical to perform operations on an Organization, so be sure to preserve this value. You may also use the organization_slug or organization_external_id here as a convenience.
  --member-id: string # Globally unique UUID that identifies a specific Member. The `member_id` is critical to perform operations on a Member, so be sure to preserve this value. You may use an external_id here if one is set for the member.
  --session-token: string # A secret token for a given Stytch Session.
  --session-jwt: string # The JSON Web Token (JWT) for a given Stytch Session.
  --prompt: string # Space separated list that specifies how the Authorization Server should prompt the user for reauthentication and consent. Only `consent` is supported today.
]: any -> record<request_id: string, member_id: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, client: record<client_id: string, client_name: string, client_description: string, client_type: string, logo_url: string>, consent_required: bool, scope_results: table<scope: string, description: string, is_grantable: bool>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/idp/oauth/authorize/start")
  let body = {client_id: $client_id, redirect_uri: $redirect_uri, response_type: $response_type, scopes: $scopes, organization_id: $organization_id, member_id: $member_id, session_token: $session_token, session_jwt: $session_jwt, prompt: $prompt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authorize
#
# POST /v1/b2b/idp/oauth/authorize
# operationId: api_b2b_idp_v1_b2b_idp_oauth_Authorize
export def "b2b-idp-oauth-authorize Authorize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consent-granted: oneof<nothing, bool> # Indicates whether the user granted the requested scopes.
  scopes: list # An array of scopes requested by the client.
  client_id: string # The ID of the Connected App client.
  redirect_uri: string # The callback URI used to redirect the user after authentication. This is the same URI provided at the start of the OAuth flow.  This field is required when using the `authorization_code` grant.
  response_type: string # The OAuth 2.0 response type. For authorization code flows this value is `code`.
  --organization-id: string # Globally unique UUID that identifies a specific Organization. The `organization_id` is critical to perform operations on an Organization, so be sure to preserve this value. You may also use the organization_slug or organization_external_id here as a convenience.
  --member-id: string # Globally unique UUID that identifies a specific Member. The `member_id` is critical to perform operations on a Member, so be sure to preserve this value. You may use an external_id here if one is set for the member.
  --session-token: string # A secret token for a given Stytch Session.
  --session-jwt: string # The JSON Web Token (JWT) for a given Stytch Session.
  --prompt: string # Space separated list that specifies how the Authorization Server should prompt the user for reauthentication and consent. Only `consent` is supported today.
  --state: string # An opaque value used to maintain state between the request and callback.
  --nonce: string # A string used to associate a client session with an ID token to mitigate replay attacks.
  --code-challenge: string # A base64url encoded challenge derived from the code verifier for PKCE flows.
  --resources: list
]: any -> record<request_id: string, redirect_uri: string, status_code: int, authorization_code: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/idp/oauth/authorize")
  let body = {consent_granted: $consent_granted, scopes: $scopes, client_id: $client_id, redirect_uri: $redirect_uri, response_type: $response_type, organization_id: $organization_id, member_id: $member_id, session_token: $session_token, session_jwt: $session_jwt, prompt: $prompt, state: $state, nonce: $nonce, code_challenge: $code_challenge, resources: $resources} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create
#
# POST /v1/users
# operationId: api_user_v1_Create
# --name shape: {first_name?: string, middle_name?: string, last_name?: string}
# --attributes shape: {ip_address?: string, user_agent?: string}
export def "users Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # The email address of the end user.
  --name: record # shape: {first_name?: string, middle_name?: string, last_name?: string}
  --attributes: record # shape: {ip_address?: string, user_agent?: string}
  --phone-number: string # The phone number to use for one-time passcodes. The phone number should be in E.164 format (i.e. +1XXXXXXXXXX). You may use +10000000000 to test this endpoint, see [Testing](https://stytch.com/docs/home#resources_testing) for more detail.
  --create-user-as-pending: oneof<nothing, bool> # Flag for whether or not to save a user as pending vs active in Stytch. Defaults to false.         If true, users will be saved with status pending in Stytch's backend until authenticated.         If false, users will be created as active. An example usage of         a true flag would be to require users to verify their phone by entering the OTP code before creating         an account for them.
  --trusted-metadata: record # The `trusted_metadata` field contains an arbitrary JSON object of application-specific data. See the [Metadata](https://stytch.com/docs/api/metadata) reference for complete field behavior details.
  --untrusted-metadata: record # The `untrusted_metadata` field contains an arbitrary JSON object of application-specific data. Untrusted metadata can be edited by end users directly via the SDK, and **cannot be used to store critical information.** See the [Metadata](https://stytch.com/docs/api/metadata) reference for complete field behavior details.
  --external-id: string # An identifier that can be used in API calls wherever a user_id is expected. This is a string consisting of alphanumeric, `.`, `_`, `-`, or `|` characters with a maximum length of 128 characters.
  --roles: list # Roles to explicitly assign to this User.    See the [RBAC guide](https://stytch.com/docs/guides/rbac/role-assignment) for more information about role assignment.
]: any -> record<request_id: string, user_id: string, email_id: string, status: string, phone_id: string, user: record<user_id: string, emails: list<record>, status: string, phone_numbers: list<record>, webauthn_registrations: list<record>, providers: list<record>, totps: list<record>, crypto_wallets: list<record>, biometric_registrations: list<record>, is_locked: bool, roles: list<string>, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/users")
  let body = {email: $email, name: $name, attributes: $attributes, phone_number: $phone_number, create_user_as_pending: $create_user_as_pending, trusted_metadata: $trusted_metadata, untrusted_metadata: $untrusted_metadata, external_id: $external_id, roles: $roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get
#
# GET /v1/users/{user_id}
# operationId: api_user_v1_Get
export def "users Get" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<request_id: string, user_id: string, emails: table<email_id: string, email: string, verified: bool>, status: string, phone_numbers: table<phone_id: string, phone_number: string, verified: bool>, webauthn_registrations: table<webauthn_registration_id: string, domain: string, user_agent: string, verified: bool, authenticator_type: string, name: string>, providers: table<provider_type: string, provider_subject: string, profile_picture_url: string, locale: string, oauth_user_registration_id: string>, totps: table<totp_id: string, verified: bool>, crypto_wallets: table<crypto_wallet_id: string, crypto_wallet_address: string, crypto_wallet_type: string, verified: bool>, biometric_registrations: table<biometric_registration_id: string, verified: bool>, is_locked: bool, roles: list<string>, status_code: int, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update
#
# PUT /v1/users/{user_id}
# operationId: api_user_v1_Update
# --name shape: {first_name?: string, middle_name?: string, last_name?: string}
# --attributes shape: {ip_address?: string, user_agent?: string}
export def "users Update" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: record # shape: {first_name?: string, middle_name?: string, last_name?: string}
  --attributes: record # shape: {ip_address?: string, user_agent?: string}
  --trusted-metadata: record # The `trusted_metadata` field contains an arbitrary JSON object of application-specific data. See the [Metadata](https://stytch.com/docs/api/metadata) reference for complete field behavior details.
  --untrusted-metadata: record # The `untrusted_metadata` field contains an arbitrary JSON object of application-specific data. Untrusted metadata can be edited by end users directly via the SDK, and **cannot be used to store critical information.** See the [Metadata](https://stytch.com/docs/api/metadata) reference for complete field behavior details.
  --external-id: string # An identifier that can be used in API calls wherever a user_id is expected. This is a string consisting of alphanumeric, `.`, `_`, `-`, or `|` characters with a maximum length of 128 characters.
  --roles: list # Roles to explicitly assign to this User.    See the [RBAC guide](https://stytch.com/docs/guides/rbac/role-assignment) for more information about role assignment.
]: any -> record<request_id: string, user_id: string, emails: table<email_id: string, email: string, verified: bool>, phone_numbers: table<phone_id: string, phone_number: string, verified: bool>, crypto_wallets: table<crypto_wallet_id: string, crypto_wallet_address: string, crypto_wallet_type: string, verified: bool>, user: record<user_id: string, emails: list<record>, status: string, phone_numbers: list<record>, webauthn_registrations: list<record>, providers: list<record>, totps: list<record>, crypto_wallets: list<record>, biometric_registrations: list<record>, is_locked: bool, roles: list<string>, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($user_id)")
  let body = {name: $name, attributes: $attributes, trusted_metadata: $trusted_metadata, untrusted_metadata: $untrusted_metadata, external_id: $external_id, roles: $roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /v1/users/{user_id}
# operationId: api_user_v1_Delete
export def "users Delete" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<request_id: string, user_id: string, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search
#
# POST /v1/users/search
# operationId: api_user_v1_Search
# --query shape: {operator: "OR"|"AND", operands: list}
export def "users-search Search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # The `cursor` field allows you to paginate through your results. Each result array is limited to 1000 results. If your query returns more than 1000 results, you will need to paginate the responses using the `cursor`. If you receive a response that includes a non-null `next_cursor` in the `results_metadata` object, repeat the search call with the `next_cursor` value set to the `cursor` field to retrieve the next page of results. Continue to make search calls until the `next_cursor` in the response is null.
  --limit: int # The number of search results to return per page. The default limit is 100. A maximum of 1000 results can be returned by a single search request. If the total size of your result set is greater than one page size, you must paginate the response. See the `cursor` field. (format: int32)
  --body-query: record # shape: {operator: "OR"|"AND", operands: list}
]: any -> record<request_id: string, results: table<user_id: string, emails: list, status: string, phone_numbers: list, webauthn_registrations: list, providers: list, totps: list, crypto_wallets: list, biometric_registrations: list, is_locked: bool, roles: list, name: record, created_at: string, password: record, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, results_metadata: record<total: int, next_cursor: string>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/users/search")
  let body = {cursor: $cursor, limit: $limit, query: $body_query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Exchangeprimaryfactor
#
# PUT /v1/users/{user_id}/exchange_primary_factor
# operationId: api_user_v1_ExchangePrimaryFactor
export def "users-exchange-primary-factor ExchangePrimaryFactor" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email-address: string # The email address to exchange to.
  --phone-number: string # The phone number to exchange to. The phone number should be in E.164 format (i.e. +1XXXXXXXXXX).
]: any -> record<request_id: string, user_id: string, user: record<user_id: string, emails: list<record>, status: string, phone_numbers: list<record>, webauthn_registrations: list<record>, providers: list<record>, totps: list<record>, crypto_wallets: list<record>, biometric_registrations: list<record>, is_locked: bool, roles: list<string>, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($user_id)/exchange_primary_factor")
  let body = {email_address: $email_address, phone_number: $phone_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deleteemail
#
# DELETE /v1/users/emails/{email_id}
# operationId: api_user_v1_DeleteEmail
export def "users-emails DeleteEmail" [
  email_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<request_id: string, user_id: string, user: record<user_id: string, emails: list<record>, status: string, phone_numbers: list<record>, webauthn_registrations: list<record>, providers: list<record>, totps: list<record>, crypto_wallets: list<record>, biometric_registrations: list<record>, is_locked: bool, roles: list<string>, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/emails/($email_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletephonenumber
#
# DELETE /v1/users/phone_numbers/{phone_id}
# operationId: api_user_v1_DeletePhoneNumber
export def "users-phone-numbers DeletePhoneNumber" [
  phone_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<request_id: string, user_id: string, user: record<user_id: string, emails: list<record>, status: string, phone_numbers: list<record>, webauthn_registrations: list<record>, providers: list<record>, totps: list<record>, crypto_wallets: list<record>, biometric_registrations: list<record>, is_locked: bool, roles: list<string>, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/phone_numbers/($phone_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletewebauthnregistration
#
# DELETE /v1/users/webauthn_registrations/{webauthn_registration_id}
# operationId: api_user_v1_DeleteWebAuthnRegistration
export def "users-webauthn-registrations DeleteWebAuthnRegistration" [
  webauthn_registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<request_id: string, user_id: string, user: record<user_id: string, emails: list<record>, status: string, phone_numbers: list<record>, webauthn_registrations: list<record>, providers: list<record>, totps: list<record>, crypto_wallets: list<record>, biometric_registrations: list<record>, is_locked: bool, roles: list<string>, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/webauthn_registrations/($webauthn_registration_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletebiometricregistration
#
# DELETE /v1/users/biometric_registrations/{biometric_registration_id}
# operationId: api_user_v1_DeleteBiometricRegistration
export def "users-biometric-registrations DeleteBiometricRegistration" [
  biometric_registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<request_id: string, user_id: string, user: record<user_id: string, emails: list<record>, status: string, phone_numbers: list<record>, webauthn_registrations: list<record>, providers: list<record>, totps: list<record>, crypto_wallets: list<record>, biometric_registrations: list<record>, is_locked: bool, roles: list<string>, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/biometric_registrations/($biometric_registration_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletetotp
#
# DELETE /v1/users/totps/{totp_id}
# operationId: api_user_v1_DeleteTOTP
export def "users-totps DeleteTOTP" [
  totp_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<request_id: string, user_id: string, user: record<user_id: string, emails: list<record>, status: string, phone_numbers: list<record>, webauthn_registrations: list<record>, providers: list<record>, totps: list<record>, crypto_wallets: list<record>, biometric_registrations: list<record>, is_locked: bool, roles: list<string>, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/totps/($totp_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletecryptowallet
#
# DELETE /v1/users/crypto_wallets/{crypto_wallet_id}
# operationId: api_user_v1_DeleteCryptoWallet
export def "users-crypto-wallets DeleteCryptoWallet" [
  crypto_wallet_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<request_id: string, user_id: string, user: record<user_id: string, emails: list<record>, status: string, phone_numbers: list<record>, webauthn_registrations: list<record>, providers: list<record>, totps: list<record>, crypto_wallets: list<record>, biometric_registrations: list<record>, is_locked: bool, roles: list<string>, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/crypto_wallets/($crypto_wallet_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletepassword
#
# DELETE /v1/users/passwords/{password_id}
# operationId: api_user_v1_DeletePassword
export def "users-passwords DeletePassword" [
  password_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<request_id: string, user_id: string, user: record<user_id: string, emails: list<record>, status: string, phone_numbers: list<record>, webauthn_registrations: list<record>, providers: list<record>, totps: list<record>, crypto_wallets: list<record>, biometric_registrations: list<record>, is_locked: bool, roles: list<string>, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/passwords/($password_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deleteoauthregistration
#
# DELETE /v1/users/oauth/{oauth_user_registration_id}
# operationId: api_user_v1_DeleteOAuthRegistration
export def "users-oauth DeleteOAuthRegistration" [
  oauth_user_registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<request_id: string, user_id: string, user: record<user_id: string, emails: list<record>, status: string, phone_numbers: list<record>, webauthn_registrations: list<record>, providers: list<record>, totps: list<record>, crypto_wallets: list<record>, biometric_registrations: list<record>, is_locked: bool, roles: list<string>, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/oauth/($oauth_user_registration_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deleteexternalid
#
# DELETE /v1/users/{user_id}/external_id
# operationId: api_user_v1_DeleteExternalId
export def "users-external-id DeleteExternalId" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<request_id: string, user_id: string, user: record<user_id: string, emails: list<record>, status: string, phone_numbers: list<record>, webauthn_registrations: list<record>, providers: list<record>, totps: list<record>, crypto_wallets: list<record>, biometric_registrations: list<record>, is_locked: bool, roles: list<string>, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($user_id)/external_id")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Connectedapps
#
# GET /v1/users/{user_id}/connected_apps
# operationId: api_user_v1_ConnectedApps
export def "users-connected-apps ConnectedApps" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<request_id: string, connected_apps: table<connected_app_id: string, name: string, description: string, client_type: string, scopes_granted: string, logo_url: string>, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($user_id)/connected_apps")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revoke
#
# POST /v1/users/{user_id}/connected_apps/{connected_app_id}/revoke
# operationId: api_user_v1_Revoke
export def "users-connected-apps-revoke Revoke" [
  user_id: string
  connected_app_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<request_id: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/users/($user_id)/connected_apps/($connected_app_id)/revoke")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get
#
# GET /v1/sessions
# operationId: api_session_v1_Get
export def "sessions Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --user-id: string
]: nothing -> record<request_id: string, sessions: table<session_id: string, user_id: string, authentication_factors: list, roles: list, started_at: string, last_accessed_at: string, expires_at: string, attributes: record, custom_claims: record>, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/sessions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Authenticate
#
# POST /v1/sessions/authenticate
# operationId: api_session_v1_Authenticate
# --authorization_check shape: {resource_id: string, action: string}
export def "sessions-authenticate Authenticate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --session-token: string # The session token to authenticate.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now; minimum of 5 and a maximum of 527040 minutes (366 days). Note that a successful authentication will continue to extend the session this many minutes. (format: int32)
  --session-jwt: string # The JWT to authenticate. You may provide a JWT that has expired according to its `exp` claim and needs to be refreshed. If the signature is valid and the underlying session is still active then Stytch will return a new JWT.
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To delete a key, supply a null value.    Custom claims made with reserved claims ("iss", "sub", "aud", "exp", "nbf", "iat", "jti") will be ignored. Total custom claims size cannot exceed four kilobytes.
  --authorization-check: record # shape: {resource_id: string, action: string}
]: any -> record<request_id: string, session: record<session_id: string, user_id: string, authentication_factors: list<record>, roles: list<string>, started_at: string, last_accessed_at: string, expires_at: string, attributes: record<ip_address: string, user_agent: string>, custom_claims: record>, session_token: string, session_jwt: string, user: record<user_id: string, emails: list<record>, status: string, phone_numbers: list<record>, webauthn_registrations: list<record>, providers: list<record>, totps: list<record>, crypto_wallets: list<record>, biometric_registrations: list<record>, is_locked: bool, roles: list<string>, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, status_code: int, verdict: record<authorized: bool, granting_roles: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sessions/authenticate")
  let body = {session_token: $session_token, session_duration_minutes: $session_duration_minutes, session_jwt: $session_jwt, session_custom_claims: $session_custom_claims, authorization_check: $authorization_check} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revoke
#
# POST /v1/sessions/revoke
# operationId: api_session_v1_Revoke
export def "sessions-revoke Revoke" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --session-id: string # The `session_id` to revoke.
  --session-token: string # The session token to revoke.
  --session-jwt: string # A JWT for the session to revoke.
]: any -> record<request_id: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sessions/revoke")
  let body = {session_id: $session_id, session_token: $session_token, session_jwt: $session_jwt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Migrate
#
# POST /v1/sessions/migrate
# operationId: api_session_v1_Migrate
export def "sessions-migrate Migrate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  session_token: string # The authorization token Stytch will pass in to the external userinfo endpoint.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will not be created. (format: int32)
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To delete a key, supply a null value.    Custom claims made with reserved claims ("iss", "sub", "aud", "exp", "nbf", "iat", "jti") will be ignored. Total custom claims size cannot exceed four kilobytes.
  --telemetry-id: string # If the `telemetry_id` is passed, as part of this request, Stytch will call the [Fingerprint Lookup API](https://stytch.com/docs/fraud/api/fingerprint-lookup) and store the associated fingerprints and IPGEO information for the User. Your workspace must be enabled for Device Fingerprinting to use this feature.
]: any -> record<request_id: string, user_id: string, session_token: string, session_jwt: string, user: record<user_id: string, emails: list<record>, status: string, phone_numbers: list<record>, webauthn_registrations: list<record>, providers: list<record>, totps: list<record>, crypto_wallets: list<record>, biometric_registrations: list<record>, is_locked: bool, roles: list<string>, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, status_code: int, session: record<session_id: string, user_id: string, authentication_factors: list<record>, roles: list<string>, started_at: string, last_accessed_at: string, expires_at: string, attributes: record<ip_address: string, user_agent: string>, custom_claims: record>, user_device: record<visitor_id: string, visitor_id_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_address: string, ip_address_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_geo_city: string, ip_geo_region: string, ip_geo_country: string, ip_geo_country_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sessions/migrate")
  let body = {session_token: $session_token, session_duration_minutes: $session_duration_minutes, session_custom_claims: $session_custom_claims, telemetry_id: $telemetry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Exchangeaccesstoken
#
# POST /v1/sessions/exchange_access_token
# operationId: api_session_v1_ExchangeAccessToken
export def "sessions-exchange-access-token ExchangeAccessToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  access_token: string # The access token to exchange for a Stytch Session. Must be granted the `full_access` scope.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will not be created. (format: int32)
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To delete a key, supply a null value.    Custom claims made with reserved claims ("iss", "sub", "aud", "exp", "nbf", "iat", "jti") will be ignored. Total custom claims size cannot exceed four kilobytes.
  --telemetry-id: string # If the `telemetry_id` is passed, as part of this request, Stytch will call the [Fingerprint Lookup API](https://stytch.com/docs/fraud/api/fingerprint-lookup) and store the associated fingerprints and IPGEO information for the User. Your workspace must be enabled for Device Fingerprinting to use this feature.
]: any -> record<request_id: string, user_id: string, session_token: string, session_jwt: string, user: record<user_id: string, emails: list<record>, status: string, phone_numbers: list<record>, webauthn_registrations: list<record>, providers: list<record>, totps: list<record>, crypto_wallets: list<record>, biometric_registrations: list<record>, is_locked: bool, roles: list<string>, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, status_code: int, session: record<session_id: string, user_id: string, authentication_factors: list<record>, roles: list<string>, started_at: string, last_accessed_at: string, expires_at: string, attributes: record<ip_address: string, user_agent: string>, custom_claims: record>, user_device: record<visitor_id: string, visitor_id_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_address: string, ip_address_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_geo_city: string, ip_geo_region: string, ip_geo_country: string, ip_geo_country_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sessions/exchange_access_token")
  let body = {access_token: $access_token, session_duration_minutes: $session_duration_minutes, session_custom_claims: $session_custom_claims, telemetry_id: $telemetry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Getjwks
#
# GET /v1/sessions/jwks/{project_id}
# operationId: api_session_v1_GetJWKS
export def "sessions-jwks GetJWKS" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<keys: table<kty: string, use: string, key_ops: list, alg: string, kid: string, x5c: list, x5tS256: string, n: string, e: string>, request_id: string, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/sessions/jwks/($project_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Attest
#
# POST /v1/sessions/attest
# operationId: api_session_v1_Attest
export def "sessions-attest Attest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  profile_id: string # The ID of the trusted auth token profile to use for attestation.
  --body-token: string # The trusted auth token to authenticate.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will not be created. (format: int32)
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To delete a key, supply a null value.    Custom claims made with reserved claims ("iss", "sub", "aud", "exp", "nbf", "iat", "jti") will be ignored. Total custom claims size cannot exceed four kilobytes.
  --session-token: string # The `session_token` for the session that you wish to add the trusted auth token authentication factor to.
  --session-jwt: string # The `session_jwt` for the session that you wish to add the trusted auth token authentication factor to.
  --telemetry-id: string # If the `telemetry_id` is passed, as part of this request, Stytch will call the [Fingerprint Lookup API](https://stytch.com/docs/fraud/api/fingerprint-lookup) and store the associated fingerprints and IPGEO information for the User. Your workspace must be enabled for Device Fingerprinting to use this feature.
]: any -> record<request_id: string, user_id: string, session_token: string, session_jwt: string, user: record<user_id: string, emails: list<record>, status: string, phone_numbers: list<record>, webauthn_registrations: list<record>, providers: list<record>, totps: list<record>, crypto_wallets: list<record>, biometric_registrations: list<record>, is_locked: bool, roles: list<string>, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, status_code: int, session: record<session_id: string, user_id: string, authentication_factors: list<record>, roles: list<string>, started_at: string, last_accessed_at: string, expires_at: string, attributes: record<ip_address: string, user_agent: string>, custom_claims: record>, user_device: record<visitor_id: string, visitor_id_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_address: string, ip_address_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_geo_city: string, ip_geo_region: string, ip_geo_country: string, ip_geo_country_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/sessions/attest")
  let body = {profile_id: $profile_id, token: $body_token, session_duration_minutes: $session_duration_minutes, session_custom_claims: $session_custom_claims, session_token: $session_token, session_jwt: $session_jwt, telemetry_id: $telemetry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get
#
# GET /v1/b2b/sessions
# operationId: api_b2b_session_v1_Get
export def "b2b-sessions Get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --organization-id: string
  --member-id: string
]: nothing -> record<request_id: string, member_sessions: table<member_session_id: string, member_id: string, started_at: string, last_accessed_at: string, expires_at: string, authentication_factors: list, organization_id: string, roles: list, organization_slug: string, custom_claims: record>, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "organization_id" $organization_id "scalar") (serialize-qp "member_id" $member_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/b2b/sessions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Authenticate
#
# POST /v1/b2b/sessions/authenticate
# operationId: api_b2b_session_v1_Authenticate
# --authorization_check shape: {organization_id: string, resource_id: string, action: string}
export def "b2b-sessions-authenticate Authenticate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --session-token: string # A secret token for a given Stytch Session.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will be created with a 60 minute duration. If you don't want   to use the Stytch session product, you can ignore the session fields in the response. (format: int32)
  --session-jwt: string # The JSON Web Token (JWT) for a given Stytch Session.
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in   `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To   delete a key, supply a null value. Custom claims made with reserved claims (`iss`, `sub`, `aud`, `exp`, `nbf`, `iat`, `jti`) will be ignored.   Total custom claims size cannot exceed four kilobytes.
  --authorization-check: record # shape: {organization_id: string, resource_id: string, action: string}
]: any -> record<request_id: string, member_session: record<member_session_id: string, member_id: string, started_at: string, last_accessed_at: string, expires_at: string, authentication_factors: list<record>, organization_id: string, roles: list<string>, organization_slug: string, custom_claims: record>, session_token: string, session_jwt: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, status_code: int, verdict: record<authorized: bool, granting_roles: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/sessions/authenticate")
  let body = {session_token: $session_token, session_duration_minutes: $session_duration_minutes, session_jwt: $session_jwt, session_custom_claims: $session_custom_claims, authorization_check: $authorization_check} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revoke
#
# POST /v1/b2b/sessions/revoke
# operationId: api_b2b_session_v1_Revoke
export def "b2b-sessions-revoke Revoke" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
  --member-session-id: string # Globally unique UUID that identifies a specific Session in the Stytch API. The `member_session_id` is critical to perform operations on an Session, so be sure to preserve this value.
  --session-token: string # A secret token for a given Stytch Session.
  --session-jwt: string # The JSON Web Token (JWT) for a given Stytch Session.
  --member-id: string # Globally unique UUID that identifies a specific Member. The `member_id` is critical to perform operations on a Member, so be sure to preserve this value.
]: any -> record<request_id: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/sessions/revoke")
  let body = {member_session_id: $member_session_id, session_token: $session_token, session_jwt: $session_jwt, member_id: $member_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Exchange
#
# POST /v1/b2b/sessions/exchange
# operationId: api_b2b_session_v1_Exchange
export def "b2b-sessions-exchange Exchange" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organization_id: string # Globally unique UUID that identifies a specific Organization. The `organization_id` is critical to perform operations on an Organization, so be sure to preserve this value. You may also use the organization_slug or organization_external_id here as a convenience.
  --session-token: string # The `session_token` belonging to the member that you wish to associate the email with.
  --session-jwt: string # The `session_jwt` belonging to the member that you wish to associate the email with.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will be created with a 60 minute duration. If you don't want   to use the Stytch session product, you can ignore the session fields in the response. (format: int32)
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in   `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To   delete a key, supply a null value. Custom claims made with reserved claims (`iss`, `sub`, `aud`, `exp`, `nbf`, `iat`, `jti`) will be ignored.   Total custom claims size cannot exceed four kilobytes.
  --locale: string@locale-completer-1
  --telemetry-id: string # If the `telemetry_id` is passed, as part of this request, Stytch will call the [Fingerprint Lookup API](https://stytch.com/docs/fraud/api/fingerprint-lookup) and store the associated fingerprints and IPGEO information for the Member. Your workspace must be enabled for Device Fingerprinting to use this feature.
]: any -> record<request_id: string, member_id: string, session_token: string, session_jwt: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, member_authenticated: bool, intermediate_session_token: string, status_code: int, member_session: record<member_session_id: string, member_id: string, started_at: string, last_accessed_at: string, expires_at: string, authentication_factors: list<record>, organization_id: string, roles: list<string>, organization_slug: string, custom_claims: record>, mfa_required: record<member_options: record<mfa_phone_number: string, totp_registration_id: string>, secondary_auth_initiated: string>, primary_required: record<allowed_auth_methods: list<string>>, member_device: record<visitor_id: string, visitor_id_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_address: string, ip_address_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_geo_city: string, ip_geo_region: string, ip_geo_country: string, ip_geo_country_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/sessions/exchange")
  let body = {organization_id: $organization_id, session_token: $session_token, session_jwt: $session_jwt, session_duration_minutes: $session_duration_minutes, session_custom_claims: $session_custom_claims, locale: $locale, telemetry_id: $telemetry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Exchangeaccesstoken
#
# POST /v1/b2b/sessions/exchange_access_token
# operationId: api_b2b_session_v1_ExchangeAccessToken
export def "b2b-sessions-exchange-access-token ExchangeAccessToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  access_token: string # The access token to exchange for a Stytch Session. Must be granted the `full_access` scope.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will be created with a 60 minute duration. If you don't want   to use the Stytch session product, you can ignore the session fields in the response. (format: int32)
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in   `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To   delete a key, supply a null value. Custom claims made with reserved claims (`iss`, `sub`, `aud`, `exp`, `nbf`, `iat`, `jti`) will be ignored.   Total custom claims size cannot exceed four kilobytes.
  --telemetry-id: string # If the `telemetry_id` is passed, as part of this request, Stytch will call the [Fingerprint Lookup API](https://stytch.com/docs/fraud/api/fingerprint-lookup) and store the associated fingerprints and IPGEO information for the Member. Your workspace must be enabled for Device Fingerprinting to use this feature.
]: any -> record<request_id: string, member_id: string, session_token: string, session_jwt: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, status_code: int, member_session: record<member_session_id: string, member_id: string, started_at: string, last_accessed_at: string, expires_at: string, authentication_factors: list<record>, organization_id: string, roles: list<string>, organization_slug: string, custom_claims: record>, member_device: record<visitor_id: string, visitor_id_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_address: string, ip_address_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_geo_city: string, ip_geo_region: string, ip_geo_country: string, ip_geo_country_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/sessions/exchange_access_token")
  let body = {access_token: $access_token, session_duration_minutes: $session_duration_minutes, session_custom_claims: $session_custom_claims, telemetry_id: $telemetry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Attest
#
# POST /v1/b2b/sessions/attest
# operationId: api_b2b_session_v1_Attest
export def "b2b-sessions-attest Attest" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  profile_id: string # The ID of the trusted auth token profile to use for attestation.
  --body-token: string # The trusted auth token to authenticate. The token must have an organization ID claim if JIT provisioning is enabled.
  --organization-id: string # The organization ID that the session should be authenticated in. Must be provided if the trusted auth token does not have an organization ID claim.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will be created with a 60 minute duration. If you don't want   to use the Stytch session product, you can ignore the session fields in the response. (format: int32)
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in   `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To   delete a key, supply a null value. Custom claims made with reserved claims (`iss`, `sub`, `aud`, `exp`, `nbf`, `iat`, `jti`) will be ignored.   Total custom claims size cannot exceed four kilobytes.
  --session-token: string # The `session_token` for the session that you wish to add the trusted auth token authentication factor to.
  --session-jwt: string # The `session_jwt` for the session that you wish to add the trusted auth token authentication factor to.
  --telemetry-id: string # If the `telemetry_id` is passed, as part of this request, Stytch will call the [Fingerprint Lookup API](https://stytch.com/docs/fraud/api/fingerprint-lookup) and store the associated fingerprints and IPGEO information for the Member. Your workspace must be enabled for Device Fingerprinting to use this feature.
]: any -> record<request_id: string, member_id: string, member_session: record<member_session_id: string, member_id: string, started_at: string, last_accessed_at: string, expires_at: string, authentication_factors: list<record>, organization_id: string, roles: list<string>, organization_slug: string, custom_claims: record>, session_token: string, session_jwt: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, status_code: int, member_device: record<visitor_id: string, visitor_id_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_address: string, ip_address_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_geo_city: string, ip_geo_region: string, ip_geo_country: string, ip_geo_country_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/sessions/attest")
  let body = {profile_id: $profile_id, token: $body_token, organization_id: $organization_id, session_duration_minutes: $session_duration_minutes, session_custom_claims: $session_custom_claims, session_token: $session_token, session_jwt: $session_jwt, telemetry_id: $telemetry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Migrate
#
# POST /v1/b2b/sessions/migrate
# operationId: api_b2b_session_v1_Migrate
export def "b2b-sessions-migrate Migrate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  session_token: string # The authorization token Stytch will pass in to the external userinfo endpoint.
  organization_id: string # Globally unique UUID that identifies a specific Organization. The `organization_id` is critical to perform operations on an Organization, so be sure to preserve this value. You may also use the organization_slug or organization_external_id here as a convenience.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will be created with a 60 minute duration. If you don't want   to use the Stytch session product, you can ignore the session fields in the response. (format: int32)
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in   `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To   delete a key, supply a null value. Custom claims made with reserved claims (`iss`, `sub`, `aud`, `exp`, `nbf`, `iat`, `jti`) will be ignored.   Total custom claims size cannot exceed four kilobytes.
]: any -> record<request_id: string, member_id: string, session_token: string, session_jwt: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, status_code: int, member_session: record<member_session_id: string, member_id: string, started_at: string, last_accessed_at: string, expires_at: string, authentication_factors: list<record>, organization_id: string, roles: list<string>, organization_slug: string, custom_claims: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/sessions/migrate")
  let body = {session_token: $session_token, organization_id: $organization_id, session_duration_minutes: $session_duration_minutes, session_custom_claims: $session_custom_claims} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Getjwks
#
# GET /v1/b2b/sessions/jwks/{project_id}
# operationId: api_b2b_session_v1_GetJWKS
export def "b2b-sessions-jwks GetJWKS" [
  project_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<keys: table<kty: string, use: string, key_ops: list, alg: string, kid: string, x5c: list, x5tS256: string, n: string, e: string>, request_id: string, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/sessions/jwks/($project_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Authenticate
#
# POST /v1/b2b/impersonation/authenticate
# operationId: api_b2b_impersonation_v1_Authenticate
export def "b2b-impersonation-authenticate Authenticate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  impersonation_token: string # The Member Impersonation token to authenticate. Expires in 5 minutes by default.
]: any -> record<request_id: string, member_id: string, organization_id: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, session_token: string, session_jwt: string, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, intermediate_session_token: string, member_authenticated: bool, status_code: int, member_session: record<member_session_id: string, member_id: string, started_at: string, last_accessed_at: string, expires_at: string, authentication_factors: list<record>, organization_id: string, roles: list<string>, organization_slug: string, custom_claims: record>, mfa_required: record<member_options: record<mfa_phone_number: string, totp_registration_id: string>, secondary_auth_initiated: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/impersonation/authenticate")
  let body = {impersonation_token: $impersonation_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Policy
#
# GET /v1/b2b/rbac/policy
# operationId: api_b2b_rbac_v1_Policy
export def "b2b-rbac-policy Policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<request_id: string, status_code: int, policy: record<roles: list<record>, resources: list<record>, scopes: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/rbac/policy")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Getorgpolicy
#
# GET /v1/b2b/rbac/organizations/{organization_id}
# operationId: api_b2b_rbac_v1_b2b_rbac_organizations_GetOrgPolicy
export def "b2b-rbac-organizations GetOrgPolicy" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<request_id: string, org_policy: record<roles: list<record>>, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/rbac/organizations/($organization_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Setorgpolicy
#
# PUT /v1/b2b/rbac/organizations/{organization_id}
# operationId: api_b2b_rbac_v1_b2b_rbac_organizations_SetOrgPolicy
# --org_policy shape: {roles: list}
export def "b2b-rbac-organizations SetOrgPolicy" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  org_policy: record # shape: {roles: list}
]: any -> record<request_id: string, org_policy: record<roles: list<record>>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/rbac/organizations/($organization_id)")
  let body = {org_policy: $org_policy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Recover
#
# POST /v1/b2b/recovery_codes/recover
# operationId: api_b2b_recovery_codes_v1_Recover
export def "b2b-recovery-codes-recover Recover" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organization_id: string # Globally unique UUID that identifies a specific Organization. The `organization_id` is critical to perform operations on an Organization, so be sure to preserve this value. You may also use the organization_slug or organization_external_id here as a convenience.
  member_id: string # Globally unique UUID that identifies a specific Member. The `member_id` is critical to perform operations on a Member, so be sure to preserve this value. You may use an external_id here if one is set for the member.
  recovery_code: string # The recovery code generated by a secondary MFA method. This code is used to authenticate in place of the secondary MFA method if that method as a backup.
  --intermediate-session-token: string # The Intermediate Session Token. This token does not necessarily belong to a specific instance of a Member, but represents a bag of factors that may be converted to a member session. The token can be used with the [OTP SMS Authenticate endpoint](https://stytch.com/docs/b2b/api/authenticate-otp-sms), [TOTP Authenticate endpoint](https://stytch.com/docs/b2b/api/authenticate-totp), or [Recovery Codes Recover endpoint](https://stytch.com/docs/b2b/api/recovery-codes-recover) to complete an MFA flow and log in to the Organization. The token has a default expiry of 10 minutes. It can also be used with the [Exchange Intermediate Session endpoint](https://stytch.com/docs/b2b/api/exchange-intermediate-session) to join a specific Organization that allows the factors represented by the intermediate session token; or the [Create Organization via Discovery endpoint](https://stytch.com/docs/b2b/api/create-organization-via-discovery) to create a new Organization and Member. Intermediate Session Tokens have a default expiry of 10 minutes.
  --session-token: string # A secret token for a given Stytch Session.
  --session-jwt: string # The JSON Web Token (JWT) for a given Stytch Session.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will be created with a 60 minute duration. If you don't want   to use the Stytch session product, you can ignore the session fields in the response. (format: int32)
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in   `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To   delete a key, supply a null value. Custom claims made with reserved claims (`iss`, `sub`, `aud`, `exp`, `nbf`, `iat`, `jti`) will be ignored.   Total custom claims size cannot exceed four kilobytes.
  --telemetry-id: string # If the `telemetry_id` is passed, as part of this request, Stytch will call the [Fingerprint Lookup API](https://stytch.com/docs/fraud/api/fingerprint-lookup) and store the associated fingerprints and IPGEO information for the Member. Your workspace must be enabled for Device Fingerprinting to use this feature.
]: any -> record<request_id: string, member_id: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, session_token: string, session_jwt: string, recovery_codes_remaining: int, status_code: int, member_session: record<member_session_id: string, member_id: string, started_at: string, last_accessed_at: string, expires_at: string, authentication_factors: list<record>, organization_id: string, roles: list<string>, organization_slug: string, custom_claims: record>, member_device: record<visitor_id: string, visitor_id_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_address: string, ip_address_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_geo_city: string, ip_geo_region: string, ip_geo_country: string, ip_geo_country_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/recovery_codes/recover")
  let body = {organization_id: $organization_id, member_id: $member_id, recovery_code: $recovery_code, intermediate_session_token: $intermediate_session_token, session_token: $session_token, session_jwt: $session_jwt, session_duration_minutes: $session_duration_minutes, session_custom_claims: $session_custom_claims, telemetry_id: $telemetry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get
#
# GET /v1/b2b/recovery_codes/{organization_id}/{member_id}
# operationId: api_b2b_recovery_codes_v1_Get
export def "b2b-recovery-codes Get" [
  organization_id: string
  member_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<request_id: string, member_id: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, recovery_codes: list<string>, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/recovery_codes/($organization_id)/($member_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Rotate
#
# POST /v1/b2b/recovery_codes/rotate
# operationId: api_b2b_recovery_codes_v1_Rotate
export def "b2b-recovery-codes-rotate Rotate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organization_id: string # Globally unique UUID that identifies a specific Organization. The `organization_id` is critical to perform operations on an Organization, so be sure to preserve this value. You may also use the organization_slug or organization_external_id here as a convenience.
  member_id: string # Globally unique UUID that identifies a specific Member. The `member_id` is critical to perform operations on a Member, so be sure to preserve this value. You may use an external_id here if one is set for the member.
]: any -> record<request_id: string, member_id: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, recovery_codes: list<string>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/recovery_codes/rotate")
  let body = {organization_id: $organization_id, member_id: $member_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create
#
# POST /v1/b2b/totp
# operationId: api_b2b_totp_v1_Create
export def "b2b-totp Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organization_id: string # Globally unique UUID that identifies a specific Organization. The `organization_id` is critical to perform operations on an Organization, so be sure to preserve this value. You may also use the organization_slug or organization_external_id here as a convenience.
  member_id: string # Globally unique UUID that identifies a specific Member. The `member_id` is critical to perform operations on a Member, so be sure to preserve this value. You may use an external_id here if one is set for the member.
  --expiration-minutes: int # The expiration for the TOTP registration. If the newly created TOTP registration is not authenticated within this time frame the member will have to restart the registration flow. Defaults to 60 (1 hour) with a minimum of 5 and a maximum of 1440. (format: int32)
  --intermediate-session-token: string # The Intermediate Session Token. This token does not necessarily belong to a specific instance of a Member, but represents a bag of factors that may be converted to a member session. The token can be used with the [OTP SMS Authenticate endpoint](https://stytch.com/docs/b2b/api/authenticate-otp-sms), [TOTP Authenticate endpoint](https://stytch.com/docs/b2b/api/authenticate-totp), or [Recovery Codes Recover endpoint](https://stytch.com/docs/b2b/api/recovery-codes-recover) to complete an MFA flow and log in to the Organization. The token has a default expiry of 10 minutes. It can also be used with the [Exchange Intermediate Session endpoint](https://stytch.com/docs/b2b/api/exchange-intermediate-session) to join a specific Organization that allows the factors represented by the intermediate session token; or the [Create Organization via Discovery endpoint](https://stytch.com/docs/b2b/api/create-organization-via-discovery) to create a new Organization and Member. Intermediate Session Tokens have a default expiry of 10 minutes.
  --session-token: string # A secret token for a given Stytch Session.
  --session-jwt: string # The JSON Web Token (JWT) for a given Stytch Session.
]: any -> record<request_id: string, member_id: string, totp_registration_id: string, secret: string, qr_code: string, recovery_codes: list<string>, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/totp")
  let body = {organization_id: $organization_id, member_id: $member_id, expiration_minutes: $expiration_minutes, intermediate_session_token: $intermediate_session_token, session_token: $session_token, session_jwt: $session_jwt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authenticate
#
# POST /v1/b2b/totp/authenticate
# operationId: api_b2b_totp_v1_Authenticate
export def "b2b-totp-authenticate Authenticate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organization_id: string # Globally unique UUID that identifies a specific Organization. The `organization_id` is critical to perform operations on an Organization, so be sure to preserve this value. You may also use the organization_slug or organization_external_id here as a convenience.
  member_id: string # Globally unique UUID that identifies a specific Member. The `member_id` is critical to perform operations on a Member, so be sure to preserve this value. You may use an external_id here if one is set for the member.
  code: string # The code to authenticate.
  --intermediate-session-token: string # The Intermediate Session Token. This token does not necessarily belong to a specific instance of a Member, but represents a bag of factors that may be converted to a member session. The token can be used with the [OTP SMS Authenticate endpoint](https://stytch.com/docs/b2b/api/authenticate-otp-sms), [TOTP Authenticate endpoint](https://stytch.com/docs/b2b/api/authenticate-totp), or [Recovery Codes Recover endpoint](https://stytch.com/docs/b2b/api/recovery-codes-recover) to complete an MFA flow and log in to the Organization. The token has a default expiry of 10 minutes. It can also be used with the [Exchange Intermediate Session endpoint](https://stytch.com/docs/b2b/api/exchange-intermediate-session) to join a specific Organization that allows the factors represented by the intermediate session token; or the [Create Organization via Discovery endpoint](https://stytch.com/docs/b2b/api/create-organization-via-discovery) to create a new Organization and Member. Intermediate Session Tokens have a default expiry of 10 minutes.
  --session-token: string # A secret token for a given Stytch Session.
  --session-jwt: string # The JSON Web Token (JWT) for a given Stytch Session.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will be created with a 60 minute duration. If you don't want   to use the Stytch session product, you can ignore the session fields in the response. (format: int32)
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in   `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To   delete a key, supply a null value. Custom claims made with reserved claims (`iss`, `sub`, `aud`, `exp`, `nbf`, `iat`, `jti`) will be ignored.   Total custom claims size cannot exceed four kilobytes.
  --set-mfa-enrollment: string # Optionally sets the Member’s MFA enrollment status upon a successful authentication. If the Organization’s MFA policy is `REQUIRED_FOR_ALL`, this field will be ignored. If this field is not passed in, the Member’s `mfa_enrolled` boolean will not be affected. The options are:     `enroll` – sets the Member's `mfa_enrolled` boolean to `true`. The Member will be required to complete an MFA step upon subsequent logins to the Organization.     `unenroll` –  sets the Member's `mfa_enrolled` boolean to `false`. The Member will no longer be required to complete MFA steps when logging in to the Organization.   
  --set-default-mfa: oneof<nothing, bool> # If passed will set the authenticated method to the default MFA method. Completing an MFA authentication flow for the first time for a Member will implicitly set the method to the default MFA method. This option can be used to update the default MFA method if multiple are being used.
  --telemetry-id: string # If the `telemetry_id` is passed, as part of this request, Stytch will call the [Fingerprint Lookup API](https://stytch.com/docs/fraud/api/fingerprint-lookup) and store the associated fingerprints and IPGEO information for the Member. Your workspace must be enabled for Device Fingerprinting to use this feature.
]: any -> record<request_id: string, member_id: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, session_token: string, session_jwt: string, status_code: int, member_session: record<member_session_id: string, member_id: string, started_at: string, last_accessed_at: string, expires_at: string, authentication_factors: list<record>, organization_id: string, roles: list<string>, organization_slug: string, custom_claims: record>, member_device: record<visitor_id: string, visitor_id_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_address: string, ip_address_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_geo_city: string, ip_geo_region: string, ip_geo_country: string, ip_geo_country_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/totp/authenticate")
  let body = {organization_id: $organization_id, member_id: $member_id, code: $code, intermediate_session_token: $intermediate_session_token, session_token: $session_token, session_jwt: $session_jwt, session_duration_minutes: $session_duration_minutes, session_custom_claims: $session_custom_claims, set_mfa_enrollment: $set_mfa_enrollment, set_default_mfa: $set_default_mfa, telemetry_id: $telemetry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Migrate
#
# POST /v1/b2b/totp/migrate
# operationId: api_b2b_totp_v1_Migrate
export def "b2b-totp-migrate Migrate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organization_id: string # Globally unique UUID that identifies a specific Organization. The `organization_id` is critical to perform operations on an Organization, so be sure to preserve this value. You may also use the organization_slug or organization_external_id here as a convenience.
  member_id: string # Globally unique UUID that identifies a specific Member. The `member_id` is critical to perform operations on a Member, so be sure to preserve this value. You may use an external_id here if one is set for the member.
  secret: string # The TOTP secret key shared between the authenticator app and the server used to generate TOTP codes.
  recovery_codes: list # An existing set of recovery codes to be imported into Stytch to be used to authenticate in place of the secondary MFA method.
]: any -> record<request_id: string, member_id: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, totp_registration_id: string, recovery_codes: list<string>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/totp/migrate")
  let body = {organization_id: $organization_id, member_id: $member_id, secret: $secret, recovery_codes: $recovery_codes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Policy
#
# GET /v1/rbac/policy
# operationId: api_consumer_rbac_v1_Policy
export def "rbac-policy Policy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<request_id: string, status_code: int, policy: record<roles: list<record>, resources: list<record>, scopes: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/rbac/policy")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Authenticatestart
#
# POST /v1/crypto_wallets/authenticate/start
# operationId: api_crypto_wallet_v1_AuthenticateStart
# --siwe_params shape: {domain: string, uri: string, resources: list, chain_id?: string, statement?: string, issued_at?: string, not_before?: string, message_request_id?: string}
export def "crypto-wallets-authenticate-start AuthenticateStart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  crypto_wallet_type: string # The type of wallet to authenticate. Currently `ethereum` and `solana` are supported. Wallets for any EVM-compatible chains (such as Polygon or BSC) are also supported and are grouped under the `ethereum` type.
  crypto_wallet_address: string # The crypto wallet address to authenticate.
  --user-id: string # The unique ID of a specific User. You may use an `external_id` here if one is set for the user.
  --session-token: string # The `session_token` associated with a User's existing Session.
  --session-jwt: string # The `session_jwt` associated with a User's existing Session.
  --siwe-params: record # shape: {domain: string, uri: string, resources: list, chain_id?: string, statement?: string, issued_at?: string, not_before?: string, message_request_id?: string}
]: any -> record<request_id: string, user_id: string, challenge: string, user_created: bool, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/crypto_wallets/authenticate/start")
  let body = {crypto_wallet_type: $crypto_wallet_type, crypto_wallet_address: $crypto_wallet_address, user_id: $user_id, session_token: $session_token, session_jwt: $session_jwt, siwe_params: $siwe_params} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authenticate
#
# POST /v1/crypto_wallets/authenticate
# operationId: api_crypto_wallet_v1_Authenticate
export def "crypto-wallets-authenticate Authenticate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  crypto_wallet_type: string # The type of wallet to authenticate. Currently `ethereum` and `solana` are supported. Wallets for any EVM-compatible chains (such as Polygon or BSC) are also supported and are grouped under the `ethereum` type.
  crypto_wallet_address: string # The crypto wallet address to authenticate.
  signature: string # The signature from the message challenge.
  --session-token: string # The `session_token` associated with a User's existing Session.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will not be created. (format: int32)
  --session-jwt: string # The `session_jwt` associated with a User's existing Session.
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To delete a key, supply a null value.    Custom claims made with reserved claims ("iss", "sub", "aud", "exp", "nbf", "iat", "jti") will be ignored. Total custom claims size cannot exceed four kilobytes.
  --telemetry-id: string # If the `telemetry_id` is passed, as part of this request, Stytch will call the [Fingerprint Lookup API](https://stytch.com/docs/fraud/api/fingerprint-lookup) and store the associated fingerprints and IPGEO information for the User. Your workspace must be enabled for Device Fingerprinting to use this feature.
]: any -> record<request_id: string, user_id: string, session_token: string, session_jwt: string, user: record<user_id: string, emails: list<record>, status: string, phone_numbers: list<record>, webauthn_registrations: list<record>, providers: list<record>, totps: list<record>, crypto_wallets: list<record>, biometric_registrations: list<record>, is_locked: bool, roles: list<string>, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, status_code: int, session: record<session_id: string, user_id: string, authentication_factors: list<record>, roles: list<string>, started_at: string, last_accessed_at: string, expires_at: string, attributes: record<ip_address: string, user_agent: string>, custom_claims: record>, siwe_params: record<domain: string, uri: string, chain_id: string, resources: list<string>, status_code: int, issued_at: string, message_request_id: string>, user_device: record<visitor_id: string, visitor_id_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_address: string, ip_address_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_geo_city: string, ip_geo_region: string, ip_geo_country: string, ip_geo_country_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/crypto_wallets/authenticate")
  let body = {crypto_wallet_type: $crypto_wallet_type, crypto_wallet_address: $crypto_wallet_address, signature: $signature, session_token: $session_token, session_duration_minutes: $session_duration_minutes, session_jwt: $session_jwt, session_custom_claims: $session_custom_claims, telemetry_id: $telemetry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Whoami
#
# GET /v1/debug/whoami
# operationId: api_debug_v1_Whoami
export def "debug-whoami Whoami" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<request_id: string, project_id: string, name: string, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/debug/whoami")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Exchange
#
# POST /v1/b2b/discovery/intermediate_sessions/exchange
# operationId: api_discovery_v1_discovery_intermediate_sessions_Exchange
export def "b2b-discovery-intermediate-sessions-exchange Exchange" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  intermediate_session_token: string # The Intermediate Session Token. This token does not necessarily belong to a specific instance of a Member, but represents a bag of factors that may be converted to a member session. The token can be used with the [OTP SMS Authenticate endpoint](https://stytch.com/docs/b2b/api/authenticate-otp-sms), [TOTP Authenticate endpoint](https://stytch.com/docs/b2b/api/authenticate-totp), or [Recovery Codes Recover endpoint](https://stytch.com/docs/b2b/api/recovery-codes-recover) to complete an MFA flow and log in to the Organization. The token has a default expiry of 10 minutes. It can also be used with the [Exchange Intermediate Session endpoint](https://stytch.com/docs/b2b/api/exchange-intermediate-session) to join a specific Organization that allows the factors represented by the intermediate session token; or the [Create Organization via Discovery endpoint](https://stytch.com/docs/b2b/api/create-organization-via-discovery) to create a new Organization and Member. Intermediate Session Tokens have a default expiry of 10 minutes.
  organization_id: string # Globally unique UUID that identifies a specific Organization. The `organization_id` is critical to perform operations on an Organization, so be sure to preserve this value. You may also use the organization_slug or organization_external_id here as a convenience.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will be created with a 60 minute duration. If you don't want   to use the Stytch session product, you can ignore the session fields in the response. (format: int32)
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in   `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To   delete a key, supply a null value. Custom claims made with reserved claims (`iss`, `sub`, `aud`, `exp`, `nbf`, `iat`, `jti`) will be ignored.   Total custom claims size cannot exceed four kilobytes.
  --locale: string@locale-completer-1
  --telemetry-id: string # If the `telemetry_id` is passed, as part of this request, Stytch will call the [Fingerprint Lookup API](https://stytch.com/docs/fraud/api/fingerprint-lookup) and store the associated fingerprints and IPGEO information for the Member. Your workspace must be enabled for Device Fingerprinting to use this feature.
]: any -> record<request_id: string, member_id: string, session_token: string, session_jwt: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, member_authenticated: bool, intermediate_session_token: string, status_code: int, member_session: record<member_session_id: string, member_id: string, started_at: string, last_accessed_at: string, expires_at: string, authentication_factors: list<record>, organization_id: string, roles: list<string>, organization_slug: string, custom_claims: record>, mfa_required: record<member_options: record<mfa_phone_number: string, totp_registration_id: string>, secondary_auth_initiated: string>, primary_required: record<allowed_auth_methods: list<string>>, member_device: record<visitor_id: string, visitor_id_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_address: string, ip_address_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_geo_city: string, ip_geo_region: string, ip_geo_country: string, ip_geo_country_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/discovery/intermediate_sessions/exchange")
  let body = {intermediate_session_token: $intermediate_session_token, organization_id: $organization_id, session_duration_minutes: $session_duration_minutes, session_custom_claims: $session_custom_claims, locale: $locale, telemetry_id: $telemetry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create
#
# POST /v1/b2b/discovery/organizations/create
# operationId: api_discovery_v1_discovery_organizations_Create
# --rbac_email_implicit_role_assignments item shape: {domain: string, role_id: string}
export def "b2b-discovery-organizations-create Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  intermediate_session_token: string # The Intermediate Session Token. This token does not necessarily belong to a specific instance of a Member, but represents a bag of factors that may be converted to a member session. The token can be used with the [OTP SMS Authenticate endpoint](https://stytch.com/docs/b2b/api/authenticate-otp-sms), [TOTP Authenticate endpoint](https://stytch.com/docs/b2b/api/authenticate-totp), or [Recovery Codes Recover endpoint](https://stytch.com/docs/b2b/api/recovery-codes-recover) to complete an MFA flow and log in to the Organization. The token has a default expiry of 10 minutes. It can also be used with the [Exchange Intermediate Session endpoint](https://stytch.com/docs/b2b/api/exchange-intermediate-session) to join a specific Organization that allows the factors represented by the intermediate session token; or the [Create Organization via Discovery endpoint](https://stytch.com/docs/b2b/api/create-organization-via-discovery) to create a new Organization and Member. Intermediate Session Tokens have a default expiry of 10 minutes.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will be created with a 60 minute duration. If you don't want   to use the Stytch session product, you can ignore the session fields in the response. (format: int32)
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in   `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To   delete a key, supply a null value. Custom claims made with reserved claims (`iss`, `sub`, `aud`, `exp`, `nbf`, `iat`, `jti`) will be ignored.   Total custom claims size cannot exceed four kilobytes.
  --organization-name: string # The name of the Organization. If the name is not specified, a default name will be created based on the email used to initiate the discovery flow. If the email domain is a common email provider such as gmail.com, or if the email is a .edu email, the organization name will be generated based on the name portion of the email. Otherwise, the organization name will be generated based on the email domain.
  --organization-slug: string # The unique URL slug of the Organization. A minimum of two characters is required. The slug only accepts alphanumeric characters and the following reserved characters: `-` `.` `_` `~`. If the slug is not specified, a default slug will be created based on the email used to initiate the discovery flow. If the email domain is a common email provider such as gmail.com, or if the email is a .edu email, the organization slug will be generated based on the name portion of the email. Otherwise, the organization slug will be generated based on the email domain.
  --organization-external-id: string # An identifier that can be used in API calls wherever a organization_id is expected. This is a string consisting of alphanumeric, `.`, `_`, `-`, or `|` characters with a maximum length of 128 characters. External IDs must be unique within a project, but may be reused across different projects in the same workspace.
  --organization-logo-url: string # The image URL of the Organization logo.
  --trusted-metadata: record # An arbitrary JSON object for storing application-specific data or identity-provider-specific data.
  --sso-jit-provisioning: string # The authentication setting that controls the JIT provisioning of Members when authenticating via SSO. The accepted values are:     `ALL_ALLOWED` – the default setting, new Members will be automatically provisioned upon successful authentication via any of the Organization's `sso_active_connections`.     `RESTRICTED` – only new Members with SSO logins that comply with `sso_jit_provisioning_allowed_connections` can be provisioned upon authentication.     `NOT_ALLOWED` – disable JIT provisioning via SSO.   
  --email-allowed-domains: list # An array of email domains that allow invites or JIT provisioning for new Members. This list is enforced when either `email_invites` or `email_jit_provisioning` is set to `RESTRICTED`.             Common domains such as `gmail.com` are not allowed. See the [common email domains resource](https://stytch.com/docs/b2b/api/common-email-domains) for the full list.
  --email-jit-provisioning: string # The authentication setting that controls how a new Member can be provisioned by authenticating via Email Magic Link or OAuth. The accepted values are:     `RESTRICTED` – only new Members with verified emails that comply with `email_allowed_domains` can be provisioned upon authentication via Email Magic Link or OAuth.     `NOT_ALLOWED` – the default setting, disables JIT provisioning via Email Magic Link and OAuth.   
  --email-invites: string # The authentication setting that controls how a new Member can be invited to an organization by email. The accepted values are:     `ALL_ALLOWED` – any new Member can be invited to join via email.     `RESTRICTED` – only new Members with verified emails that comply with `email_allowed_domains` can be invited via email.     `NOT_ALLOWED` – disable email invites.   
  --auth-methods: string # The setting that controls which authentication methods can be used by Members of an Organization. The accepted values are:     `ALL_ALLOWED` – the default setting which allows all authentication methods to be used.     `RESTRICTED` – only methods that comply with `allowed_auth_methods` can be used for authentication. This setting does not apply to Members with `is_breakglass` set to `true`.   
  --allowed-auth-methods: list # An array of allowed authentication methods. This list is enforced when `auth_methods` is set to `RESTRICTED`.   The list's accepted values are: `sso`, `magic_link`, `email_otp`, `password`, `google_oauth`, `microsoft_oauth`, `slack_oauth`, `github_oauth`, and `hubspot_oauth`.   
  --mfa-policy: string # The setting that controls the MFA policy for all Members in the Organization. The accepted values are:     `REQUIRED_FOR_ALL` – All Members within the Organization will be required to complete MFA every time they wish to log in. However, any active Session that existed prior to this setting change will remain valid.     `OPTIONAL` – The default value. The Organization does not require MFA by default for all Members. Members will be required to complete MFA only if their `mfa_enrolled` status is set to true.   
  --rbac-email-implicit-role-assignments: list # Implicit role assignments based off of email domains.   For each domain-Role pair, all Members whose email addresses have the specified email domain will be granted the   associated Role, regardless of their login method. See the [RBAC guide](https://stytch.com/docs/b2b/guides/rbac/role-assignment)   for more information about role assignment. — item shape: {domain: string, role_id: string}
  --mfa-methods: string # The setting that controls which MFA methods can be used by Members of an Organization. The accepted values are:     `ALL_ALLOWED` – the default setting which allows all authentication methods to be used.     `RESTRICTED` – only methods that comply with `allowed_mfa_methods` can be used for authentication. This setting does not apply to Members with `is_breakglass` set to `true`.   
  --allowed-mfa-methods: list # An array of allowed MFA authentication methods. This list is enforced when `mfa_methods` is set to `RESTRICTED`.   The list's accepted values are: `sms_otp` and `totp`.   
  --oauth-tenant-jit-provisioning: string # The authentication setting that controls how a new Member can JIT provision into an organization by tenant. The accepted values are:     `RESTRICTED` – only new Members with tenants in `allowed_oauth_tenants` can JIT provision via tenant.     `NOT_ALLOWED` – the default setting, disables JIT provisioning by OAuth Tenant.   
  --allowed-oauth-tenants: record # A map of allowed OAuth tenants. If this field is not passed in, the Organization will not allow JIT provisioning by OAuth Tenant. Allowed keys are "slack", "hubspot", and "github".
  --first-party-connected-apps-allowed-type: string@first-party-connected-apps-allowed-type-completer
  --allowed-first-party-connected-apps: list # An array of first party Connected App IDs that are allowed for the Organization. Only used when the Organization's `first_party_connected_apps_allowed_type` is `RESTRICTED`.
  --third-party-connected-apps-allowed-type: string@third-party-connected-apps-allowed-type-completer
  --allowed-third-party-connected-apps: list # An array of third party Connected App IDs that are allowed for the Organization. Only used when the Organization's `third_party_connected_apps_allowed_type` is `RESTRICTED`.
  --telemetry-id: string # If the `telemetry_id` is passed, as part of this request, Stytch will call the [Fingerprint Lookup API](https://stytch.com/docs/fraud/api/fingerprint-lookup) and store the associated fingerprints and IPGEO information for the Member. Your workspace must be enabled for Device Fingerprinting to use this feature.
]: any -> record<request_id: string, member_id: string, session_token: string, session_jwt: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, member_authenticated: bool, intermediate_session_token: string, status_code: int, member_session: record<member_session_id: string, member_id: string, started_at: string, last_accessed_at: string, expires_at: string, authentication_factors: list<record>, organization_id: string, roles: list<string>, organization_slug: string, custom_claims: record>, mfa_required: record<member_options: record<mfa_phone_number: string, totp_registration_id: string>, secondary_auth_initiated: string>, primary_required: record<allowed_auth_methods: list<string>>, member_device: record<visitor_id: string, visitor_id_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_address: string, ip_address_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_geo_city: string, ip_geo_region: string, ip_geo_country: string, ip_geo_country_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/discovery/organizations/create")
  let body = {intermediate_session_token: $intermediate_session_token, session_duration_minutes: $session_duration_minutes, session_custom_claims: $session_custom_claims, organization_name: $organization_name, organization_slug: $organization_slug, organization_external_id: $organization_external_id, organization_logo_url: $organization_logo_url, trusted_metadata: $trusted_metadata, sso_jit_provisioning: $sso_jit_provisioning, email_allowed_domains: $email_allowed_domains, email_jit_provisioning: $email_jit_provisioning, email_invites: $email_invites, auth_methods: $auth_methods, allowed_auth_methods: $allowed_auth_methods, mfa_policy: $mfa_policy, rbac_email_implicit_role_assignments: $rbac_email_implicit_role_assignments, mfa_methods: $mfa_methods, allowed_mfa_methods: $allowed_mfa_methods, oauth_tenant_jit_provisioning: $oauth_tenant_jit_provisioning, allowed_oauth_tenants: $allowed_oauth_tenants, first_party_connected_apps_allowed_type: $first_party_connected_apps_allowed_type, allowed_first_party_connected_apps: $allowed_first_party_connected_apps, third_party_connected_apps_allowed_type: $third_party_connected_apps_allowed_type, allowed_third_party_connected_apps: $allowed_third_party_connected_apps, telemetry_id: $telemetry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List
#
# POST /v1/b2b/discovery/organizations
# operationId: api_discovery_v1_discovery_organizations_List
export def "b2b-discovery-organizations List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --intermediate-session-token: string # The Intermediate Session Token. This token does not necessarily belong to a specific instance of a Member, but represents a bag of factors that may be converted to a member session. The token can be used with the [OTP SMS Authenticate endpoint](https://stytch.com/docs/b2b/api/authenticate-otp-sms), [TOTP Authenticate endpoint](https://stytch.com/docs/b2b/api/authenticate-totp), or [Recovery Codes Recover endpoint](https://stytch.com/docs/b2b/api/recovery-codes-recover) to complete an MFA flow and log in to the Organization. The token has a default expiry of 10 minutes. It can also be used with the [Exchange Intermediate Session endpoint](https://stytch.com/docs/b2b/api/exchange-intermediate-session) to join a specific Organization that allows the factors represented by the intermediate session token; or the [Create Organization via Discovery endpoint](https://stytch.com/docs/b2b/api/create-organization-via-discovery) to create a new Organization and Member. Intermediate Session Tokens have a default expiry of 10 minutes.
  --session-token: string # A secret token for a given Stytch Session.
  --session-jwt: string # The JSON Web Token (JWT) for a given Stytch Session.
]: any -> record<request_id: string, email_address: string, discovered_organizations: table<member_authenticated: bool, organization: record, membership: record, primary_required: record, mfa_required: record>, status_code: int, organization_id_hint: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/discovery/organizations")
  let body = {intermediate_session_token: $intermediate_session_token, session_token: $session_token, session_jwt: $session_jwt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lookup
#
# POST /v1/fingerprint/lookup
# operationId: api_fraud_v1_fraud_fingerprint_Lookup
# --external_metadata shape: {external_id?: string, organization_id?: string, user_action?: string}
export def "fingerprint-lookup Lookup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  telemetry_id: string # The telemetry ID associated with the fingerprint getting looked up.
  --external-metadata: record # shape: {external_id?: string, organization_id?: string, user_action?: string}
]: any -> record<request_id: string, telemetry_id: string, fingerprints: record<network_fingerprint: string, hardware_fingerprint: string, browser_fingerprint: string, visitor_fingerprint: string, visitor_id: string, browser_id: string>, verdict: record<action: string, reasons: list<string>, detected_device_type: string, is_authentic_device: bool, verdict_reason_overrides: list<record>, rule_match_type: string, rule_match_identifier: string>, external_metadata: record<external_id: string, organization_id: string, user_action: string>, created_at: string, expires_at: string, status_code: int, properties: record<network_properties: record<ip_address: string, asn: record, ip_geolocation: record, is_proxy: bool, is_vpn: bool>, browser_properties: record<user_agent: string>>, raw_signals: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://telemetry.stytch.com")
  let full_url = (build-url $base "/v1/fingerprint/lookup")
  let body = {telemetry_id: $telemetry_id, external_metadata: $external_metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Set
#
# POST /v1/rules/set
# operationId: api_fraud_v1_fraud_rules_Set
export def "rules-set Set" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  action: string@action-completer
  --visitor-id: string # The visitor ID we want to set a rule for. Only one identifier can be specified in the request.
  --browser-id: string # The browser ID we want to set a rule for. Only one identifier can be specified in the request.
  --visitor-fingerprint: string # The visitor fingerprint we want to set a rule for. Only one identifier can be specified in the request.
  --browser-fingerprint: string # The browser fingerprint we want to set a rule for. Only one identifier can be specified in the request.
  --hardware-fingerprint: string # The hardware fingerprint we want to set a rule for. Only one identifier can be specified in the request.
  --network-fingerprint: string # The network fingerprint we want to set a rule for. Only one identifier can be specified in the request.
  --expires-in-minutes: int # The number of minutes until this rule expires. If no `expires_in_minutes` is specified, then the rule is kept permanently. (format: int32)
  --description: string # An optional description for the rule.
  --cidr-block: string # The CIDR block we want to set a rule for. You may pass either an IP address or a CIDR block. The CIDR block prefix must be between 16 and 32, inclusive. If an end user's IP address is within this CIDR block, this rule will be applied. Only one identifier can be specified in the request.
  --country-code: string # The country code we want to set a rule for. The country code must be a valid ISO 3166-1 alpha-2 code. You may not set `ALLOW` rules for country codes. Only one identifier can be specified in the request.
  --asn: string # The ASN we want to set a rule for. The ASN must be the string representation of an integer between 0 and 4294967295, inclusive. Only one identifier can be specified in the request.
]: any -> record<request_id: string, action: string, status_code: int, visitor_id: string, browser_id: string, visitor_fingerprint: string, browser_fingerprint: string, hardware_fingerprint: string, network_fingerprint: string, expires_at: string, cidr_block: string, country_code: string, asn: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://telemetry.stytch.com")
  let full_url = (build-url $base "/v1/rules/set")
  let body = {action: $action, visitor_id: $visitor_id, browser_id: $browser_id, visitor_fingerprint: $visitor_fingerprint, browser_fingerprint: $browser_fingerprint, hardware_fingerprint: $hardware_fingerprint, network_fingerprint: $network_fingerprint, expires_in_minutes: $expires_in_minutes, description: $description, cidr_block: $cidr_block, country_code: $country_code, asn: $asn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List
#
# POST /v1/rules/list
# operationId: api_fraud_v1_fraud_rules_List
export def "rules-list List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # The `cursor` field allows you to paginate through your results. Each result array is limited to 100 results. If your query returns more than 100 results, you will need to paginate the responses using the `cursor`. If you receive a response that includes a non-null `next_cursor`, repeat the request with the `next_cursor` value set to the `cursor` field to retrieve the next page of results. Continue to make requests until the `next_cursor` in the response is null.
  --limit: int # The number of results to return per page. The default limit is 10. A maximum of 100 results can be returned by a single get request. If the total size of your result set is greater than one page size, you must paginate the response. See the `cursor` field. (format: int32)
]: any -> record<request_id: string, next_cursor: string, rules: table<rule_type: string, action: string, created_at: string, visitor_id: string, browser_id: string, visitor_fingerprint: string, browser_fingerprint: string, hardware_fingerprint: string, network_fingerprint: string, cidr_block: string, country_code: string, asn: string, description: string, expires_at: string, last_updated_at: string>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://telemetry.stytch.com")
  let full_url = (build-url $base "/v1/rules/list")
  let body = {cursor: $cursor, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Override
#
# POST /v1/verdict_reasons/override
# operationId: api_fraud_v1_fraud_verdict_reasons_Override
export def "verdict-reasons-override Override" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  verdict_reason: string # The verdict reason that you wish to override. For a list of possible reasons to override, see [Warning Flags (Verdict Reasons)](https://stytch.com/docs/docs/fraud/guides/device-fingerprinting/reference/warning-flags-verdict-reasons). You may not override the `RULE_MATCH` reason.
  override_action: string@override-action-completer
  --override-description: string # An optional description for the verdict reason override.
]: any -> record<request_id: string, verdict_reason_action: record<verdict_reason: string, default_action: string, override_action: string, override_created_at: string, override_description: string>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://telemetry.stytch.com")
  let full_url = (build-url $base "/v1/verdict_reasons/override")
  let body = {verdict_reason: $verdict_reason, override_action: $override_action, override_description: $override_description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List
#
# POST /v1/verdict_reasons/list
# operationId: api_fraud_v1_fraud_verdict_reasons_List
export def "verdict-reasons-list List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --overrides-only: oneof<nothing, bool> # Whether to return only verdict reasons that have overrides set. Defaults to false.
]: any -> record<request_id: string, verdict_reason_actions: table<verdict_reason: string, default_action: string, override_action: string, override_created_at: string, override_description: string>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://telemetry.stytch.com")
  let full_url = (build-url $base "/v1/verdict_reasons/list")
  let body = {overrides_only: $overrides_only} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Risk
#
# POST /v1/email/risk
# operationId: api_fraud_v1_fraud_email_Risk
export def "email-risk Risk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email_address: string # The email address to check.
]: any -> record<request_id: string, address_information: record<has_known_bounces: bool, has_valid_syntax: bool, is_suspected_role_address: bool, normalized_email: string, tumbling_character_count: int>, domain_information: record<has_mx_or_a_record: bool, is_disposable_domain: bool>, action: string, risk_score: int, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://telemetry.stytch.com")
  let full_url = (build-url $base "/v1/email/risk")
  let body = {email_address: $email_address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authorizestart
#
# POST /v1/idp/oauth/authorize/start
# operationId: api_idp_v1_idp_oauth_AuthorizeStart
export def "idp-oauth-authorize-start AuthorizeStart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  client_id: string # The ID of the Connected App client.
  redirect_uri: string # The callback URI used to redirect the user after authentication. This is the same URI provided at the start of the OAuth flow.  This field is required when using the `authorization_code` grant.
  response_type: string # The OAuth 2.0 response type. For authorization code flows this value is `code`.
  scopes: list # An array of scopes requested by the client.
  --user-id: string # The unique ID of a specific User. You may use an `external_id` here if one is set for the user.
  --session-token: string # The `session_token` associated with a User's existing Session.
  --session-jwt: string # The `session_jwt` associated with a User's existing Session.
  --prompt: string # Space separated list that specifies how the Authorization Server should prompt the user for reauthentication and consent. Only `consent` is supported today.
]: any -> record<request_id: string, user_id: string, user: record<user_id: string, emails: list<record>, status: string, phone_numbers: list<record>, webauthn_registrations: list<record>, providers: list<record>, totps: list<record>, crypto_wallets: list<record>, biometric_registrations: list<record>, is_locked: bool, roles: list<string>, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, client: record<client_id: string, client_name: string, client_description: string, client_type: string, logo_url: string>, consent_required: bool, scope_results: table<scope: string, description: string, is_grantable: bool>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/idp/oauth/authorize/start")
  let body = {client_id: $client_id, redirect_uri: $redirect_uri, response_type: $response_type, scopes: $scopes, user_id: $user_id, session_token: $session_token, session_jwt: $session_jwt, prompt: $prompt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authorize
#
# POST /v1/idp/oauth/authorize
# operationId: api_idp_v1_idp_oauth_Authorize
export def "idp-oauth-authorize Authorize" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --consent-granted: oneof<nothing, bool> # Indicates whether the user granted the requested scopes.
  scopes: list # An array of scopes requested by the client.
  client_id: string # The ID of the Connected App client.
  redirect_uri: string # The callback URI used to redirect the user after authentication. This is the same URI provided at the start of the OAuth flow.  This field is required when using the `authorization_code` grant.
  response_type: string # The OAuth 2.0 response type. For authorization code flows this value is `code`.
  --user-id: string # The unique ID of a specific User. You may use an `external_id` here if one is set for the user.
  --session-token: string # The `session_token` associated with a User's existing Session.
  --session-jwt: string # The `session_jwt` associated with a User's existing Session.
  --prompt: string # Space separated list that specifies how the Authorization Server should prompt the user for reauthentication and consent. Only `consent` is supported today.
  --state: string # An opaque value used to maintain state between the request and callback.
  --nonce: string # A string used to associate a client session with an ID token to mitigate replay attacks.
  --code-challenge: string # A base64url encoded challenge derived from the code verifier for PKCE flows.
  --resources: list
]: any -> record<request_id: string, redirect_uri: string, status_code: int, authorization_code: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/idp/oauth/authorize")
  let body = {consent_granted: $consent_granted, scopes: $scopes, client_id: $client_id, redirect_uri: $redirect_uri, response_type: $response_type, user_id: $user_id, session_token: $session_token, session_jwt: $session_jwt, prompt: $prompt, state: $state, nonce: $nonce, code_challenge: $code_challenge, resources: $resources} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authenticate
#
# POST /v1/impersonation/authenticate
# operationId: api_impersonation_v1_Authenticate
export def "impersonation-authenticate Authenticate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  impersonation_token: string # The User Impersonation token to authenticate. Expires in 5 minutes by default.
]: any -> record<request_id: string, user_id: string, user: record<user_id: string, emails: list<record>, status: string, phone_numbers: list<record>, webauthn_registrations: list<record>, providers: list<record>, totps: list<record>, crypto_wallets: list<record>, biometric_registrations: list<record>, is_locked: bool, roles: list<string>, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, session_token: string, session_jwt: string, status_code: int, session: record<session_id: string, user_id: string, authentication_factors: list<record>, roles: list<string>, started_at: string, last_accessed_at: string, expires_at: string, attributes: record<ip_address: string, user_agent: string>, custom_claims: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/impersonation/authenticate")
  let body = {impersonation_token: $impersonation_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get
#
# GET /v1/m2m/clients/{client_id}
# operationId: api_m2m_v1_m2m_clients_Get
export def "m2m-clients Get" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<request_id: string, m2m_client: record<client_id: string, client_name: string, client_description: string, status: string, scopes: list<string>, client_secret_last_four: string, trusted_metadata: record, next_client_secret_last_four: string>, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/m2m/clients/($client_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update
#
# PUT /v1/m2m/clients/{client_id}
# operationId: api_m2m_v1_m2m_clients_Update
export def "m2m-clients Update" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --client-name: string # A human-readable name for the client.
  --client-description: string # A human-readable description for the client.
  --status: string@status-completer
  --scopes: list # An array of scopes assigned to the client.
  --trusted-metadata: record # The `trusted_metadata` field contains an arbitrary JSON object of application-specific data. See the [Metadata](https://stytch.com/docs/api/metadata) reference for complete field behavior details.
]: any -> record<request_id: string, m2m_client: record<client_id: string, client_name: string, client_description: string, status: string, scopes: list<string>, client_secret_last_four: string, trusted_metadata: record, next_client_secret_last_four: string>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/m2m/clients/($client_id)")
  let body = {client_name: $client_name, client_description: $client_description, status: $status, scopes: $scopes, trusted_metadata: $trusted_metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete
#
# DELETE /v1/m2m/clients/{client_id}
# operationId: api_m2m_v1_m2m_clients_Delete
export def "m2m-clients Delete" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<request_id: string, client_id: string, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/m2m/clients/($client_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Search
#
# POST /v1/m2m/clients/search
# operationId: api_m2m_v1_m2m_clients_Search
# --query shape: {operator: "OR"|"AND", operands: list}
export def "m2m-clients-search Search" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cursor: string # The `cursor` field allows you to paginate through your results. Each result array is limited to 1000 results. If your query returns more than 1000 results, you will need to paginate the responses using the `cursor`. If you receive a response that includes a non-null `next_cursor` in the `results_metadata` object, repeat the search call with the `next_cursor` value set to the `cursor` field to retrieve the next page of results. Continue to make search calls until the `next_cursor` in the response is null.
  --limit: int # The number of search results to return per page. The default limit is 100. A maximum of 1000 results can be returned by a single search request. If the total size of your result set is greater than one page size, you must paginate the response. See the `cursor` field. (format: int32)
  --body-query: record # shape: {operator: "OR"|"AND", operands: list}
]: any -> record<request_id: string, m2m_clients: table<client_id: string, client_name: string, client_description: string, status: string, scopes: list, client_secret_last_four: string, trusted_metadata: record, next_client_secret_last_four: string>, results_metadata: record<total: int, next_cursor: string>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/m2m/clients/search")
  let body = {cursor: $cursor, limit: $limit, query: $body_query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create
#
# POST /v1/m2m/clients
# operationId: api_m2m_v1_m2m_clients_Create
export def "m2m-clients Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  scopes: list # An array of scopes assigned to the client.
  --client-id: string # If provided, the ID of the client to create. If not provided, Stytch will generate this value for you. The `client_id` must be unique within your project.
  --client-secret: string # If provided, the stored secret of the client to create. If not provided, Stytch will generate this value for you. If provided, the `client_secret` must be at least 8 characters long and pass entropy requirements.
  --client-name: string # A human-readable name for the client.
  --client-description: string # A human-readable description for the client.
  --trusted-metadata: record # The `trusted_metadata` field contains an arbitrary JSON object of application-specific data. See the [Metadata](https://stytch.com/docs/api/metadata) reference for complete field behavior details.
]: any -> record<request_id: string, m2m_client: record<client_id: string, client_secret: string, client_name: string, client_description: string, status: string, scopes: list<string>, client_secret_last_four: string, trusted_metadata: record, next_client_secret_last_four: string>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/m2m/clients")
  let body = {scopes: $scopes, client_id: $client_id, client_secret: $client_secret, client_name: $client_name, client_description: $client_description, trusted_metadata: $trusted_metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rotatestart
#
# POST /v1/m2m/clients/{client_id}/secrets/rotate/start
# operationId: api_m2m_v1_m2m_clients_secrets_RotateStart
export def "m2m-clients-secrets-rotate-start RotateStart" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<request_id: string, m2m_client: record<client_id: string, next_client_secret: string, client_name: string, client_description: string, status: string, scopes: list<string>, client_secret_last_four: string, trusted_metadata: record, next_client_secret_last_four: string>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/m2m/clients/($client_id)/secrets/rotate/start")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rotatecancel
#
# POST /v1/m2m/clients/{client_id}/secrets/rotate/cancel
# operationId: api_m2m_v1_m2m_clients_secrets_RotateCancel
export def "m2m-clients-secrets-rotate-cancel RotateCancel" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<request_id: string, m2m_client: record<client_id: string, client_name: string, client_description: string, status: string, scopes: list<string>, client_secret_last_four: string, trusted_metadata: record, next_client_secret_last_four: string>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/m2m/clients/($client_id)/secrets/rotate/cancel")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rotate
#
# POST /v1/m2m/clients/{client_id}/secrets/rotate
# operationId: api_m2m_v1_m2m_clients_secrets_Rotate
export def "m2m-clients-secrets-rotate Rotate" [
  client_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<request_id: string, m2m_client: record<client_id: string, client_name: string, client_description: string, status: string, scopes: list<string>, client_secret_last_four: string, trusted_metadata: record, next_client_secret_last_four: string>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/m2m/clients/($client_id)/secrets/rotate")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authenticate
#
# POST /v1/magic_links/authenticate
# operationId: api_magic_v1_Authenticate
# --attributes shape: {ip_address?: string, user_agent?: string}
# --options shape: {ip_match_required: bool, user_agent_match_required: bool}
export def "magic-links-authenticate Authenticate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string # The Magic Link `token` from the `?token=` query parameter in the URL.        The redirect URL will look like `https://example.com/authenticate?stytch_token_type=magic_links&token=rM_kw42CWBhsHLF62V75jELMbvJ87njMe3tFVj7Qupu7`        In the redirect URL, the `stytch_token_type` will be `magic_link`. See [here](https://stytch.com/docs/workspace-management/redirect-urls) for more detail.
  --attributes: record # shape: {ip_address?: string, user_agent?: string}
  --options: record # shape: {ip_match_required: bool, user_agent_match_required: bool}
  --session-token: string # The `session_token` associated with a User's existing Session.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will not be created. (format: int32)
  --session-jwt: string # The `session_jwt` associated with a User's existing Session.
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To delete a key, supply a null value.    Custom claims made with reserved claims ("iss", "sub", "aud", "exp", "nbf", "iat", "jti") will be ignored. Total custom claims size cannot exceed four kilobytes.
  --code-verifier: string # A base64url encoded one time secret used to validate that the request starts and ends on the same device.
  --telemetry-id: string # If the `telemetry_id` is passed, as part of this request, Stytch will call the [Fingerprint Lookup API](https://stytch.com/docs/fraud/api/fingerprint-lookup) and store the associated fingerprints and IPGEO information for the User. Your workspace must be enabled for Device Fingerprinting to use this feature.
]: any -> record<request_id: string, user_id: string, method_id: string, session_token: string, session_jwt: string, user: record<user_id: string, emails: list<record>, status: string, phone_numbers: list<record>, webauthn_registrations: list<record>, providers: list<record>, totps: list<record>, crypto_wallets: list<record>, biometric_registrations: list<record>, is_locked: bool, roles: list<string>, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, reset_sessions: bool, status_code: int, session: record<session_id: string, user_id: string, authentication_factors: list<record>, roles: list<string>, started_at: string, last_accessed_at: string, expires_at: string, attributes: record<ip_address: string, user_agent: string>, custom_claims: record>, user_device: record<visitor_id: string, visitor_id_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_address: string, ip_address_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_geo_city: string, ip_geo_region: string, ip_geo_country: string, ip_geo_country_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/magic_links/authenticate")
  let body = {token: $body_token, attributes: $attributes, options: $options, session_token: $session_token, session_duration_minutes: $session_duration_minutes, session_jwt: $session_jwt, session_custom_claims: $session_custom_claims, code_verifier: $code_verifier, telemetry_id: $telemetry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create
#
# POST /v1/magic_links
# operationId: api_magic_v1_Create
# --attributes shape: {ip_address?: string, user_agent?: string}
export def "magic-links Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user_id: string # The unique ID of a specific User. You may use an `external_id` here if one is set for the user.
  --expiration-minutes: int # Set the expiration for the Magic Link `token` in minutes. By default, it expires in 1 hour. The minimum expiration is 5 minutes and the maximum is 7 days (10080 mins). (format: int32)
  --attributes: record # shape: {ip_address?: string, user_agent?: string}
]: any -> record<request_id: string, user_id: string, token: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/magic_links")
  let body = {user_id: $user_id, expiration_minutes: $expiration_minutes, attributes: $attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send
#
# POST /v1/magic_links/email/send
# operationId: api_magic_v1_magic_links_email_Send
# --attributes shape: {ip_address?: string, user_agent?: string}
export def "magic-links-email-send Send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # The email address of the User to send the Magic Link to.
  --login-template-id: string # Use a custom template for login emails. By default, it will use your default email template. Templates can be added in the [Stytch dashboard](https://stytch.com/dashboard/templates) using our built-in customization options or custom HTML templates with type “Magic links - Login”.
  --attributes: record # shape: {ip_address?: string, user_agent?: string}
  --login-magic-link-url: string # The URL the end user clicks from the login Email Magic Link. This should be a URL that your app receives and parses and subsequently send an API request to authenticate the Magic Link and log in the User. If this value is not passed, the default login redirect URL that you set in your Dashboard is used. If you have not set a default login redirect URL, an error is returned.
  --signup-magic-link-url: string # The URL the end user clicks from the sign-up Email Magic Link. This should be a URL that your app receives and parses and subsequently send an API request to authenticate the Magic Link and sign-up the User. If this value is not passed, the default sign-up redirect URL that you set in your Dashboard is used. If you have not set a default sign-up redirect URL, an error is returned.
  --login-expiration-minutes: int # Set the expiration for the login email magic link, in minutes. By default, it expires in 1 hour. The minimum expiration is 5 minutes and the maximum is 7 days (10080 mins). (format: int32)
  --signup-expiration-minutes: int # Set the expiration for the sign-up email magic link, in minutes. By default, it expires in 1 week. The minimum expiration is 5 minutes and the maximum is 7 days (10080 mins). (format: int32)
  --code-challenge: string # A base64url encoded SHA256 hash of a one time secret used to validate that the request starts and ends on the same device.
  --user-id: string # The unique ID of a specific User. You may use an `external_id` here if one is set for the user.
  --session-token: string # The `session_token` of the user to associate the email with.
  --session-jwt: string # The `session_jwt` of the user to associate the email with.
  --locale: string@locale-completer
  --signup-template-id: string # Use a custom template for sign-up emails. By default, it will use your default email template. Templates can be added in the [Stytch dashboard](https://stytch.com/dashboard/templates) using our built-in customization options or custom HTML templates with type “Magic links - Sign-up”.
]: any -> record<request_id: string, user_id: string, email_id: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/magic_links/email/send")
  let body = {email: $email, login_template_id: $login_template_id, attributes: $attributes, login_magic_link_url: $login_magic_link_url, signup_magic_link_url: $signup_magic_link_url, login_expiration_minutes: $login_expiration_minutes, signup_expiration_minutes: $signup_expiration_minutes, code_challenge: $code_challenge, user_id: $user_id, session_token: $session_token, session_jwt: $session_jwt, locale: $locale, signup_template_id: $signup_template_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Loginorcreate
#
# POST /v1/magic_links/email/login_or_create
# operationId: api_magic_v1_magic_links_email_LoginOrCreate
# --attributes shape: {ip_address?: string, user_agent?: string}
export def "magic-links-email-login-or-create LoginOrCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # The email address of the end user.
  --login-magic-link-url: string # The URL the end user clicks from the login Email Magic Link. This should be a URL that your app receives and parses and subsequently send an API request to authenticate the Magic Link and log in the User. If this value is not passed, the default login redirect URL that you set in your Dashboard is used. If you have not set a default login redirect URL, an error is returned.
  --signup-magic-link-url: string # The URL the end user clicks from the sign-up Email Magic Link. This should be a URL that your app receives and parses and subsequently send an API request to authenticate the Magic Link and sign-up the User. If this value is not passed, the default sign-up redirect URL that you set in your Dashboard is used. If you have not set a default sign-up redirect URL, an error is returned.
  --login-expiration-minutes: int # Set the expiration for the login email magic link, in minutes. By default, it expires in 1 hour. The minimum expiration is 5 minutes and the maximum is 7 days (10080 mins). (format: int32)
  --signup-expiration-minutes: int # Set the expiration for the sign-up email magic link, in minutes. By default, it expires in 1 week. The minimum expiration is 5 minutes and the maximum is 7 days (10080 mins). (format: int32)
  --login-template-id: string # Use a custom template for login emails. By default, it will use your default email template. Templates can be added in the [Stytch dashboard](https://stytch.com/dashboard/templates) using our built-in customization options or custom HTML templates with type “Magic links - Login”.
  --signup-template-id: string # Use a custom template for sign-up emails. By default, it will use your default email template. Templates can be added in the [Stytch dashboard](https://stytch.com/dashboard/templates) using our built-in customization options or custom HTML templates with type “Magic links - Sign-up”.
  --attributes: record # shape: {ip_address?: string, user_agent?: string}
  --create-user-as-pending: oneof<nothing, bool> # Flag for whether or not to save a user as pending vs active in Stytch. Defaults to false.         If true, users will be saved with status pending in Stytch's backend until authenticated.         If false, users will be created as active. An example usage of         a true flag would be to require users to verify their phone by entering the OTP code before creating         an account for them.
  --code-challenge: string # A base64url encoded SHA256 hash of a one time secret used to validate that the request starts and ends on the same device.
  --locale: string@locale-completer
]: any -> record<request_id: string, user_id: string, email_id: string, user_created: bool, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/magic_links/email/login_or_create")
  let body = {email: $email, login_magic_link_url: $login_magic_link_url, signup_magic_link_url: $signup_magic_link_url, login_expiration_minutes: $login_expiration_minutes, signup_expiration_minutes: $signup_expiration_minutes, login_template_id: $login_template_id, signup_template_id: $signup_template_id, attributes: $attributes, create_user_as_pending: $create_user_as_pending, code_challenge: $code_challenge, locale: $locale} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Invite
#
# POST /v1/magic_links/email/invite
# operationId: api_magic_v1_magic_links_email_Invite
# --attributes shape: {ip_address?: string, user_agent?: string}
# --name shape: {first_name?: string, middle_name?: string, last_name?: string}
export def "magic-links-email-invite Invite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # The email address of the User to send the invite Magic Link to.
  --invite-template-id: string # Use a custom template for invite emails. By default, it will use your default email template. Templates can be added in the [Stytch dashboard](https://stytch.com/dashboard/templates) using our built-in customization options or custom HTML templates with type “Magic links - Invite”.
  --attributes: record # shape: {ip_address?: string, user_agent?: string}
  --name: record # shape: {first_name?: string, middle_name?: string, last_name?: string}
  --invite-magic-link-url: string # The URL the end user clicks from the Email Magic Link. This should be a URL that your app receives and parses and subsequently sends an API request to authenticate the Magic Link and log in the User. If this value is not passed, the default invite redirect URL that you set in your Dashboard is used. If you have not set a default sign-up redirect URL, an error is returned.
  --invite-expiration-minutes: int # Set the expiration for the email magic link, in minutes. By default, it expires in 1 hour. The minimum expiration is 5 minutes and the maximum is 7 days (10080 mins). (format: int32)
  --locale: string@locale-completer
  --trusted-metadata: record # The `trusted_metadata` field contains an arbitrary JSON object of application-specific data. See the [Metadata](https://stytch.com/docs/api/metadata) reference for complete field behavior details.
  --untrusted-metadata: record # The `untrusted_metadata` field contains an arbitrary JSON object of application-specific data. Untrusted metadata can be edited by end users directly via the SDK, and **cannot be used to store critical information.** See the [Metadata](https://stytch.com/docs/api/metadata) reference for complete field behavior details.
]: any -> record<request_id: string, user_id: string, email_id: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/magic_links/email/invite")
  let body = {email: $email, invite_template_id: $invite_template_id, attributes: $attributes, name: $name, invite_magic_link_url: $invite_magic_link_url, invite_expiration_minutes: $invite_expiration_minutes, locale: $locale, trusted_metadata: $trusted_metadata, untrusted_metadata: $untrusted_metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revokeinvite
#
# POST /v1/magic_links/email/revoke_invite
# operationId: api_magic_v1_magic_links_email_RevokeInvite
export def "magic-links-email-revoke-invite RevokeInvite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # The email of the user.
]: any -> record<request_id: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/magic_links/email/revoke_invite")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authenticate
#
# POST /v1/b2b/magic_links/authenticate
# operationId: api_b2b_magic_v1_Authenticate
export def "b2b-magic-links-authenticate Authenticate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  magic_links_token: string # The Email Magic Link token to authenticate.
  --pkce-code-verifier: string # A base64url encoded one time secret used to validate that the request starts and ends on the same device.
  --session-token: string # Reuse an existing session instead of creating a new one. If you provide a `session_token`, Stytch will update the session.       If the `session_token` and `magic_links_token` belong to different Members, the `session_token` will be ignored. This endpoint will error if       both `session_token` and `session_jwt` are provided.
  --session-jwt: string # Reuse an existing session instead of creating a new one. If you provide a `session_jwt`, Stytch will update the session. If the `session_jwt`       and `magic_links_token` belong to different Members, the `session_jwt` will be ignored. This endpoint will error if both `session_token` and `session_jwt`       are provided.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will be created with a 60 minute duration. If you don't want   to use the Stytch session product, you can ignore the session fields in the response. (format: int32)
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in   `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To   delete a key, supply a null value. Custom claims made with reserved claims (`iss`, `sub`, `aud`, `exp`, `nbf`, `iat`, `jti`) will be ignored.   Total custom claims size cannot exceed four kilobytes.
  --locale: string@locale-completer
  --intermediate-session-token: string # Adds this primary authentication factor to the intermediate session token. If the resulting set of factors satisfies the organization's primary authentication requirements and MFA requirements, the intermediate session token will be consumed and converted to a member session. If not, the same intermediate session token will be returned.
  --telemetry-id: string # If the `telemetry_id` is passed, as part of this request, Stytch will call the [Fingerprint Lookup API](https://stytch.com/docs/fraud/api/fingerprint-lookup) and store the associated fingerprints and IPGEO information for the Member. Your workspace must be enabled for Device Fingerprinting to use this feature.
]: any -> record<request_id: string, member_id: string, method_id: string, reset_sessions: bool, organization_id: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, session_token: string, session_jwt: string, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, intermediate_session_token: string, member_authenticated: bool, status_code: int, member_session: record<member_session_id: string, member_id: string, started_at: string, last_accessed_at: string, expires_at: string, authentication_factors: list<record>, organization_id: string, roles: list<string>, organization_slug: string, custom_claims: record>, mfa_required: record<member_options: record<mfa_phone_number: string, totp_registration_id: string>, secondary_auth_initiated: string>, primary_required: record<allowed_auth_methods: list<string>>, member_device: record<visitor_id: string, visitor_id_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_address: string, ip_address_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_geo_city: string, ip_geo_region: string, ip_geo_country: string, ip_geo_country_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/magic_links/authenticate")
  let body = {magic_links_token: $magic_links_token, pkce_code_verifier: $pkce_code_verifier, session_token: $session_token, session_jwt: $session_jwt, session_duration_minutes: $session_duration_minutes, session_custom_claims: $session_custom_claims, locale: $locale, intermediate_session_token: $intermediate_session_token, telemetry_id: $telemetry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Loginorsignup
#
# POST /v1/b2b/magic_links/email/login_or_signup
# operationId: api_b2b_magic_v1_b2b_magic_links_email_LoginOrSignup
export def "b2b-magic-links-email-login-or-signup LoginOrSignup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organization_id: string # Globally unique UUID that identifies a specific Organization. The `organization_id` is critical to perform operations on an Organization, so be sure to preserve this value. You may also use the organization_slug or organization_external_id here as a convenience.
  email_address: string # The email address of the Member.
  --login-redirect-url: string # The URL that the Member clicks from the login Email Magic Link. This URL should be an endpoint in the backend server that   verifies the request by querying Stytch's authenticate endpoint and finishes the login. If this value is not passed, the default login   redirect URL that you set in your Dashboard is used. If you have not set a default login redirect URL, an error is returned.
  --signup-redirect-url: string # The URL the Member clicks from the signup Email Magic Link. This URL should be an endpoint in the backend server that verifies   the request by querying Stytch's authenticate endpoint and finishes the login. If this value is not passed, the default sign-up redirect URL   that you set in your Dashboard is used. If you have not set a default sign-up redirect URL, an error is returned.
  --pkce-code-challenge: string # A base64url encoded SHA256 hash of a one time secret used to validate that the request starts and ends on the same device.
  --login-template-id: string # Use a custom template for login emails. By default, it will use your default email template. Templates can be added in the [Stytch dashboard](https://stytch.com/dashboard/templates) using our built-in customization options or custom HTML templates with type “Magic Links - Login”.
  --signup-template-id: string # Use a custom template for signup emails. By default, it will use your default email template. The template must be from Stytch's built-in customizations or a custom HTML email for “Magic Links - Signup”.
  --locale: string@locale-completer
  --login-expiration-minutes: int # The expiration time, in minutes, for a login Email Magic Link. If not authenticated within this time frame, the email will need to be resent. Defaults to 60 (1 hour) with a minimum of 5 and a maximum of 10080 (1 week). (format: int32)
  --signup-expiration-minutes: int # The expiration time, in minutes, for a signup Email Magic Link. If not authenticated within this time frame, the email will need to be resent. Defaults to 60 (1 hour) with a minimum of 5 and a maximum of 10080 (1 week). (format: int32)
]: any -> record<request_id: string, member_id: string, member_created: bool, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/magic_links/email/login_or_signup")
  let body = {organization_id: $organization_id, email_address: $email_address, login_redirect_url: $login_redirect_url, signup_redirect_url: $signup_redirect_url, pkce_code_challenge: $pkce_code_challenge, login_template_id: $login_template_id, signup_template_id: $signup_template_id, locale: $locale, login_expiration_minutes: $login_expiration_minutes, signup_expiration_minutes: $signup_expiration_minutes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Invite
#
# POST /v1/b2b/magic_links/email/invite
# operationId: api_b2b_magic_v1_b2b_magic_links_email_Invite
export def "b2b-magic-links-email-invite Invite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
  organization_id: string # Globally unique UUID that identifies a specific Organization. The `organization_id` is critical to perform operations on an Organization, so be sure to preserve this value. You may also use the organization_slug or organization_external_id here as a convenience.
  email_address: string # The email address of the Member.
  --invite-redirect-url: string # The URL that the Member clicks from the invite Email Magic Link. This URL should be an endpoint in the backend server that verifies   the request by querying Stytch's authenticate endpoint and finishes the invite flow. If this value is not passed, the default `invite_redirect_url`   that you set in your Dashboard is used. If you have not set a default `invite_redirect_url`, an error is returned.
  --invited-by-member-id: string # The `member_id` of the Member who sends the invite.
  --name: string # The name of the Member.
  --trusted-metadata: record # An arbitrary JSON object for storing application-specific data or identity-provider-specific data.
  --untrusted-metadata: record # An arbitrary JSON object of application-specific data. These fields can be edited directly by the   frontend SDK, and should not be used to store critical information. See the [Metadata resource](https://stytch.com/docs/b2b/api/metadata)   for complete field behavior details.
  --invite-template-id: string # Use a custom template for invite emails. By default, it will use your default email template. Templates can be added in the [Stytch dashboard](https://stytch.com/dashboard/templates) using our built-in customization options or custom HTML templates with type “Magic Links - Invite”.
  --locale: string@locale-completer
  --roles: list # Roles to explicitly assign to this Member. See the [RBAC guide](https://stytch.com/docs/b2b/guides/rbac/role-assignment)    for more information about role assignment.
  --invite-expiration-minutes: int # The expiration time, in minutes, for an invite email. If not accepted within this time frame, the invite will need to be resent. Defaults to 10080 (1 week) with a minimum of 5 and a maximum of 10080. (format: int32)
]: any -> record<request_id: string, member_id: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/magic_links/email/invite")
  let body = {organization_id: $organization_id, email_address: $email_address, invite_redirect_url: $invite_redirect_url, invited_by_member_id: $invited_by_member_id, name: $name, trusted_metadata: $trusted_metadata, untrusted_metadata: $untrusted_metadata, invite_template_id: $invite_template_id, locale: $locale, roles: $roles, invite_expiration_minutes: $invite_expiration_minutes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send
#
# POST /v1/b2b/magic_links/email/discovery/send
# operationId: api_b2b_magic_v1_b2b_magic_links_email_discovery_Send
export def "b2b-magic-links-email-discovery-send Send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email_address: string # The email address of the Member.
  --discovery-redirect-url: string # The URL that the end user clicks from the discovery Magic Link. This URL should be an endpoint in the backend server that   verifies the request by querying Stytch's discovery authenticate endpoint and continues the flow. If this value is not passed, the default   discovery redirect URL that you set in your Dashboard is used. If you have not set a default discovery redirect URL, an error is returned.
  --pkce-code-challenge: string # A base64url encoded SHA256 hash of a one time secret used to validate that the request starts and ends on the same device.
  --login-template-id: string # Use a custom template for discovery emails. By default, it will use your default email template. Templates can be added in the [Stytch dashboard](https://stytch.com/dashboard/templates) using our built-in customization options or custom HTML templates with type “Magic Links - Login”.
  --locale: string@locale-completer
  --discovery-expiration-minutes: int # The expiration time, in minutes, for an discovery magic link email. If not accepted within this time frame, the email will need to be resent. Defaults to 60 (1 hour) with a minimum of 5 and a maximum of 10080 (1 week). (format: int32)
]: any -> record<request_id: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/magic_links/email/discovery/send")
  let body = {email_address: $email_address, discovery_redirect_url: $discovery_redirect_url, pkce_code_challenge: $pkce_code_challenge, login_template_id: $login_template_id, locale: $locale, discovery_expiration_minutes: $discovery_expiration_minutes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authenticate
#
# POST /v1/b2b/magic_links/discovery/authenticate
# operationId: api_b2b_magic_v1_b2b_magic_links_discovery_Authenticate
export def "b2b-magic-links-discovery-authenticate Authenticate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  discovery_magic_links_token: string # The Discovery Email Magic Link token to authenticate.
  --pkce-code-verifier: string # A base64url encoded one time secret used to validate that the request starts and ends on the same device.
]: any -> record<request_id: string, intermediate_session_token: string, email_address: string, discovered_organizations: table<member_authenticated: bool, organization: record, membership: record, primary_required: record, mfa_required: record>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/magic_links/discovery/authenticate")
  let body = {discovery_magic_links_token: $discovery_magic_links_token, pkce_code_verifier: $pkce_code_verifier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authenticate
#
# POST /v1/b2b/oauth/authenticate
# operationId: api_b2b_oauth_v1_Authenticate
export def "b2b-oauth-authenticate Authenticate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  oauth_token: string # The token to authenticate.
  --session-token: string # A secret token for a given Stytch Session.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will be created with a 60 minute duration. If you don't want   to use the Stytch session product, you can ignore the session fields in the response. (format: int32)
  --session-jwt: string # The JSON Web Token (JWT) for a given Stytch Session.
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in   `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To   delete a key, supply a null value. Custom claims made with reserved claims (`iss`, `sub`, `aud`, `exp`, `nbf`, `iat`, `jti`) will be ignored.   Total custom claims size cannot exceed four kilobytes.
  --pkce-code-verifier: string # A base64url encoded one time secret used to validate that the request starts and ends on the same device.
  --locale: string@locale-completer-1
  --intermediate-session-token: string # Adds this primary authentication factor to the intermediate session token. If the resulting set of factors satisfies the organization's primary authentication requirements and MFA requirements, the intermediate session token will be consumed and converted to a member session. If not, the same intermediate session token will be returned.
  --telemetry-id: string # If the `telemetry_id` is passed, as part of this request, Stytch will call the [Fingerprint Lookup API](https://stytch.com/docs/fraud/api/fingerprint-lookup) and store the associated fingerprints and IPGEO information for the Member. Your workspace must be enabled for Device Fingerprinting to use this feature.
]: any -> record<request_id: string, member_id: string, provider_subject: string, provider_type: string, session_token: string, session_jwt: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization_id: string, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, reset_sessions: bool, member_authenticated: bool, intermediate_session_token: string, status_code: int, member_session: record<member_session_id: string, member_id: string, started_at: string, last_accessed_at: string, expires_at: string, authentication_factors: list<record>, organization_id: string, roles: list<string>, organization_slug: string, custom_claims: record>, provider_values: record<scopes: list<string>, access_token: string, refresh_token: string, expires_at: string, id_token: string>, mfa_required: record<member_options: record<mfa_phone_number: string, totp_registration_id: string>, secondary_auth_initiated: string>, primary_required: record<allowed_auth_methods: list<string>>, member_device: record<visitor_id: string, visitor_id_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_address: string, ip_address_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_geo_city: string, ip_geo_region: string, ip_geo_country: string, ip_geo_country_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/oauth/authenticate")
  let body = {oauth_token: $oauth_token, session_token: $session_token, session_duration_minutes: $session_duration_minutes, session_jwt: $session_jwt, session_custom_claims: $session_custom_claims, pkce_code_verifier: $pkce_code_verifier, locale: $locale, intermediate_session_token: $intermediate_session_token, telemetry_id: $telemetry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authenticate
#
# POST /v1/b2b/oauth/discovery/authenticate
# operationId: api_b2b_oauth_v1_b2b_oauth_discovery_Authenticate
export def "b2b-oauth-discovery-authenticate Authenticate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  discovery_oauth_token: string # The Discovery OAuth token to authenticate.
  --session-token: string
  --session-duration-minutes: int # format: int32
  --session-jwt: string
  --session-custom-claims: record
  --pkce-code-verifier: string # A base64url encoded one time secret used to validate that the request starts and ends on the same device.
]: any -> record<request_id: string, intermediate_session_token: string, email_address: string, discovered_organizations: table<member_authenticated: bool, organization: record, membership: record, primary_required: record, mfa_required: record>, provider_type: string, provider_tenant_id: string, provider_tenant_ids: list<string>, full_name: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/oauth/discovery/authenticate")
  let body = {discovery_oauth_token: $discovery_oauth_token, session_token: $session_token, session_duration_minutes: $session_duration_minutes, session_jwt: $session_jwt, session_custom_claims: $session_custom_claims, pkce_code_verifier: $pkce_code_verifier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send
#
# POST /v1/b2b/otps/sms/send
# operationId: api_b2b_otp_v1_b2b_otp_sms_Send
export def "b2b-otps-sms-send Send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organization_id: string # Globally unique UUID that identifies a specific Organization. The `organization_id` is critical to perform operations on an Organization, so be sure to preserve this value. You may also use the organization_slug or organization_external_id here as a convenience.
  member_id: string # Globally unique UUID that identifies a specific Member. The `member_id` is critical to perform operations on a Member, so be sure to preserve this value. You may use an external_id here if one is set for the member.
  --mfa-phone-number: string # The phone number to send the OTP to. If the Member already has a phone number, this argument is not needed.
  --locale: string@locale-completer
  --intermediate-session-token: string # The Intermediate Session Token. This token does not necessarily belong to a specific instance of a Member, but represents a bag of factors that may be converted to a member session. The token can be used with the [OTP SMS Authenticate endpoint](https://stytch.com/docs/b2b/api/authenticate-otp-sms), [TOTP Authenticate endpoint](https://stytch.com/docs/b2b/api/authenticate-totp), or [Recovery Codes Recover endpoint](https://stytch.com/docs/b2b/api/recovery-codes-recover) to complete an MFA flow and log in to the Organization. The token has a default expiry of 10 minutes. It can also be used with the [Exchange Intermediate Session endpoint](https://stytch.com/docs/b2b/api/exchange-intermediate-session) to join a specific Organization that allows the factors represented by the intermediate session token; or the [Create Organization via Discovery endpoint](https://stytch.com/docs/b2b/api/create-organization-via-discovery) to create a new Organization and Member. Intermediate Session Tokens have a default expiry of 10 minutes.
  --session-token: string # A secret token for a given Stytch Session.
  --session-jwt: string # The JSON Web Token (JWT) for a given Stytch Session.
]: any -> record<request_id: string, member_id: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/otps/sms/send")
  let body = {organization_id: $organization_id, member_id: $member_id, mfa_phone_number: $mfa_phone_number, locale: $locale, intermediate_session_token: $intermediate_session_token, session_token: $session_token, session_jwt: $session_jwt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authenticate
#
# POST /v1/b2b/otps/sms/authenticate
# operationId: api_b2b_otp_v1_b2b_otp_sms_Authenticate
export def "b2b-otps-sms-authenticate Authenticate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organization_id: string # Globally unique UUID that identifies a specific Organization. The `organization_id` is critical to perform operations on an Organization, so be sure to preserve this value. You may also use the organization_slug or organization_external_id here as a convenience.
  member_id: string # Globally unique UUID that identifies a specific Member. The `member_id` is critical to perform operations on a Member, so be sure to preserve this value. You may use an external_id here if one is set for the member.
  code: string # The code to authenticate.
  --intermediate-session-token: string # The Intermediate Session Token. This token does not necessarily belong to a specific instance of a Member, but represents a bag of factors that may be converted to a member session. The token can be used with the [OTP SMS Authenticate endpoint](https://stytch.com/docs/b2b/api/authenticate-otp-sms), [TOTP Authenticate endpoint](https://stytch.com/docs/b2b/api/authenticate-totp), or [Recovery Codes Recover endpoint](https://stytch.com/docs/b2b/api/recovery-codes-recover) to complete an MFA flow and log in to the Organization. The token has a default expiry of 10 minutes. It can also be used with the [Exchange Intermediate Session endpoint](https://stytch.com/docs/b2b/api/exchange-intermediate-session) to join a specific Organization that allows the factors represented by the intermediate session token; or the [Create Organization via Discovery endpoint](https://stytch.com/docs/b2b/api/create-organization-via-discovery) to create a new Organization and Member. Intermediate Session Tokens have a default expiry of 10 minutes.
  --session-token: string # A secret token for a given Stytch Session.
  --session-jwt: string # The JSON Web Token (JWT) for a given Stytch Session.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will be created with a 60 minute duration. If you don't want   to use the Stytch session product, you can ignore the session fields in the response. (format: int32)
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in   `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To   delete a key, supply a null value. Custom claims made with reserved claims (`iss`, `sub`, `aud`, `exp`, `nbf`, `iat`, `jti`) will be ignored.   Total custom claims size cannot exceed four kilobytes.
  --set-mfa-enrollment: string # Optionally sets the Member’s MFA enrollment status upon a successful authentication. If the Organization’s MFA policy is `REQUIRED_FOR_ALL`, this field will be ignored. If this field is not passed in, the Member’s `mfa_enrolled` boolean will not be affected. The options are:     `enroll` – sets the Member's `mfa_enrolled` boolean to `true`. The Member will be required to complete an MFA step upon subsequent logins to the Organization.     `unenroll` –  sets the Member's `mfa_enrolled` boolean to `false`. The Member will no longer be required to complete MFA steps when logging in to the Organization.   
  --set-default-mfa: oneof<nothing, bool>
  --telemetry-id: string # If the `telemetry_id` is passed, as part of this request, Stytch will call the [Fingerprint Lookup API](https://stytch.com/docs/fraud/api/fingerprint-lookup) and store the associated fingerprints and IPGEO information for the Member. Your workspace must be enabled for Device Fingerprinting to use this feature.
]: any -> record<request_id: string, member_id: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, session_token: string, session_jwt: string, status_code: int, member_session: record<member_session_id: string, member_id: string, started_at: string, last_accessed_at: string, expires_at: string, authentication_factors: list<record>, organization_id: string, roles: list<string>, organization_slug: string, custom_claims: record>, member_device: record<visitor_id: string, visitor_id_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_address: string, ip_address_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_geo_city: string, ip_geo_region: string, ip_geo_country: string, ip_geo_country_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/otps/sms/authenticate")
  let body = {organization_id: $organization_id, member_id: $member_id, code: $code, intermediate_session_token: $intermediate_session_token, session_token: $session_token, session_jwt: $session_jwt, session_duration_minutes: $session_duration_minutes, session_custom_claims: $session_custom_claims, set_mfa_enrollment: $set_mfa_enrollment, set_default_mfa: $set_default_mfa, telemetry_id: $telemetry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Loginorsignup
#
# POST /v1/b2b/otps/email/login_or_signup
# operationId: api_b2b_otp_v1_b2b_otp_email_LoginOrSignup
export def "b2b-otps-email-login-or-signup LoginOrSignup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organization_id: string # Globally unique UUID that identifies a specific Organization. The `organization_id` is critical to perform operations on an Organization, so be sure to preserve this value. You may also use the organization_slug or organization_external_id here as a convenience.
  email_address: string # The email address of the Member.
  --login-template-id: string # Use a custom template for login emails. By default, it will use your default email template. Templates can be added in the [Stytch dashboard](https://stytch.com/dashboard/templates) using our built-in customization options or custom HTML templates with type “OTP - Login”.
  --signup-template-id: string # Use a custom template for signup emails. By default, it will use your default email template. Templates can be added in the [Stytch dashboard](https://stytch.com/dashboard/templates) using our built-in customization options or custom HTML templates with type “OTP - Signup”.
  --locale: string@locale-completer
  --login-expiration-minutes: int # The expiration time, in minutes, for a login OTP email to a Member. If not authenticated within this time frame, the OTP will need to be resent. Defaults to 10 with a minimum of 2 and a maximum of 15. (format: int32)
  --signup-expiration-minutes: int # The expiration time, in minutes, for a signup OTP email to a Member. If not authenticated within this time frame, the OTP will need to be resent. Defaults to 10 with a minimum of 2 and a maximum of 15. (format: int32)
]: any -> record<request_id: string, member_id: string, member_created: bool, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/otps/email/login_or_signup")
  let body = {organization_id: $organization_id, email_address: $email_address, login_template_id: $login_template_id, signup_template_id: $signup_template_id, locale: $locale, login_expiration_minutes: $login_expiration_minutes, signup_expiration_minutes: $signup_expiration_minutes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authenticate
#
# POST /v1/b2b/otps/email/authenticate
# operationId: api_b2b_otp_v1_b2b_otp_email_Authenticate
export def "b2b-otps-email-authenticate Authenticate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organization_id: string # Globally unique UUID that identifies a specific Organization. The `organization_id` is critical to perform operations on an Organization, so be sure to preserve this value. You may also use the organization_slug or organization_external_id here as a convenience.
  email_address: string # The email address of the Member.
  code: string # The code to authenticate.
  --session-token: string # A secret token for a given Stytch Session.
  --session-jwt: string # The JSON Web Token (JWT) for a given Stytch Session.
  --intermediate-session-token: string # The Intermediate Session Token. This token does not necessarily belong to a specific instance of a Member, but represents a bag of factors that may be converted to a member session. The token can be used with the [OTP SMS Authenticate endpoint](https://stytch.com/docs/b2b/api/authenticate-otp-sms), [TOTP Authenticate endpoint](https://stytch.com/docs/b2b/api/authenticate-totp), or [Recovery Codes Recover endpoint](https://stytch.com/docs/b2b/api/recovery-codes-recover) to complete an MFA flow and log in to the Organization. The token has a default expiry of 10 minutes. It can also be used with the [Exchange Intermediate Session endpoint](https://stytch.com/docs/b2b/api/exchange-intermediate-session) to join a specific Organization that allows the factors represented by the intermediate session token; or the [Create Organization via Discovery endpoint](https://stytch.com/docs/b2b/api/create-organization-via-discovery) to create a new Organization and Member. Intermediate Session Tokens have a default expiry of 10 minutes.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will be created with a 60 minute duration. If you don't want   to use the Stytch session product, you can ignore the session fields in the response. (format: int32)
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in   `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To   delete a key, supply a null value. Custom claims made with reserved claims (`iss`, `sub`, `aud`, `exp`, `nbf`, `iat`, `jti`) will be ignored.   Total custom claims size cannot exceed four kilobytes.
  --locale: string@locale-completer
  --telemetry-id: string # If the `telemetry_id` is passed, as part of this request, Stytch will call the [Fingerprint Lookup API](https://stytch.com/docs/fraud/api/fingerprint-lookup) and store the associated fingerprints and IPGEO information for the Member. Your workspace must be enabled for Device Fingerprinting to use this feature.
]: any -> record<request_id: string, member_id: string, method_id: string, organization_id: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, session_token: string, session_jwt: string, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, intermediate_session_token: string, member_authenticated: bool, status_code: int, member_session: record<member_session_id: string, member_id: string, started_at: string, last_accessed_at: string, expires_at: string, authentication_factors: list<record>, organization_id: string, roles: list<string>, organization_slug: string, custom_claims: record>, mfa_required: record<member_options: record<mfa_phone_number: string, totp_registration_id: string>, secondary_auth_initiated: string>, primary_required: record<allowed_auth_methods: list<string>>, member_device: record<visitor_id: string, visitor_id_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_address: string, ip_address_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_geo_city: string, ip_geo_region: string, ip_geo_country: string, ip_geo_country_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/otps/email/authenticate")
  let body = {organization_id: $organization_id, email_address: $email_address, code: $code, session_token: $session_token, session_jwt: $session_jwt, intermediate_session_token: $intermediate_session_token, session_duration_minutes: $session_duration_minutes, session_custom_claims: $session_custom_claims, locale: $locale, telemetry_id: $telemetry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send
#
# POST /v1/b2b/otps/email/discovery/send
# operationId: api_b2b_otp_v1_b2b_otp_email_discovery_Send
export def "b2b-otps-email-discovery-send Send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email_address: string # The email address to start the discovery flow for.
  --login-template-id: string # Use a custom template for login emails. By default, it will use your default email template. Templates can be added in the [Stytch dashboard](https://stytch.com/dashboard/templates) using our built-in customization options or custom HTML templates with type “OTP - Login”.
  --locale: string@locale-completer
  --discovery-expiration-minutes: int # The expiration time, in minutes, for a discovery OTP email. If not accepted within this time frame, the OTP will need to be resent. Defaults to 10 with a minimum of 2 and a maximum of 15. (format: int32)
]: any -> record<request_id: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/otps/email/discovery/send")
  let body = {email_address: $email_address, login_template_id: $login_template_id, locale: $locale, discovery_expiration_minutes: $discovery_expiration_minutes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authenticate
#
# POST /v1/b2b/otps/email/discovery/authenticate
# operationId: api_b2b_otp_v1_b2b_otp_email_discovery_Authenticate
export def "b2b-otps-email-discovery-authenticate Authenticate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email_address: string # The email address of the Member.
  code: string # The code to authenticate.
]: any -> record<request_id: string, intermediate_session_token: string, email_address: string, discovered_organizations: table<member_authenticated: bool, organization: record, membership: record, primary_required: record, mfa_required: record>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/otps/email/discovery/authenticate")
  let body = {email_address: $email_address, code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create
#
# POST /v1/passwords
# operationId: api_password_v1_Create
# --name shape: {first_name?: string, middle_name?: string, last_name?: string}
export def "passwords Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # The email address of the end user.
  password: string # The password for the user. Any UTF8 character is allowed, e.g. spaces, emojis, non-English characters, etc.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will not be created. (format: int32)
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To delete a key, supply a null value.    Custom claims made with reserved claims ("iss", "sub", "aud", "exp", "nbf", "iat", "jti") will be ignored. Total custom claims size cannot exceed four kilobytes.
  --trusted-metadata: record # The `trusted_metadata` field contains an arbitrary JSON object of application-specific data. See the [Metadata](https://stytch.com/docs/api/metadata) reference for complete field behavior details.
  --untrusted-metadata: record # The `untrusted_metadata` field contains an arbitrary JSON object of application-specific data. Untrusted metadata can be edited by end users directly via the SDK, and **cannot be used to store critical information.** See the [Metadata](https://stytch.com/docs/api/metadata) reference for complete field behavior details.
  --name: record # shape: {first_name?: string, middle_name?: string, last_name?: string}
  --telemetry-id: string # If the `telemetry_id` is passed, as part of this request, Stytch will call the [Fingerprint Lookup API](https://stytch.com/docs/fraud/api/fingerprint-lookup) and store the associated fingerprints and IPGEO information for the User. Your workspace must be enabled for Device Fingerprinting to use this feature.
]: any -> record<request_id: string, user_id: string, email_id: string, session_token: string, session_jwt: string, user: record<user_id: string, emails: list<record>, status: string, phone_numbers: list<record>, webauthn_registrations: list<record>, providers: list<record>, totps: list<record>, crypto_wallets: list<record>, biometric_registrations: list<record>, is_locked: bool, roles: list<string>, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, status_code: int, session: record<session_id: string, user_id: string, authentication_factors: list<record>, roles: list<string>, started_at: string, last_accessed_at: string, expires_at: string, attributes: record<ip_address: string, user_agent: string>, custom_claims: record>, user_device: record<visitor_id: string, visitor_id_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_address: string, ip_address_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_geo_city: string, ip_geo_region: string, ip_geo_country: string, ip_geo_country_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/passwords")
  let body = {email: $email, password: $password, session_duration_minutes: $session_duration_minutes, session_custom_claims: $session_custom_claims, trusted_metadata: $trusted_metadata, untrusted_metadata: $untrusted_metadata, name: $name, telemetry_id: $telemetry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authenticate
#
# POST /v1/passwords/authenticate
# operationId: api_password_v1_Authenticate
export def "passwords-authenticate Authenticate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # The email address of the end user.
  password: string # The password for the user. Any UTF8 character is allowed, e.g. spaces, emojis, non-English characters, etc.
  --session-token: string # The `session_token` associated with a User's existing Session.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will not be created. (format: int32)
  --session-jwt: string # The `session_jwt` associated with a User's existing Session.
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To delete a key, supply a null value.    Custom claims made with reserved claims ("iss", "sub", "aud", "exp", "nbf", "iat", "jti") will be ignored. Total custom claims size cannot exceed four kilobytes.
  --telemetry-id: string # If the `telemetry_id` is passed, as part of this request, Stytch will call the [Fingerprint Lookup API](https://stytch.com/docs/fraud/api/fingerprint-lookup) and store the associated fingerprints and IPGEO information for the User. Your workspace must be enabled for Device Fingerprinting to use this feature.
]: any -> record<request_id: string, user_id: string, session_token: string, session_jwt: string, user: record<user_id: string, emails: list<record>, status: string, phone_numbers: list<record>, webauthn_registrations: list<record>, providers: list<record>, totps: list<record>, crypto_wallets: list<record>, biometric_registrations: list<record>, is_locked: bool, roles: list<string>, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, status_code: int, session: record<session_id: string, user_id: string, authentication_factors: list<record>, roles: list<string>, started_at: string, last_accessed_at: string, expires_at: string, attributes: record<ip_address: string, user_agent: string>, custom_claims: record>, user_device: record<visitor_id: string, visitor_id_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_address: string, ip_address_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_geo_city: string, ip_geo_region: string, ip_geo_country: string, ip_geo_country_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/passwords/authenticate")
  let body = {email: $email, password: $password, session_token: $session_token, session_duration_minutes: $session_duration_minutes, session_jwt: $session_jwt, session_custom_claims: $session_custom_claims, telemetry_id: $telemetry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Strengthcheck
#
# POST /v1/passwords/strength_check
# operationId: api_password_v1_StrengthCheck
export def "passwords-strength-check StrengthCheck" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  password: string # The password for the user. Any UTF8 character is allowed, e.g. spaces, emojis, non-English characters, etc.
  --email: string # The email address of the end user.
]: any -> record<request_id: string, valid_password: bool, score: int, breached_password: bool, strength_policy: string, breach_detection_on_create: bool, status_code: int, feedback: record<warning: string, suggestions: list<string>, luds_requirements: record<has_lower_case: bool, has_upper_case: bool, has_digit: bool, has_symbol: bool, missing_complexity: int, missing_characters: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/passwords/strength_check")
  let body = {password: $password, email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Migrate
#
# POST /v1/passwords/migrate
# operationId: api_password_v1_Migrate
# --md_5_config shape: {prepend_salt: string, append_salt: string}
# --argon_2_config shape: {salt: string, iteration_amount: int, memory: int, threads: int, key_length: int}
# --sha_1_config shape: {prepend_salt: string, append_salt: string}
# --sha_512_config shape: {prepend_salt: string, append_salt: string}
# --scrypt_config shape: {salt: string, n_parameter: int, r_parameter: int, p_parameter: int, key_length: int}
# --pbkdf_2_config shape: {salt: string, iteration_amount: int, key_length: int, algorithm: string}
# --name shape: {first_name?: string, middle_name?: string, last_name?: string}
export def "passwords-migrate Migrate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # The email address of the end user.
  hash: string # The password hash. For a Scrypt or PBKDF2 hash, the hash needs to be a base64 encoded string.
  hash_type: string@hash-type-completer
  --md-5-config: record # shape: {prepend_salt: string, append_salt: string}
  --argon-2-config: record # shape: {salt: string, iteration_amount: int, memory: int, threads: int, key_length: int}
  --sha-1-config: record # shape: {prepend_salt: string, append_salt: string}
  --sha-512-config: record # shape: {prepend_salt: string, append_salt: string}
  --scrypt-config: record # shape: {salt: string, n_parameter: int, r_parameter: int, p_parameter: int, key_length: int}
  --pbkdf-2-config: record # shape: {salt: string, iteration_amount: int, key_length: int, algorithm: string}
  --trusted-metadata: record # The `trusted_metadata` field contains an arbitrary JSON object of application-specific data. See the [Metadata](https://stytch.com/docs/api/metadata) reference for complete field behavior details.
  --untrusted-metadata: record # The `untrusted_metadata` field contains an arbitrary JSON object of application-specific data. Untrusted metadata can be edited by end users directly via the SDK, and **cannot be used to store critical information.** See the [Metadata](https://stytch.com/docs/api/metadata) reference for complete field behavior details.
  --set-email-verified: oneof<nothing, bool> # Whether to set the user's email as verified. This is a dangerous field, incorrect use may lead to users getting erroneously                 deduplicated into one User object. This flag should only be set if you can attest that the user owns the email address in question.                 
  --name: record # shape: {first_name?: string, middle_name?: string, last_name?: string}
  --phone-number: string # The phone number of the user. The phone number should be in E.164 format (i.e. +1XXXXXXXXXX).
  --set-phone-number-verified: oneof<nothing, bool> # Whether to set the user's phone number as verified. This is a dangerous field, this flag should only be set if you can attest that    the user owns the phone number in question.
  --external-id: string # If a new user is created, this will set an identifier that can be used in API calls wherever a user_id is expected. This is a string consisting of alphanumeric, `.`, `_`, `-`, or `|` characters with a maximum length of 128 characters.
  --roles: list # Roles to explicitly assign to this User.    See the [RBAC guide](https://stytch.com/docs/guides/rbac/role-assignment) for more information about role assignment.
]: any -> record<request_id: string, user_id: string, email_id: string, user_created: bool, user: record<user_id: string, emails: list<record>, status: string, phone_numbers: list<record>, webauthn_registrations: list<record>, providers: list<record>, totps: list<record>, crypto_wallets: list<record>, biometric_registrations: list<record>, is_locked: bool, roles: list<string>, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/passwords/migrate")
  let body = {email: $email, hash: $hash, hash_type: $hash_type, md_5_config: $md_5_config, argon_2_config: $argon_2_config, sha_1_config: $sha_1_config, sha_512_config: $sha_512_config, scrypt_config: $scrypt_config, pbkdf_2_config: $pbkdf_2_config, trusted_metadata: $trusted_metadata, untrusted_metadata: $untrusted_metadata, set_email_verified: $set_email_verified, name: $name, phone_number: $phone_number, set_phone_number_verified: $set_phone_number_verified, external_id: $external_id, roles: $roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Resetstart
#
# POST /v1/passwords/email/reset/start
# operationId: api_password_v1_passwords_email_ResetStart
# --attributes shape: {ip_address?: string, user_agent?: string}
export def "passwords-email-reset-start ResetStart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # The email of the User that requested the password reset.
  --reset-password-redirect-url: string # The URL that the User is redirected to from the reset password magic link. This URL should display your application's reset password page.   Before rendering the reset page, extract the `token` from the query parameters. On the reset page, collect the new password and complete the flow by calling the corresponding Password Reset by Email endpoint.   If this parameter is not specified, the default Reset Password redirect URL configured in the Dashboard will be used. If you have not set a default Reset Password redirect URL, an error is returned.
  --reset-password-expiration-minutes: int # Set the expiration for the password reset, in minutes. By default, it expires in 30 minutes.   The minimum expiration is 5 minutes and the maximum is 7 days (10080 mins). (format: int32)
  --code-challenge: string # A base64url encoded SHA256 hash of a one time secret used to validate that the request starts and ends on the same device.
  --attributes: record # shape: {ip_address?: string, user_agent?: string}
  --login-redirect-url: string # The URL that Users are redirected to upon clicking the "Log in without password" button in password reset emails.        After Users are redirected to the login redirect URL, your application should retrieve the `token` value from the URL parameters and call the [Magic Link Authenticate endpoint](https://stytch.com/docs/api/authenticate-magic-link) to log the User in without requiring a password reset. If this value is not provided, your project's default login redirect URL will be used. If you have not set a default login redirect URL, an error will be returned.
  --locale: string@locale-completer
  --reset-password-template-id: string # Use a custom template for password reset emails. By default, it will use your default email template.   Templates can be added in the [Stytch dashboard](https://stytch.com/dashboard/templates) using our built-in customization options or custom HTML templates with type “Passwords - Password reset”.
]: any -> record<request_id: string, user_id: string, email_id: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/passwords/email/reset/start")
  let body = {email: $email, reset_password_redirect_url: $reset_password_redirect_url, reset_password_expiration_minutes: $reset_password_expiration_minutes, code_challenge: $code_challenge, attributes: $attributes, login_redirect_url: $login_redirect_url, locale: $locale, reset_password_template_id: $reset_password_template_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset
#
# POST /v1/passwords/email/reset
# operationId: api_password_v1_passwords_email_Reset
# --attributes shape: {ip_address?: string, user_agent?: string}
# --options shape: {ip_match_required: bool, user_agent_match_required: bool}
export def "passwords-email-reset Reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string # The Passwords `token` from the `?token=` query parameter in the URL.        In the redirect URL, the `stytch_token_type` will be `login` or `reset_password`.        See examples and read more about redirect URLs [here](https://stytch.com/docs/workspace-management/redirect-urls).
  password: string # The password for the user. Any UTF8 character is allowed, e.g. spaces, emojis, non-English characters, etc.
  --session-token: string # The `session_token` associated with a User's existing Session.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will not be created. (format: int32)
  --session-jwt: string # The `session_jwt` associated with a User's existing Session.
  --code-verifier: string # A base64url encoded one time secret used to validate that the request starts and ends on the same device.
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To delete a key, supply a null value.    Custom claims made with reserved claims ("iss", "sub", "aud", "exp", "nbf", "iat", "jti") will be ignored. Total custom claims size cannot exceed four kilobytes.
  --attributes: record # shape: {ip_address?: string, user_agent?: string}
  --options: record # shape: {ip_match_required: bool, user_agent_match_required: bool}
  --telemetry-id: string # If the `telemetry_id` is passed, as part of this request, Stytch will call the [Fingerprint Lookup API](https://stytch.com/docs/fraud/api/fingerprint-lookup) and store the associated fingerprints and IPGEO information for the User. Your workspace must be enabled for Device Fingerprinting to use this feature.
]: any -> record<request_id: string, user_id: string, session_token: string, session_jwt: string, user: record<user_id: string, emails: list<record>, status: string, phone_numbers: list<record>, webauthn_registrations: list<record>, providers: list<record>, totps: list<record>, crypto_wallets: list<record>, biometric_registrations: list<record>, is_locked: bool, roles: list<string>, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, status_code: int, session: record<session_id: string, user_id: string, authentication_factors: list<record>, roles: list<string>, started_at: string, last_accessed_at: string, expires_at: string, attributes: record<ip_address: string, user_agent: string>, custom_claims: record>, user_device: record<visitor_id: string, visitor_id_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_address: string, ip_address_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_geo_city: string, ip_geo_region: string, ip_geo_country: string, ip_geo_country_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/passwords/email/reset")
  let body = {token: $body_token, password: $password, session_token: $session_token, session_duration_minutes: $session_duration_minutes, session_jwt: $session_jwt, code_verifier: $code_verifier, session_custom_claims: $session_custom_claims, attributes: $attributes, options: $options, telemetry_id: $telemetry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset
#
# POST /v1/passwords/existing_password/reset
# operationId: api_password_v1_passwords_existing_password_Reset
export def "passwords-existing-password-reset Reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # The email address of the end user.
  existing_password: string # The user's existing password.
  new_password: string # The new password for the user.
  --session-token: string # The `session_token` associated with a User's existing Session.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will not be created. (format: int32)
  --session-jwt: string # The `session_jwt` associated with a User's existing Session.
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To delete a key, supply a null value.    Custom claims made with reserved claims ("iss", "sub", "aud", "exp", "nbf", "iat", "jti") will be ignored. Total custom claims size cannot exceed four kilobytes.
  --telemetry-id: string # If the `telemetry_id` is passed, as part of this request, Stytch will call the [Fingerprint Lookup API](https://stytch.com/docs/fraud/api/fingerprint-lookup) and store the associated fingerprints and IPGEO information for the User. Your workspace must be enabled for Device Fingerprinting to use this feature.
]: any -> record<request_id: string, user_id: string, session_token: string, session_jwt: string, user: record<user_id: string, emails: list<record>, status: string, phone_numbers: list<record>, webauthn_registrations: list<record>, providers: list<record>, totps: list<record>, crypto_wallets: list<record>, biometric_registrations: list<record>, is_locked: bool, roles: list<string>, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, status_code: int, session: record<session_id: string, user_id: string, authentication_factors: list<record>, roles: list<string>, started_at: string, last_accessed_at: string, expires_at: string, attributes: record<ip_address: string, user_agent: string>, custom_claims: record>, user_device: record<visitor_id: string, visitor_id_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_address: string, ip_address_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_geo_city: string, ip_geo_region: string, ip_geo_country: string, ip_geo_country_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/passwords/existing_password/reset")
  let body = {email: $email, existing_password: $existing_password, new_password: $new_password, session_token: $session_token, session_duration_minutes: $session_duration_minutes, session_jwt: $session_jwt, session_custom_claims: $session_custom_claims, telemetry_id: $telemetry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset
#
# POST /v1/passwords/session/reset
# operationId: api_password_v1_passwords_session_Reset
export def "passwords-session-reset Reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  password: string # The password for the user. Any UTF8 character is allowed, e.g. spaces, emojis, non-English characters, etc.
  --session-token: string # The `session_token` associated with a User's existing Session.
  --session-jwt: string # The `session_jwt` associated with a User's existing Session.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will not be created. (format: int32)
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To delete a key, supply a null value.    Custom claims made with reserved claims ("iss", "sub", "aud", "exp", "nbf", "iat", "jti") will be ignored. Total custom claims size cannot exceed four kilobytes.
  --telemetry-id: string # If the `telemetry_id` is passed, as part of this request, Stytch will call the [Fingerprint Lookup API](https://stytch.com/docs/fraud/api/fingerprint-lookup) and store the associated fingerprints and IPGEO information for the User. Your workspace must be enabled for Device Fingerprinting to use this feature.
]: any -> record<request_id: string, user_id: string, user: record<user_id: string, emails: list<record>, status: string, phone_numbers: list<record>, webauthn_registrations: list<record>, providers: list<record>, totps: list<record>, crypto_wallets: list<record>, biometric_registrations: list<record>, is_locked: bool, roles: list<string>, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, session_token: string, session_jwt: string, status_code: int, session: record<session_id: string, user_id: string, authentication_factors: list<record>, roles: list<string>, started_at: string, last_accessed_at: string, expires_at: string, attributes: record<ip_address: string, user_agent: string>, custom_claims: record>, user_device: record<visitor_id: string, visitor_id_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_address: string, ip_address_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_geo_city: string, ip_geo_region: string, ip_geo_country: string, ip_geo_country_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/passwords/session/reset")
  let body = {password: $password, session_token: $session_token, session_jwt: $session_jwt, session_duration_minutes: $session_duration_minutes, session_custom_claims: $session_custom_claims, telemetry_id: $telemetry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Strengthcheck
#
# POST /v1/b2b/passwords/strength_check
# operationId: api_b2b_password_v1_StrengthCheck
export def "b2b-passwords-strength-check StrengthCheck" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  password: string # The password to authenticate, reset, or set for the first time. Any UTF8 character is allowed, e.g. spaces, emojis, non-English characters, etc.
  --email-address: string # The email address of the Member.
]: any -> record<request_id: string, valid_password: bool, score: int, breached_password: bool, strength_policy: string, breach_detection_on_create: bool, status_code: int, luds_feedback: record<has_lower_case: bool, has_upper_case: bool, has_digit: bool, has_symbol: bool, missing_complexity: int, missing_characters: int>, zxcvbn_feedback: record<warning: string, suggestions: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/passwords/strength_check")
  let body = {password: $password, email_address: $email_address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Migrate
#
# POST /v1/b2b/passwords/migrate
# operationId: api_b2b_password_v1_Migrate
# --md_5_config shape: {prepend_salt: string, append_salt: string}
# --argon_2_config shape: {salt: string, iteration_amount: int, memory: int, threads: int, key_length: int}
# --sha_1_config shape: {prepend_salt: string, append_salt: string}
# --sha_512_config shape: {prepend_salt: string, append_salt: string}
# --scrypt_config shape: {salt: string, n_parameter: int, r_parameter: int, p_parameter: int, key_length: int}
# --pbkdf_2_config shape: {salt: string, iteration_amount: int, key_length: int, algorithm: string}
export def "b2b-passwords-migrate Migrate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email_address: string # The email address of the Member.
  hash: string # The password hash. For a Scrypt or PBKDF2 hash, the hash needs to be a base64 encoded string.
  hash_type: string@hash-type-completer
  organization_id: string # Globally unique UUID that identifies a specific Organization. The `organization_id` is critical to perform operations on an Organization, so be sure to preserve this value. You may also use the organization_slug or organization_external_id here as a convenience.
  --md-5-config: record # shape: {prepend_salt: string, append_salt: string}
  --argon-2-config: record # shape: {salt: string, iteration_amount: int, memory: int, threads: int, key_length: int}
  --sha-1-config: record # shape: {prepend_salt: string, append_salt: string}
  --sha-512-config: record # shape: {prepend_salt: string, append_salt: string}
  --scrypt-config: record # shape: {salt: string, n_parameter: int, r_parameter: int, p_parameter: int, key_length: int}
  --pbkdf-2-config: record # shape: {salt: string, iteration_amount: int, key_length: int, algorithm: string}
  --name: string # The name of the Member. Each field in the name object is optional.
  --trusted-metadata: record # An arbitrary JSON object for storing application-specific data or identity-provider-specific data.
  --untrusted-metadata: record # An arbitrary JSON object of application-specific data. These fields can be edited directly by the   frontend SDK, and should not be used to store critical information. See the [Metadata resource](https://stytch.com/docs/b2b/api/metadata)   for complete field behavior details.
  --roles: list # Roles to explicitly assign to this Member.  Will completely replace any existing explicitly assigned roles. See the  [RBAC guide](https://stytch.com/docs/b2b/guides/rbac/role-assignment) for more information about role assignment.     If a Role is removed from a Member, and the Member is also implicitly assigned this Role from an SSO connection    or an SSO group, we will by default revoke any existing sessions for the Member that contain any SSO    authentication factors with the affected connection ID. You can preserve these sessions by passing in the    `preserve_existing_sessions` parameter with a value of `true`.
  --preserve-existing-sessions: oneof<nothing, bool> # Whether to preserve existing sessions when explicit Roles that are revoked are also implicitly assigned   by SSO connection or SSO group. Defaults to `false` - that is, existing Member Sessions that contain SSO   authentication factors with the affected SSO connection IDs will be revoked.
  --mfa-phone-number: string # The Member's phone number. A Member may only have one phone number. The phone number should be in E.164 format (i.e. +1XXXXXXXXXX).
  --set-phone-number-verified: oneof<nothing, bool> # Whether to set the user's phone number as verified. This is a dangerous field. This flag should only be set if you can attest that    the user owns the phone number in question.
  --external-id: string # If a new member is created, this will set an identifier that can be used in most API calls where a `member_id` is expected. This is a string consisting of alphanumeric, `.`, `_`, `-`, or `|` characters with a maximum length of 128 characters. External IDs must be unique within an organization, but may be reused across different organizations in the same project. Note that if a member already exists, this field will be ignored.
]: any -> record<request_id: string, member_id: string, member_created: bool, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/passwords/migrate")
  let body = {email_address: $email_address, hash: $hash, hash_type: $hash_type, organization_id: $organization_id, md_5_config: $md_5_config, argon_2_config: $argon_2_config, sha_1_config: $sha_1_config, sha_512_config: $sha_512_config, scrypt_config: $scrypt_config, pbkdf_2_config: $pbkdf_2_config, name: $name, trusted_metadata: $trusted_metadata, untrusted_metadata: $untrusted_metadata, roles: $roles, preserve_existing_sessions: $preserve_existing_sessions, mfa_phone_number: $mfa_phone_number, set_phone_number_verified: $set_phone_number_verified, external_id: $external_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authenticate
#
# POST /v1/b2b/passwords/authenticate
# operationId: api_b2b_password_v1_Authenticate
export def "b2b-passwords-authenticate Authenticate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organization_id: string # Globally unique UUID that identifies a specific Organization. The `organization_id` is critical to perform operations on an Organization, so be sure to preserve this value. You may also use the organization_slug or organization_external_id here as a convenience.
  email_address: string # The email address of the Member.
  password: string # The password to authenticate, reset, or set for the first time. Any UTF8 character is allowed, e.g. spaces, emojis, non-English characters, etc.
  --session-token: string # A secret token for a given Stytch Session.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will be created with a 60 minute duration. If you don't want   to use the Stytch session product, you can ignore the session fields in the response. (format: int32)
  --session-jwt: string # The JSON Web Token (JWT) for a given Stytch Session.
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in   `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To   delete a key, supply a null value. Custom claims made with reserved claims (`iss`, `sub`, `aud`, `exp`, `nbf`, `iat`, `jti`) will be ignored.   Total custom claims size cannot exceed four kilobytes.
  --locale: string@locale-completer
  --intermediate-session-token: string # Adds this primary authentication factor to the intermediate session token. If the resulting set of factors satisfies the organization's primary authentication requirements and MFA requirements, the intermediate session token will be consumed and converted to a member session. If not, the same intermediate session token will be returned.
  --telemetry-id: string # If the `telemetry_id` is passed, as part of this request, Stytch will call the [Fingerprint Lookup API](https://stytch.com/docs/fraud/api/fingerprint-lookup) and store the associated fingerprints and IPGEO information for the Member. Your workspace must be enabled for Device Fingerprinting to use this feature.
]: any -> record<request_id: string, member_id: string, organization_id: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, session_token: string, session_jwt: string, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, intermediate_session_token: string, member_authenticated: bool, status_code: int, member_session: record<member_session_id: string, member_id: string, started_at: string, last_accessed_at: string, expires_at: string, authentication_factors: list<record>, organization_id: string, roles: list<string>, organization_slug: string, custom_claims: record>, mfa_required: record<member_options: record<mfa_phone_number: string, totp_registration_id: string>, secondary_auth_initiated: string>, primary_required: record<allowed_auth_methods: list<string>>, member_device: record<visitor_id: string, visitor_id_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_address: string, ip_address_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_geo_city: string, ip_geo_region: string, ip_geo_country: string, ip_geo_country_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/passwords/authenticate")
  let body = {organization_id: $organization_id, email_address: $email_address, password: $password, session_token: $session_token, session_duration_minutes: $session_duration_minutes, session_jwt: $session_jwt, session_custom_claims: $session_custom_claims, locale: $locale, intermediate_session_token: $intermediate_session_token, telemetry_id: $telemetry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Resetstart
#
# POST /v1/b2b/passwords/email/reset/start
# operationId: api_b2b_password_v1_b2b_passwords_email_ResetStart
export def "b2b-passwords-email-reset-start ResetStart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organization_id: string # Globally unique UUID that identifies a specific Organization. The `organization_id` is critical to perform operations on an Organization, so be sure to preserve this value. You may also use the organization_slug or organization_external_id here as a convenience.
  email_address: string # The email address of the Member to start the email reset process for.
  --reset-password-redirect-url: string # The URL that the Member is redirected to from the reset password magic link. This URL should display your application's reset password page.   Before rendering the reset page, extract the `token` from the query parameters. On the reset page, collect the new password and complete the flow by calling the corresponding Password Reset by Email endpoint.   If this parameter is not specified, the default Reset Password redirect URL configured in the Dashboard will be used. If you have not set a default Reset Password redirect URL, an error is returned.
  --reset-password-expiration-minutes: int # Sets a time limit after which the email link to reset the member's password will no longer be valid. The minimum allowed expiration is 5 minutes and the maximum is 10080 minutes (7 days). By default, the expiration is 30 minutes. (format: int32)
  --code-challenge: string # A base64url encoded SHA256 hash of a one time secret used to validate that the request starts and ends on the same device.
  --login-redirect-url: string # The URL that Members are redirected to upon clicking the "Log in without password" button in password reset emails.        After Members are redirected to the login redirect URL, your application should retrieve the `token` value from the URL parameters and call the [Magic Link Authenticate endpoint](https://stytch.com/docs/api/authenticate-magic-link) to log the Member in without requiring a password reset. If this value is not provided, your project's default login redirect URL will be used. If you have not set a default login redirect URL, an error will be returned.
  --locale: string@locale-completer
  --reset-password-template-id: string # Use a custom template for reset password emails. By default, it will use your default email template. Templates can be added in the [Stytch dashboard](https://stytch.com/dashboard/templates) using our built-in customization options or custom HTML templates with type “Passwords - Reset Password”.
  --verify-email-template-id: string # Use a custom template for verification emails sent during password reset flows. When cross-organization passwords are enabled for your Project, this template will be used the first time a user sets a password via a   password reset flow. By default, it will use your default email template. Templates can be added in the [Stytch dashboard](https://stytch.com/dashboard/templates) using our built-in customization options or custom HTML templates with type “Passwords - Email Verification”.
]: any -> record<request_id: string, member_id: string, member_email_id: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/passwords/email/reset/start")
  let body = {organization_id: $organization_id, email_address: $email_address, reset_password_redirect_url: $reset_password_redirect_url, reset_password_expiration_minutes: $reset_password_expiration_minutes, code_challenge: $code_challenge, login_redirect_url: $login_redirect_url, locale: $locale, reset_password_template_id: $reset_password_template_id, verify_email_template_id: $verify_email_template_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset
#
# POST /v1/b2b/passwords/email/reset
# operationId: api_b2b_password_v1_b2b_passwords_email_Reset
export def "b2b-passwords-email-reset Reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  password_reset_token: string # The password reset token to authenticate.
  password: string # The password to authenticate, reset, or set for the first time. Any UTF8 character is allowed, e.g. spaces, emojis, non-English characters, etc.
  --session-token: string # Reuse an existing session instead of creating a new one. If you provide a `session_token`, Stytch will update the session.       If the `session_token` and `magic_links_token` belong to different Members, the `session_token` will be ignored. This endpoint will error if       both `session_token` and `session_jwt` are provided.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will be created with a 60 minute duration. If you don't want   to use the Stytch session product, you can ignore the session fields in the response. (format: int32)
  --session-jwt: string # Reuse an existing session instead of creating a new one. If you provide a `session_jwt`, Stytch will update the session. If the `session_jwt`       and `magic_links_token` belong to different Members, the `session_jwt` will be ignored. This endpoint will error if both `session_token` and `session_jwt`       are provided.
  --code-verifier: string # A base64url encoded one time secret used to validate that the request starts and ends on the same device.
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in   `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To   delete a key, supply a null value. Custom claims made with reserved claims (`iss`, `sub`, `aud`, `exp`, `nbf`, `iat`, `jti`) will be ignored.   Total custom claims size cannot exceed four kilobytes.
  --locale: string@locale-completer
  --intermediate-session-token: string # Adds this primary authentication factor to the intermediate session token. If the resulting set of factors satisfies the organization's primary authentication requirements and MFA requirements, the intermediate session token will be consumed and converted to a member session. If not, the same intermediate session token will be returned.
  --telemetry-id: string # If the `telemetry_id` is passed, as part of this request, Stytch will call the [Fingerprint Lookup API](https://stytch.com/docs/fraud/api/fingerprint-lookup) and store the associated fingerprints and IPGEO information for the Member. Your workspace must be enabled for Device Fingerprinting to use this feature.
]: any -> record<request_id: string, member_id: string, member_email_id: string, organization_id: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, session_token: string, session_jwt: string, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, intermediate_session_token: string, member_authenticated: bool, status_code: int, member_session: record<member_session_id: string, member_id: string, started_at: string, last_accessed_at: string, expires_at: string, authentication_factors: list<record>, organization_id: string, roles: list<string>, organization_slug: string, custom_claims: record>, mfa_required: record<member_options: record<mfa_phone_number: string, totp_registration_id: string>, secondary_auth_initiated: string>, primary_required: record<allowed_auth_methods: list<string>>, member_device: record<visitor_id: string, visitor_id_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_address: string, ip_address_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_geo_city: string, ip_geo_region: string, ip_geo_country: string, ip_geo_country_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/passwords/email/reset")
  let body = {password_reset_token: $password_reset_token, password: $password, session_token: $session_token, session_duration_minutes: $session_duration_minutes, session_jwt: $session_jwt, code_verifier: $code_verifier, session_custom_claims: $session_custom_claims, locale: $locale, intermediate_session_token: $intermediate_session_token, telemetry_id: $telemetry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Requirereset
#
# POST /v1/b2b/passwords/email/require_reset
# operationId: api_b2b_password_v1_b2b_passwords_email_RequireReset
export def "b2b-passwords-email-require-reset RequireReset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
  email_address: string # The email address of the Member to start the email reset process for.
  --organization-id: string # Globally unique UUID that identifies a specific Organization. The `organization_id` is critical to perform operations on an Organization, so be sure to preserve this value. You may also use the organization_slug or organization_external_id here as a convenience.
  --member-id: string # Globally unique UUID that identifies a specific Member. The `member_id` is critical to perform operations on a Member, so be sure to preserve this value. You may use an external_id here if one is set for the member.
]: any -> record<request_id: string, status_code: int, member_id: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/passwords/email/require_reset")
  let body = {email_address: $email_address, organization_id: $organization_id, member_id: $member_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset
#
# POST /v1/b2b/passwords/session/reset
# operationId: api_b2b_password_v1_b2b_passwords_session_Reset
export def "b2b-passwords-session-reset Reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  organization_id: string # Globally unique UUID that identifies a specific Organization. The `organization_id` is critical to perform operations on an Organization, so be sure to preserve this value. You may also use the organization_slug or organization_external_id here as a convenience.
  password: string # The password to authenticate, reset, or set for the first time. Any UTF8 character is allowed, e.g. spaces, emojis, non-English characters, etc.
  --session-token: string # A secret token for a given Stytch Session.
  --session-jwt: string # The JSON Web Token (JWT) for a given Stytch Session.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will be created with a 60 minute duration. If you don't want   to use the Stytch session product, you can ignore the session fields in the response. (format: int32)
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in   `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To   delete a key, supply a null value. Custom claims made with reserved claims (`iss`, `sub`, `aud`, `exp`, `nbf`, `iat`, `jti`) will be ignored.   Total custom claims size cannot exceed four kilobytes.
  --locale: string@locale-completer
  --telemetry-id: string # If the `telemetry_id` is passed, as part of this request, Stytch will call the [Fingerprint Lookup API](https://stytch.com/docs/fraud/api/fingerprint-lookup) and store the associated fingerprints and IPGEO information for the Member. Your workspace must be enabled for Device Fingerprinting to use this feature.
]: any -> record<request_id: string, member_id: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, session_token: string, session_jwt: string, intermediate_session_token: string, member_authenticated: bool, status_code: int, member_session: record<member_session_id: string, member_id: string, started_at: string, last_accessed_at: string, expires_at: string, authentication_factors: list<record>, organization_id: string, roles: list<string>, organization_slug: string, custom_claims: record>, mfa_required: record<member_options: record<mfa_phone_number: string, totp_registration_id: string>, secondary_auth_initiated: string>, member_device: record<visitor_id: string, visitor_id_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_address: string, ip_address_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_geo_city: string, ip_geo_region: string, ip_geo_country: string, ip_geo_country_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/passwords/session/reset")
  let body = {organization_id: $organization_id, password: $password, session_token: $session_token, session_jwt: $session_jwt, session_duration_minutes: $session_duration_minutes, session_custom_claims: $session_custom_claims, locale: $locale, telemetry_id: $telemetry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset
#
# POST /v1/b2b/passwords/existing_password/reset
# operationId: api_b2b_password_v1_b2b_passwords_existing_password_Reset
export def "b2b-passwords-existing-password-reset Reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email_address: string # The email address of the Member.
  existing_password: string # The Member's current password that they supplied.
  new_password: string # The Member's elected new password.
  organization_id: string # Globally unique UUID that identifies a specific Organization. The `organization_id` is critical to perform operations on an Organization, so be sure to preserve this value. You may also use the organization_slug or organization_external_id here as a convenience.
  --session-token: string # A secret token for a given Stytch Session.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will be created with a 60 minute duration. If you don't want   to use the Stytch session product, you can ignore the session fields in the response. (format: int32)
  --session-jwt: string # The JSON Web Token (JWT) for a given Stytch Session.
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in   `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To   delete a key, supply a null value. Custom claims made with reserved claims (`iss`, `sub`, `aud`, `exp`, `nbf`, `iat`, `jti`) will be ignored.   Total custom claims size cannot exceed four kilobytes.
  --locale: string@locale-completer
  --telemetry-id: string # If the `telemetry_id` is passed, as part of this request, Stytch will call the [Fingerprint Lookup API](https://stytch.com/docs/fraud/api/fingerprint-lookup) and store the associated fingerprints and IPGEO information for the Member. Your workspace must be enabled for Device Fingerprinting to use this feature.
]: any -> record<request_id: string, member_id: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, session_token: string, session_jwt: string, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, intermediate_session_token: string, member_authenticated: bool, status_code: int, member_session: record<member_session_id: string, member_id: string, started_at: string, last_accessed_at: string, expires_at: string, authentication_factors: list<record>, organization_id: string, roles: list<string>, organization_slug: string, custom_claims: record>, mfa_required: record<member_options: record<mfa_phone_number: string, totp_registration_id: string>, secondary_auth_initiated: string>, primary_required: record<allowed_auth_methods: list<string>>, member_device: record<visitor_id: string, visitor_id_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_address: string, ip_address_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_geo_city: string, ip_geo_region: string, ip_geo_country: string, ip_geo_country_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/passwords/existing_password/reset")
  let body = {email_address: $email_address, existing_password: $existing_password, new_password: $new_password, organization_id: $organization_id, session_token: $session_token, session_duration_minutes: $session_duration_minutes, session_jwt: $session_jwt, session_custom_claims: $session_custom_claims, locale: $locale, telemetry_id: $telemetry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authenticate
#
# POST /v1/b2b/passwords/discovery/authenticate
# operationId: api_b2b_password_v1_b2b_passwords_discovery_Authenticate
export def "b2b-passwords-discovery-authenticate Authenticate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email_address: string # The email address of the Member.
  password: string # The password to authenticate, reset, or set for the first time. Any UTF8 character is allowed, e.g. spaces, emojis, non-English characters, etc.
]: any -> record<request_id: string, email_address: string, intermediate_session_token: string, discovered_organizations: table<member_authenticated: bool, organization: record, membership: record, primary_required: record, mfa_required: record>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/passwords/discovery/authenticate")
  let body = {email_address: $email_address, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Resetstart
#
# POST /v1/b2b/passwords/discovery/email/reset/start
# operationId: api_b2b_password_v1_b2b_passwords_discovery_email_ResetStart
export def "b2b-passwords-discovery-email-reset-start ResetStart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email_address: string # The email address of the Member to start the email reset process for.
  --reset-password-redirect-url: string # The URL that the Member is redirected to from the reset password magic link. This URL should display your application's reset password page.   Before rendering the reset page, extract the `token` from the query parameters. On the reset page, collect the new password and complete the flow by calling the corresponding Password Reset by Email endpoint.   If this parameter is not specified, the default Reset Password redirect URL configured in the Dashboard will be used. If you have not set a default Reset Password redirect URL, an error is returned.
  --discovery-redirect-url: string # The URL that the end user clicks from the discovery Magic Link. This URL should be an endpoint in the backend server that   verifies the request by querying Stytch's discovery authenticate endpoint and continues the flow. If this value is not passed, the default   discovery redirect URL that you set in your Dashboard is used. If you have not set a default discovery redirect URL, an error is returned.
  --reset-password-template-id: string # Use a custom template for reset password emails. By default, it will use your default email template. Templates can be added in the [Stytch dashboard](https://stytch.com/dashboard/templates) using our built-in customization options or custom HTML templates with type “Passwords - Reset Password”.
  --reset-password-expiration-minutes: int # Sets a time limit after which the email link to reset the member's password will no longer be valid. The minimum allowed expiration is 5 minutes and the maximum is 10080 minutes (7 days). By default, the expiration is 30 minutes. (format: int32)
  --pkce-code-challenge: string
  --locale: string # Used to determine which language to use when sending the user this delivery method. Parameter is an [IETF BCP 47 language tag](https://www.w3.org/International/articles/language-tags/), e.g. `"en"`.  Currently supported languages are English (`"en"`), Spanish (`"es"`), French (`"fr"`) and Brazilian Portuguese (`"pt-br"`); if no value is provided, the copy defaults to English.  Request support for additional languages [here](https://docs.google.com/forms/d/e/1FAIpQLScZSpAu_m2AmLXRT3F3kap-s_mcV6UTBitYn6CdyWP0-o7YjQ/viewform?usp=sf_link")!
  --verify-email-template-id: string # Use a custom template for verification emails sent during password reset flows. When cross-organization passwords are enabled for your Project, this template will be used the first time a user sets a password via a   password reset flow. By default, it will use your default email template. Templates can be added in the [Stytch dashboard](https://stytch.com/dashboard/templates) using our built-in customization options or custom HTML templates with type “Passwords - Email Verification”.
]: any -> record<request_id: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/passwords/discovery/email/reset/start")
  let body = {email_address: $email_address, reset_password_redirect_url: $reset_password_redirect_url, discovery_redirect_url: $discovery_redirect_url, reset_password_template_id: $reset_password_template_id, reset_password_expiration_minutes: $reset_password_expiration_minutes, pkce_code_challenge: $pkce_code_challenge, locale: $locale, verify_email_template_id: $verify_email_template_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Reset
#
# POST /v1/b2b/passwords/discovery/email/reset
# operationId: api_b2b_password_v1_b2b_passwords_discovery_email_Reset
export def "b2b-passwords-discovery-email-reset Reset" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  password_reset_token: string # The password reset token to authenticate.
  password: string # The password to authenticate, reset, or set for the first time. Any UTF8 character is allowed, e.g. spaces, emojis, non-English characters, etc.
  --pkce-code-verifier: string
]: any -> record<request_id: string, intermediate_session_token: string, email_address: string, discovered_organizations: table<member_authenticated: bool, organization: record, membership: record, primary_required: record, mfa_required: record>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/passwords/discovery/email/reset")
  let body = {password_reset_token: $password_reset_token, password: $password, pkce_code_verifier: $pkce_code_verifier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Attach
#
# POST /v1/oauth/attach
# operationId: api_oauth_v1_Attach
export def "oauth-attach Attach" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  provider: string # The OAuth provider's name.
  --user-id: string # The unique ID of a specific User. You may use an `external_id` here if one is set for the user.
  --session-token: string # The `session_token` associated with a User's existing Session.
  --session-jwt: string # The `session_jwt` associated with a User's existing Session.
]: any -> record<request_id: string, oauth_attach_token: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/oauth/attach")
  let body = {provider: $provider, user_id: $user_id, session_token: $session_token, session_jwt: $session_jwt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authenticate
#
# POST /v1/oauth/authenticate
# operationId: api_oauth_v1_Authenticate
export def "oauth-authenticate Authenticate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string # The OAuth `token` from the `?token=` query parameter in the URL.        The redirect URL will look like `https://example.com/authenticate?stytch_token_type=oauth&token=rM_kw42CWBhsHLF62V75jELMbvJ87njMe3tFVj7Qupu7`        In the redirect URL, the `stytch_token_type` will be `oauth`. See [here](https://stytch.com/docs/workspace-management/redirect-urls) for more detail.
  --session-token: string # Reuse an existing session instead of creating a new one. If you provide us with a `session_token`, then we'll update the session represented by this session token with this OAuth factor. If this `session_token` belongs to a different user than the OAuth token, the session_jwt will be ignored. This endpoint will error if both `session_token` and `session_jwt` are provided.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will not be created. (format: int32)
  --session-jwt: string # Reuse an existing session instead of creating a new one. If you provide us with a `session_jwt`, then we'll update the session represented by this JWT with this OAuth factor. If this `session_jwt` belongs to a different user than the OAuth token, the session_jwt will be ignored. This endpoint will error if both `session_token` and `session_jwt` are provided.
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To delete a key, supply a null value.    Custom claims made with reserved claims ("iss", "sub", "aud", "exp", "nbf", "iat", "jti") will be ignored. Total custom claims size cannot exceed four kilobytes.
  --code-verifier: string # A base64url encoded one time secret used to validate that the request starts and ends on the same device.
  --telemetry-id: string # If the `telemetry_id` is passed, as part of this request, Stytch will call the [Fingerprint Lookup API](https://stytch.com/docs/fraud/api/fingerprint-lookup) and store the associated fingerprints and IPGEO information for the User. Your workspace must be enabled for Device Fingerprinting to use this feature.
]: any -> record<request_id: string, user_id: string, provider_subject: string, provider_type: string, session_token: string, session_jwt: string, provider_values: record<access_token: string, refresh_token: string, id_token: string, scopes: list<string>, expires_at: string>, user: record<user_id: string, emails: list<record>, status: string, phone_numbers: list<record>, webauthn_registrations: list<record>, providers: list<record>, totps: list<record>, crypto_wallets: list<record>, biometric_registrations: list<record>, is_locked: bool, roles: list<string>, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, reset_sessions: bool, oauth_user_registration_id: string, status_code: int, user_session: record<session_id: string, user_id: string, authentication_factors: list<record>, roles: list<string>, started_at: string, last_accessed_at: string, expires_at: string, attributes: record<ip_address: string, user_agent: string>, custom_claims: record>, user_device: record<visitor_id: string, visitor_id_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_address: string, ip_address_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_geo_city: string, ip_geo_region: string, ip_geo_country: string, ip_geo_country_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/oauth/authenticate")
  let body = {token: $body_token, session_token: $session_token, session_duration_minutes: $session_duration_minutes, session_jwt: $session_jwt, session_custom_claims: $session_custom_claims, code_verifier: $code_verifier, telemetry_id: $telemetry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authenticate
#
# POST /v1/otps/authenticate
# operationId: api_otp_v1_Authenticate
# --attributes shape: {ip_address?: string, user_agent?: string}
# --options shape: {ip_match_required: bool, user_agent_match_required: bool}
export def "otps-authenticate Authenticate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  method_id: string # The `email_id` or `phone_id` involved in the given authentication.
  code: string # The code to authenticate.
  --attributes: record # shape: {ip_address?: string, user_agent?: string}
  --options: record # shape: {ip_match_required: bool, user_agent_match_required: bool}
  --session-token: string # The `session_token` associated with a User's existing Session.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will not be created. (format: int32)
  --session-jwt: string # The `session_jwt` associated with a User's existing Session.
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To delete a key, supply a null value.    Custom claims made with reserved claims ("iss", "sub", "aud", "exp", "nbf", "iat", "jti") will be ignored. Total custom claims size cannot exceed four kilobytes.
  --telemetry-id: string # If the `telemetry_id` is passed, as part of this request, Stytch will call the [Fingerprint Lookup API](https://stytch.com/docs/fraud/api/fingerprint-lookup) and store the associated fingerprints and IPGEO information for the User. Your workspace must be enabled for Device Fingerprinting to use this feature.
]: any -> record<request_id: string, user_id: string, method_id: string, session_token: string, session_jwt: string, user: record<user_id: string, emails: list<record>, status: string, phone_numbers: list<record>, webauthn_registrations: list<record>, providers: list<record>, totps: list<record>, crypto_wallets: list<record>, biometric_registrations: list<record>, is_locked: bool, roles: list<string>, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, reset_sessions: bool, status_code: int, session: record<session_id: string, user_id: string, authentication_factors: list<record>, roles: list<string>, started_at: string, last_accessed_at: string, expires_at: string, attributes: record<ip_address: string, user_agent: string>, custom_claims: record>, user_device: record<visitor_id: string, visitor_id_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_address: string, ip_address_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_geo_city: string, ip_geo_region: string, ip_geo_country: string, ip_geo_country_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/otps/authenticate")
  let body = {method_id: $method_id, code: $code, attributes: $attributes, options: $options, session_token: $session_token, session_duration_minutes: $session_duration_minutes, session_jwt: $session_jwt, session_custom_claims: $session_custom_claims, telemetry_id: $telemetry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send
#
# POST /v1/otps/sms/send
# operationId: api_otp_v1_otp_sms_Send
# --attributes shape: {ip_address?: string, user_agent?: string}
export def "otps-sms-send Send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  phone_number: string # The phone number to use for one-time passcodes. The phone number should be in E.164 format (i.e. +1XXXXXXXXXX). You may use +10000000000 to test this endpoint, see [Testing](https://stytch.com/docs/home#resources_testing) for more detail.
  --expiration-minutes: int # Set the expiration for the one-time passcode, in minutes. The minimum expiration is 1 minute and the maximum is 10 minutes. The default expiration is 2 minutes. (format: int32)
  --attributes: record # shape: {ip_address?: string, user_agent?: string}
  --locale: string@locale-completer
  --user-id: string # The unique ID of a specific User. You may use an `external_id` here if one is set for the user.
  --session-token: string # The `session_token` associated with a User's existing Session.
  --session-jwt: string # The `session_jwt` associated with a User's existing Session.
]: any -> record<request_id: string, user_id: string, phone_id: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/otps/sms/send")
  let body = {phone_number: $phone_number, expiration_minutes: $expiration_minutes, attributes: $attributes, locale: $locale, user_id: $user_id, session_token: $session_token, session_jwt: $session_jwt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Loginorcreate
#
# POST /v1/otps/sms/login_or_create
# operationId: api_otp_v1_otp_sms_LoginOrCreate
# --attributes shape: {ip_address?: string, user_agent?: string}
export def "otps-sms-login-or-create LoginOrCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  phone_number: string # The phone number to use for one-time passcodes. The phone number should be in E.164 format (i.e. +1XXXXXXXXXX). You may use +10000000000 to test this endpoint, see [Testing](https://stytch.com/docs/home#resources_testing) for more detail.
  --expiration-minutes: int # Set the expiration for the one-time passcode, in minutes. The minimum expiration is 1 minute and the maximum is 10 minutes. The default expiration is 2 minutes. (format: int32)
  --attributes: record # shape: {ip_address?: string, user_agent?: string}
  --create-user-as-pending: oneof<nothing, bool> # Flag for whether or not to save a user as pending vs active in Stytch. Defaults to false.         If true, users will be saved with status pending in Stytch's backend until authenticated.         If false, users will be created as active. An example usage of         a true flag would be to require users to verify their phone by entering the OTP code before creating         an account for them.
  --locale: string@locale-completer
]: any -> record<request_id: string, user_id: string, phone_id: string, user_created: bool, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/otps/sms/login_or_create")
  let body = {phone_number: $phone_number, expiration_minutes: $expiration_minutes, attributes: $attributes, create_user_as_pending: $create_user_as_pending, locale: $locale} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send
#
# POST /v1/otps/whatsapp/send
# operationId: api_otp_v1_otp_whatsapp_Send
# --attributes shape: {ip_address?: string, user_agent?: string}
export def "otps-whatsapp-send Send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  phone_number: string # The phone number to use for one-time passcodes. The phone number should be in E.164 format (i.e. +1XXXXXXXXXX). You may use +10000000000 to test this endpoint, see [Testing](https://stytch.com/docs/home#resources_testing) for more detail.
  --expiration-minutes: int # Set the expiration for the one-time passcode, in minutes. The minimum expiration is 1 minute and the maximum is 10 minutes. The default expiration is 2 minutes. (format: int32)
  --attributes: record # shape: {ip_address?: string, user_agent?: string}
  --locale: string@locale-completer
  --user-id: string # The unique ID of a specific User. You may use an `external_id` here if one is set for the user.
  --session-token: string # The `session_token` associated with a User's existing Session.
  --session-jwt: string # The `session_jwt` associated with a User's existing Session.
]: any -> record<request_id: string, user_id: string, phone_id: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/otps/whatsapp/send")
  let body = {phone_number: $phone_number, expiration_minutes: $expiration_minutes, attributes: $attributes, locale: $locale, user_id: $user_id, session_token: $session_token, session_jwt: $session_jwt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Loginorcreate
#
# POST /v1/otps/whatsapp/login_or_create
# operationId: api_otp_v1_otp_whatsapp_LoginOrCreate
# --attributes shape: {ip_address?: string, user_agent?: string}
export def "otps-whatsapp-login-or-create LoginOrCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  phone_number: string # The phone number to use for one-time passcodes. The phone number should be in E.164 format (i.e. +1XXXXXXXXXX). You may use +10000000000 to test this endpoint, see [Testing](https://stytch.com/docs/home#resources_testing) for more detail.
  --expiration-minutes: int # Set the expiration for the one-time passcode, in minutes. The minimum expiration is 1 minute and the maximum is 10 minutes. The default expiration is 2 minutes. (format: int32)
  --attributes: record # shape: {ip_address?: string, user_agent?: string}
  --create-user-as-pending: oneof<nothing, bool> # Flag for whether or not to save a user as pending vs active in Stytch. Defaults to false.         If true, users will be saved with status pending in Stytch's backend until authenticated.         If false, users will be created as active. An example usage of         a true flag would be to require users to verify their phone by entering the OTP code before creating         an account for them.
  --locale: string@locale-completer
]: any -> record<request_id: string, user_id: string, phone_id: string, user_created: bool, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/otps/whatsapp/login_or_create")
  let body = {phone_number: $phone_number, expiration_minutes: $expiration_minutes, attributes: $attributes, create_user_as_pending: $create_user_as_pending, locale: $locale} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send
#
# POST /v1/otps/email/send
# operationId: api_otp_v1_otp_email_Send
# --attributes shape: {ip_address?: string, user_agent?: string}
export def "otps-email-send Send" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # The email address of the user to send the one-time passcode to. You may use sandbox@stytch.com to test this endpoint, see [Testing](https://stytch.com/docs/home#resources_testing) for more detail.
  --expiration-minutes: int # Set the expiration for the one-time passcode, in minutes. The minimum expiration is 1 minute and the maximum is 10 minutes. The default expiration is 2 minutes. (format: int32)
  --attributes: record # shape: {ip_address?: string, user_agent?: string}
  --locale: string@locale-completer
  --user-id: string # The unique ID of a specific User. You may use an `external_id` here if one is set for the user.
  --session-token: string # The `session_token` associated with a User's existing Session.
  --session-jwt: string # The `session_jwt` associated with a User's existing Session.
  --login-template-id: string # Use a custom template for login emails. By default, it will use your default email template. Templates can be added in the [Stytch dashboard](https://stytch.com/dashboard/templates) using our built-in customization options or custom HTML templates with type “OTP - Login”.
  --signup-template-id: string # Use a custom template for sign-up emails. By default, it will use your default email template. Templates can be added in the [Stytch dashboard](https://stytch.com/dashboard/templates) using our built-in customization options or custom HTML templates with type “OTP - Sign-up”.
]: any -> record<request_id: string, user_id: string, email_id: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/otps/email/send")
  let body = {email: $email, expiration_minutes: $expiration_minutes, attributes: $attributes, locale: $locale, user_id: $user_id, session_token: $session_token, session_jwt: $session_jwt, login_template_id: $login_template_id, signup_template_id: $signup_template_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Loginorcreate
#
# POST /v1/otps/email/login_or_create
# operationId: api_otp_v1_otp_email_LoginOrCreate
# --attributes shape: {ip_address?: string, user_agent?: string}
export def "otps-email-login-or-create LoginOrCreate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # The email address of the user to send the one-time passcode to. You may use sandbox@stytch.com to test this endpoint, see [Testing](https://stytch.com/docs/home#resources_testing) for more detail.
  --expiration-minutes: int # Set the expiration for the one-time passcode, in minutes. The minimum expiration is 1 minute and the maximum is 10 minutes. The default expiration is 2 minutes. (format: int32)
  --attributes: record # shape: {ip_address?: string, user_agent?: string}
  --create-user-as-pending: oneof<nothing, bool> # Flag for whether or not to save a user as pending vs active in Stytch. Defaults to false.         If true, users will be saved with status pending in Stytch's backend until authenticated.         If false, users will be created as active. An example usage of         a true flag would be to require users to verify their phone by entering the OTP code before creating         an account for them.
  --locale: string@locale-completer
  --login-template-id: string # Use a custom template for login emails. By default, it will use your default email template. Templates can be added in the [Stytch dashboard](https://stytch.com/dashboard/templates) using our built-in customization options or custom HTML templates with type “Magic links - Login”.
  --signup-template-id: string # Use a custom template for sign-up emails. By default, it will use your default email template. Templates can be added in the [Stytch dashboard](https://stytch.com/dashboard/templates) using our built-in customization options or custom HTML templates with type “Magic links - Sign-up”.
]: any -> record<request_id: string, user_id: string, email_id: string, user_created: bool, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/otps/email/login_or_create")
  let body = {email: $email, expiration_minutes: $expiration_minutes, attributes: $attributes, create_user_as_pending: $create_user_as_pending, locale: $locale, login_template_id: $login_template_id, signup_template_id: $signup_template_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Metrics
#
# GET /v1/projects/metrics
# operationId: api_project_v1_Metrics
export def "projects-metrics Metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<request_id: string, project_id: string, metrics: table<metric_type: string, count: int>, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/projects/metrics")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Getconnections
#
# GET /v1/b2b/sso/{organization_id}
# operationId: api_sso_v1_GetConnections
export def "b2b-sso GetConnections" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
]: nothing -> record<request_id: string, saml_connections: table<organization_id: string, connection_id: string, status: string, idp_entity_id: string, display_name: string, idp_sso_url: string, acs_url: string, audience_uri: string, signing_certificates: list, verification_certificates: list, encryption_private_keys: list, saml_connection_implicit_role_assignments: list, saml_group_implicit_role_assignments: list, alternative_audience_uri: string, identity_provider: string, nameid_format: string, alternative_acs_url: string, idp_initiated_auth_disabled: bool, allow_gateway_callback: bool, attribute_mapping: record>, oidc_connections: table<organization_id: string, connection_id: string, status: string, display_name: string, redirect_url: string, client_id: string, client_secret: string, issuer: string, authorization_url: string, token_url: string, userinfo_url: string, jwks_url: string, identity_provider: string, custom_scopes: string, attribute_mapping: record>, external_connections: table<organization_id: string, connection_id: string, external_organization_id: string, external_connection_id: string, display_name: string, status: string, external_connection_implicit_role_assignments: list, external_group_implicit_role_assignments: list>, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/sso/($organization_id)")
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deleteconnection
#
# DELETE /v1/b2b/sso/{organization_id}/connections/{connection_id}
# operationId: api_sso_v1_DeleteConnection
export def "b2b-sso-connections DeleteConnection" [
  organization_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
]: nothing -> record<request_id: string, connection_id: string, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/sso/($organization_id)/connections/($connection_id)")
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Authenticate
#
# POST /v1/b2b/sso/authenticate
# operationId: api_sso_v1_Authenticate
export def "b2b-sso-authenticate Authenticate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sso_token: string # The token to authenticate.
  --pkce-code-verifier: string # A base64url encoded one time secret used to validate that the request starts and ends on the same device.
  --session-token: string # The `session_token` belonging to the member that you wish to associate the email with.
  --session-jwt: string # The `session_jwt` belonging to the member that you wish to associate the email with.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will be created with a 60 minute duration. If you don't want   to use the Stytch session product, you can ignore the session fields in the response. (format: int32)
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in   `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To   delete a key, supply a null value. Custom claims made with reserved claims (`iss`, `sub`, `aud`, `exp`, `nbf`, `iat`, `jti`) will be ignored.   Total custom claims size cannot exceed four kilobytes.
  --locale: string@locale-completer-1
  --intermediate-session-token: string # Adds this primary authentication factor to the intermediate session token. If the resulting set of factors satisfies the organization's primary authentication requirements and MFA requirements, the intermediate session token will be consumed and converted to a member session. If not, the same intermediate session token will be returned.
  --telemetry-id: string # If the `telemetry_id` is passed, as part of this request, Stytch will call the [Fingerprint Lookup API](https://stytch.com/docs/fraud/api/fingerprint-lookup) and store the associated fingerprints and IPGEO information for the Member. Your workspace must be enabled for Device Fingerprinting to use this feature.
]: any -> record<request_id: string, member_id: string, organization_id: string, member: record<organization_id: string, member_id: string, email_address: string, status: string, name: string, sso_registrations: list<record>, is_breakglass: bool, member_password_id: string, oauth_registrations: list<record>, email_address_verified: bool, mfa_phone_number_verified: bool, is_admin: bool, totp_registration_id: string, retired_email_addresses: list<record>, is_locked: bool, mfa_enrolled: bool, mfa_phone_number: string, default_mfa_method: string, roles: list<record>, trusted_metadata: record, untrusted_metadata: record, created_at: string, updated_at: string, scim_registration: record<connection_id: string, registration_id: string, external_id: string, scim_attributes: record>, external_id: string, lock_created_at: string, lock_expires_at: string>, session_token: string, session_jwt: string, reset_session: bool, organization: record<organization_id: string, organization_name: string, organization_logo_url: string, organization_slug: string, sso_jit_provisioning: string, sso_jit_provisioning_allowed_connections: list<string>, sso_active_connections: list<record>, email_allowed_domains: list<string>, email_jit_provisioning: string, email_invites: string, auth_methods: string, allowed_auth_methods: list<string>, mfa_policy: string, rbac_email_implicit_role_assignments: list<record>, mfa_methods: string, allowed_mfa_methods: list<string>, oauth_tenant_jit_provisioning: string, claimed_email_domains: list<string>, first_party_connected_apps_allowed_type: string, allowed_first_party_connected_apps: list<string>, third_party_connected_apps_allowed_type: string, allowed_third_party_connected_apps: list<string>, custom_roles: list<record>, trusted_metadata: record, created_at: string, updated_at: string, organization_external_id: string, sso_default_connection_id: string, scim_active_connection: record<connection_id: string, display_name: string, bearer_token_last_four: string, bearer_token_expires_at: string>, allowed_oauth_tenants: record>, intermediate_session_token: string, member_authenticated: bool, status_code: int, member_session: record<member_session_id: string, member_id: string, started_at: string, last_accessed_at: string, expires_at: string, authentication_factors: list<record>, organization_id: string, roles: list<string>, organization_slug: string, custom_claims: record>, mfa_required: record<member_options: record<mfa_phone_number: string, totp_registration_id: string>, secondary_auth_initiated: string>, primary_required: record<allowed_auth_methods: list<string>>, member_device: record<visitor_id: string, visitor_id_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_address: string, ip_address_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_geo_city: string, ip_geo_region: string, ip_geo_country: string, ip_geo_country_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/b2b/sso/authenticate")
  let body = {sso_token: $sso_token, pkce_code_verifier: $pkce_code_verifier, session_token: $session_token, session_jwt: $session_jwt, session_duration_minutes: $session_duration_minutes, session_custom_claims: $session_custom_claims, locale: $locale, intermediate_session_token: $intermediate_session_token, telemetry_id: $telemetry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Createconnection
#
# POST /v1/b2b/sso/oidc/{organization_id}
# operationId: api_sso_v1_sso_oidc_CreateConnection
export def "b2b-sso-oidc CreateConnection" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
  --display-name: string # A human-readable display name for the connection.
  --identity-provider: string@identity-provider-completer-1
]: any -> record<request_id: string, status_code: int, connection: record<organization_id: string, connection_id: string, status: string, display_name: string, redirect_url: string, client_id: string, client_secret: string, issuer: string, authorization_url: string, token_url: string, userinfo_url: string, jwks_url: string, identity_provider: string, custom_scopes: string, attribute_mapping: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/sso/oidc/($organization_id)")
  let body = {display_name: $display_name, identity_provider: $identity_provider} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updateconnection
#
# PUT /v1/b2b/sso/oidc/{organization_id}/connections/{connection_id}
# operationId: api_sso_v1_sso_oidc_UpdateConnection
export def "b2b-sso-oidc-connections UpdateConnection" [
  organization_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
  --display-name: string # A human-readable display name for the connection.
  --client-id: string # The OAuth2.0 client ID used to authenticate login attempts. This will be provided by the IdP.
  --client-secret: string # The secret belonging to the OAuth2.0 client used to authenticate login attempts. This will be provided by the IdP.
  --issuer: string # A case-sensitive `https://` URL that uniquely identifies the IdP. This will be provided by the IdP.
  --authorization-url: string # The location of the URL that starts an OAuth login at the IdP. This will be provided by the IdP.
  --token-url: string # The location of the URL that issues OAuth2.0 access tokens and OIDC ID tokens. This will be provided by the IdP.
  --userinfo-url: string # The location of the IDP's [UserInfo Endpoint](https://openid.net/specs/openid-connect-core-1_0.html#UserInfo). This will be provided by the IdP.
  --jwks-url: string # The location of the IdP's JSON Web Key Set, used to verify credentials issued by the IdP. This will be provided by the IdP.
  --identity-provider: string@identity-provider-completer-1
  --custom-scopes: string # Include a space-separated list of custom scopes that you'd like to include. Note that this list must be URL encoded, e.g. the spaces must be expressed as %20.
  --attribute-mapping: record # An object that represents the attributes used to identify a Member. This object will map the IdP-defined User attributes to Stytch-specific values, which will appear on the member's Trusted Metadata.
]: any -> record<request_id: string, status_code: int, connection: record<organization_id: string, connection_id: string, status: string, display_name: string, redirect_url: string, client_id: string, client_secret: string, issuer: string, authorization_url: string, token_url: string, userinfo_url: string, jwks_url: string, identity_provider: string, custom_scopes: string, attribute_mapping: record>, warning: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/sso/oidc/($organization_id)/connections/($connection_id)")
  let body = {display_name: $display_name, client_id: $client_id, client_secret: $client_secret, issuer: $issuer, authorization_url: $authorization_url, token_url: $token_url, userinfo_url: $userinfo_url, jwks_url: $jwks_url, identity_provider: $identity_provider, custom_scopes: $custom_scopes, attribute_mapping: $attribute_mapping} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Createconnection
#
# POST /v1/b2b/sso/saml/{organization_id}
# operationId: api_sso_v1_sso_saml_CreateConnection
export def "b2b-sso-saml CreateConnection" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
  --display-name: string # A human-readable display name for the connection.
  --identity-provider: string@identity-provider-completer-1
]: any -> record<request_id: string, status_code: int, connection: record<organization_id: string, connection_id: string, status: string, idp_entity_id: string, display_name: string, idp_sso_url: string, acs_url: string, audience_uri: string, signing_certificates: list<record>, verification_certificates: list<record>, encryption_private_keys: list<record>, saml_connection_implicit_role_assignments: list<record>, saml_group_implicit_role_assignments: list<record>, alternative_audience_uri: string, identity_provider: string, nameid_format: string, alternative_acs_url: string, idp_initiated_auth_disabled: bool, allow_gateway_callback: bool, attribute_mapping: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/sso/saml/($organization_id)")
  let body = {display_name: $display_name, identity_provider: $identity_provider} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updateconnection
#
# PUT /v1/b2b/sso/saml/{organization_id}/connections/{connection_id}
# operationId: api_sso_v1_sso_saml_UpdateConnection
# --saml_connection_implicit_role_assignments item shape: {role_id: string}
# --saml_group_implicit_role_assignments item shape: {role_id: string, group: string}
export def "b2b-sso-saml-connections UpdateConnection" [
  organization_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
  --idp-entity-id: string # A globally unique name for the IdP. This will be provided by the IdP.
  --display-name: string # A human-readable display name for the connection.
  --attribute-mapping: record # An object that represents the attributes used to identify a Member. This object will map the IdP-defined User attributes to Stytch-specific values. Required attributes: `email` and one of `full_name` or `first_name` and `last_name`.
  --x509-certificate: string # A certificate that Stytch will use to verify the sign-in assertion sent by the IdP, in [PEM](https://en.wikipedia.org/wiki/Privacy-Enhanced_Mail) format. See our [X509 guide](https://stytch.com/docs/b2b/api/saml-certificates) for more info.
  --idp-sso-url: string # The URL for which assertions for login requests will be sent. This will be provided by the IdP.
  --saml-connection-implicit-role-assignments: list # All Members who log in with this SAML connection will implicitly receive the specified Roles. See the [RBAC guide](https://stytch.com/docs/b2b/guides/rbac/role-assignment) for more information about role assignment. — item shape: {role_id: string}
  --saml-group-implicit-role-assignments: list # Defines the names of the SAML groups  that grant specific role assignments. For each group-Role pair, if a Member logs in with this SAML connection and  belongs to the specified SAML group, they will be granted the associated Role. See the  [RBAC guide](https://stytch.com/docs/b2b/guides/rbac/role-assignment) for more information about role assignment. Before adding any group implicit role assignments, you must add a "groups" key to your SAML connection's          `attribute_mapping`. Make sure that your IdP is configured to correctly send the group information. — item shape: {role_id: string, group: string}
  --alternative-audience-uri: string # An alternative URL to use for the Audience Restriction. This value can be used when you wish to migrate an existing SAML integration to Stytch with zero downtime. Read our [SSO migration guide](https://stytch.com/docs/b2b/guides/migrations/additional-migration-considerations) for more info.
  --identity-provider: string@identity-provider-completer-1
  --signing-private-key: string # A PKCS1 format RSA private key used for signing SAML requests. Only PKCS1 format (starting with "-----BEGIN RSA PRIVATE KEY-----") is supported. When provided, Stytch will generate a new x509 certificate from this key and return it in the signing_certificates array.
  --nameid-format: string # The NameID format the SAML Connection expects to use. Defaults to `urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress`.
  --alternative-acs-url: string # An alternative URL to use for the `AssertionConsumerServiceURL` in SP initiated SAML AuthNRequests. This value can be used when you wish to migrate an existing SAML integration to Stytch with zero downtime. Note that you will be responsible for proxying requests sent to the Alternative ACS URL to Stytch. Read our [SSO migration guide](https://stytch.com/docs/b2b/guides/migrations/additional-migration-considerations) for more info.
  --idp-initiated-auth-disabled: oneof<nothing, bool> # Determines whether IDP initiated auth is allowed for a given SAML connection. Defaults to false (IDP Initiated Auth is enabled).
  --saml-encryption-private-key: string # A PKCS1 format RSA private key used to decrypt encrypted SAML assertions. Only PKCS1 format (starting with "-----BEGIN RSA PRIVATE KEY-----") is supported.
  --allow-gateway-callback: oneof<nothing, bool>
]: any -> record<request_id: string, status_code: int, connection: record<organization_id: string, connection_id: string, status: string, idp_entity_id: string, display_name: string, idp_sso_url: string, acs_url: string, audience_uri: string, signing_certificates: list<record>, verification_certificates: list<record>, encryption_private_keys: list<record>, saml_connection_implicit_role_assignments: list<record>, saml_group_implicit_role_assignments: list<record>, alternative_audience_uri: string, identity_provider: string, nameid_format: string, alternative_acs_url: string, idp_initiated_auth_disabled: bool, allow_gateway_callback: bool, attribute_mapping: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/sso/saml/($organization_id)/connections/($connection_id)")
  let body = {idp_entity_id: $idp_entity_id, display_name: $display_name, attribute_mapping: $attribute_mapping, x509_certificate: $x509_certificate, idp_sso_url: $idp_sso_url, saml_connection_implicit_role_assignments: $saml_connection_implicit_role_assignments, saml_group_implicit_role_assignments: $saml_group_implicit_role_assignments, alternative_audience_uri: $alternative_audience_uri, identity_provider: $identity_provider, signing_private_key: $signing_private_key, nameid_format: $nameid_format, alternative_acs_url: $alternative_acs_url, idp_initiated_auth_disabled: $idp_initiated_auth_disabled, saml_encryption_private_key: $saml_encryption_private_key, allow_gateway_callback: $allow_gateway_callback} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updatebyurl
#
# PUT /v1/b2b/sso/saml/{organization_id}/connections/{connection_id}/url
# operationId: api_sso_v1_sso_saml_UpdateByURL
export def "b2b-sso-saml-connections-url UpdateByURL" [
  organization_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
  metadata_url: string # A URL that points to the IdP metadata. This will be provided by the IdP.
]: any -> record<request_id: string, status_code: int, connection: record<organization_id: string, connection_id: string, status: string, idp_entity_id: string, display_name: string, idp_sso_url: string, acs_url: string, audience_uri: string, signing_certificates: list<record>, verification_certificates: list<record>, encryption_private_keys: list<record>, saml_connection_implicit_role_assignments: list<record>, saml_group_implicit_role_assignments: list<record>, alternative_audience_uri: string, identity_provider: string, nameid_format: string, alternative_acs_url: string, idp_initiated_auth_disabled: bool, allow_gateway_callback: bool, attribute_mapping: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/sso/saml/($organization_id)/connections/($connection_id)/url")
  let body = {metadata_url: $metadata_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deleteverificationcertificate
#
# DELETE /v1/b2b/sso/saml/{organization_id}/connections/{connection_id}/verification_certificates/{certificate_id}
# operationId: api_sso_v1_sso_saml_DeleteVerificationCertificate
export def "b2b-sso-saml-connections-verification-certificates DeleteVerificationCertificate" [
  organization_id: string
  connection_id: string
  certificate_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
]: nothing -> record<request_id: string, certificate_id: string, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/sso/saml/($organization_id)/connections/($connection_id)/verification_certificates/($certificate_id)")
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deleteencryptionprivatekey
#
# DELETE /v1/b2b/sso/saml/{organization_id}/connections/{connection_id}/encryption_private_keys/{private_key_id}
# operationId: api_sso_v1_sso_saml_DeleteEncryptionPrivateKey
export def "b2b-sso-saml-connections-encryption-private-keys DeleteEncryptionPrivateKey" [
  organization_id: string
  connection_id: string
  private_key_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
]: nothing -> record<request_id: string, private_key_id: string, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/sso/saml/($organization_id)/connections/($connection_id)/encryption_private_keys/($private_key_id)")
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Createconnection
#
# POST /v1/b2b/sso/external/{organization_id}
# operationId: api_sso_v1_sso_external_CreateConnection
# --connection_implicit_role_assignments item shape: {role_id: string}
# --group_implicit_role_assignments item shape: {role_id: string, group: string}
export def "b2b-sso-external CreateConnection" [
  organization_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
  external_organization_id: string # Globally unique UUID that identifies a different Organization within your Project.
  external_connection_id: string # Globally unique UUID that identifies a specific SSO connection configured for a different Organization in your Project.
  --display-name: string # A human-readable display name for the connection.
  --connection-implicit-role-assignments: list # item shape: {role_id: string}
  --group-implicit-role-assignments: list # item shape: {role_id: string, group: string}
]: any -> record<request_id: string, status_code: int, connection: record<organization_id: string, connection_id: string, external_organization_id: string, external_connection_id: string, display_name: string, status: string, external_connection_implicit_role_assignments: list<record>, external_group_implicit_role_assignments: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/sso/external/($organization_id)")
  let body = {external_organization_id: $external_organization_id, external_connection_id: $external_connection_id, display_name: $display_name, connection_implicit_role_assignments: $connection_implicit_role_assignments, group_implicit_role_assignments: $group_implicit_role_assignments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Updateconnection
#
# PUT /v1/b2b/sso/external/{organization_id}/connections/{connection_id}
# operationId: api_sso_v1_sso_external_UpdateConnection
# --external_connection_implicit_role_assignments item shape: {role_id: string}
# --external_group_implicit_role_assignments item shape: {role_id: string, group: string}
export def "b2b-sso-external-connections UpdateConnection" [
  organization_id: string
  connection_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Stytch-Member-Session: string # A Stytch session that can be used to run the request with the given member's permissions.
  --X-Stytch-Member-SessionJWT: string # A Stytch Session JSON Web Token (JWT) that can be used to run the request with the given member's permissions.
  --display-name: string # A human-readable display name for the connection.
  --external-connection-implicit-role-assignments: list # All Members who log in with this External connection will implicitly receive the specified Roles. See the [RBAC guide](https://stytch.com/docs/b2b/guides/rbac/role-assignment) for more information about role assignment. Implicit role assignments are not supported for External connections if the underlying SSO connection is an OIDC connection.  — item shape: {role_id: string}
  --external-group-implicit-role-assignments: list # Defines the names of the groups  that grant specific role assignments. For each group-Role pair, if a Member logs in with this external connection and  belongs to the specified group, they will be granted the associated Role. See the  [RBAC guide](https://stytch.com/docs/b2b/guides/rbac/role-assignment) for more information about role assignment. Before adding any group implicit role assignments to an external connection, you must add a "groups" key to the underlying SAML connection's          `attribute_mapping`. Make sure that the SAML connection IdP is configured to correctly send the group information. Implicit role assignments are not supported          for External connections if the underlying SSO connection is an OIDC connection. — item shape: {role_id: string, group: string}
]: any -> record<request_id: string, status_code: int, connection: record<organization_id: string, connection_id: string, external_organization_id: string, external_connection_id: string, display_name: string, status: string, external_connection_implicit_role_assignments: list<record>, external_group_implicit_role_assignments: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/b2b/sso/external/($organization_id)/connections/($connection_id)")
  let body = {display_name: $display_name, external_connection_implicit_role_assignments: $external_connection_implicit_role_assignments, external_group_implicit_role_assignments: $external_group_implicit_role_assignments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Stytch-Member-Session": $X_Stytch_Member_Session, "X-Stytch-Member-SessionJWT": $X_Stytch_Member_SessionJWT} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create
#
# POST /v1/totps
# operationId: api_totp_v1_Create
export def "totps Create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user_id: string # The `user_id` of an active user the TOTP registration should be tied to. You may use an `external_id` here if one is set for the user.
  --expiration-minutes: int # The expiration for the TOTP instance. If the newly created TOTP is not authenticated within this time frame the TOTP will be unusable. Defaults to 1440 (1 day) with a minimum of 5 and a maximum of 1440. (format: int32)
]: any -> record<request_id: string, totp_id: string, secret: string, qr_code: string, recovery_codes: list<string>, user: record<user_id: string, emails: list<record>, status: string, phone_numbers: list<record>, webauthn_registrations: list<record>, providers: list<record>, totps: list<record>, crypto_wallets: list<record>, biometric_registrations: list<record>, is_locked: bool, roles: list<string>, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, user_id: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/totps")
  let body = {user_id: $user_id, expiration_minutes: $expiration_minutes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authenticate
#
# POST /v1/totps/authenticate
# operationId: api_totp_v1_Authenticate
export def "totps-authenticate Authenticate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user_id: string # The `user_id` of an active user the TOTP registration should be tied to. You may use an `external_id` here if one is set for the user.
  totp_code: string # The TOTP code to authenticate. The TOTP code should consist of 6 digits.
  --session-token: string # The `session_token` associated with a User's existing Session.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will not be created. (format: int32)
  --session-jwt: string # The `session_jwt` associated with a User's existing Session.
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To delete a key, supply a null value.    Custom claims made with reserved claims ("iss", "sub", "aud", "exp", "nbf", "iat", "jti") will be ignored. Total custom claims size cannot exceed four kilobytes.
  --telemetry-id: string # If the `telemetry_id` is passed, as part of this request, Stytch will call the [Fingerprint Lookup API](https://stytch.com/docs/fraud/api/fingerprint-lookup) and store the associated fingerprints and IPGEO information for the User. Your workspace must be enabled for Device Fingerprinting to use this feature.
]: any -> record<request_id: string, user_id: string, session_token: string, totp_id: string, session_jwt: string, user: record<user_id: string, emails: list<record>, status: string, phone_numbers: list<record>, webauthn_registrations: list<record>, providers: list<record>, totps: list<record>, crypto_wallets: list<record>, biometric_registrations: list<record>, is_locked: bool, roles: list<string>, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, status_code: int, session: record<session_id: string, user_id: string, authentication_factors: list<record>, roles: list<string>, started_at: string, last_accessed_at: string, expires_at: string, attributes: record<ip_address: string, user_agent: string>, custom_claims: record>, user_device: record<visitor_id: string, visitor_id_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_address: string, ip_address_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_geo_city: string, ip_geo_region: string, ip_geo_country: string, ip_geo_country_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/totps/authenticate")
  let body = {user_id: $user_id, totp_code: $totp_code, session_token: $session_token, session_duration_minutes: $session_duration_minutes, session_jwt: $session_jwt, session_custom_claims: $session_custom_claims, telemetry_id: $telemetry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Recoverycodes
#
# POST /v1/totps/recovery_codes
# operationId: api_totp_v1_RecoveryCodes
export def "totps-recovery-codes RecoveryCodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user_id: string # The `user_id` of an active user the TOTP registration should be tied to. You may use an `external_id` here if one is set for the user.
]: any -> record<request_id: string, user_id: string, totps: table<totp_id: string, verified: bool, recovery_codes: list>, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/totps/recovery_codes")
  let body = {user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Recover
#
# POST /v1/totps/recover
# operationId: api_totp_v1_Recover
export def "totps-recover Recover" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user_id: string # The `user_id` of an active user the TOTP registration should be tied to. You may use an `external_id` here if one is set for the user.
  recovery_code: string # The recovery code to authenticate.
  --session-token: string # The `session_token` associated with a User's existing Session.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will not be created. (format: int32)
  --session-jwt: string # The `session_jwt` associated with a User's existing Session.
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To delete a key, supply a null value.    Custom claims made with reserved claims ("iss", "sub", "aud", "exp", "nbf", "iat", "jti") will be ignored. Total custom claims size cannot exceed four kilobytes.
  --telemetry-id: string # If the `telemetry_id` is passed, as part of this request, Stytch will call the [Fingerprint Lookup API](https://stytch.com/docs/fraud/api/fingerprint-lookup) and store the associated fingerprints and IPGEO information for the User. Your workspace must be enabled for Device Fingerprinting to use this feature.
]: any -> record<request_id: string, totp_id: string, user_id: string, session_token: string, session_jwt: string, user: record<user_id: string, emails: list<record>, status: string, phone_numbers: list<record>, webauthn_registrations: list<record>, providers: list<record>, totps: list<record>, crypto_wallets: list<record>, biometric_registrations: list<record>, is_locked: bool, roles: list<string>, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, status_code: int, session: record<session_id: string, user_id: string, authentication_factors: list<record>, roles: list<string>, started_at: string, last_accessed_at: string, expires_at: string, attributes: record<ip_address: string, user_agent: string>, custom_claims: record>, user_device: record<visitor_id: string, visitor_id_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_address: string, ip_address_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_geo_city: string, ip_geo_region: string, ip_geo_country: string, ip_geo_country_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/totps/recover")
  let body = {user_id: $user_id, recovery_code: $recovery_code, session_token: $session_token, session_duration_minutes: $session_duration_minutes, session_jwt: $session_jwt, session_custom_claims: $session_custom_claims, telemetry_id: $telemetry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Registerstart
#
# POST /v1/webauthn/register/start
# operationId: api_webauthn_v1_RegisterStart
export def "webauthn-register-start RegisterStart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user_id: string # The `user_id` of an active user the Passkey or WebAuthn registration should be tied to. You may use an `external_id` here if one is set for the user.
  domain: string # The domain for Passkeys or WebAuthn. Defaults to `window.location.hostname`.
  --user-agent: string # The user agent of the client.
  --authenticator-type: string # The requested authenticator type of the Passkey or WebAuthn device. The two valid values are platform and cross-platform. If no value passed, we assume both values are allowed.
  --return-passkey-credential-options: oneof<nothing, bool> # If true, the `public_key_credential_creation_options` returned will be optimized for Passkeys with `residentKey` set to `"required"` and `userVerification` set to `"preferred"`.       
  --override-id: string
  --override-name: string
  --override-display-name: string
  --use-base64-url-encoding: oneof<nothing, bool> # If true, values in the `public_key_credential_creation_options` will be base64 URL encoded. Set this option to true when using built-in browser methods like `navigator.credentials.create` and `navigator.credentials.get`.
]: any -> record<request_id: string, user_id: string, public_key_credential_creation_options: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/webauthn/register/start")
  let body = {user_id: $user_id, domain: $domain, user_agent: $user_agent, authenticator_type: $authenticator_type, return_passkey_credential_options: $return_passkey_credential_options, override_id: $override_id, override_name: $override_name, override_display_name: $override_display_name, use_base64_url_encoding: $use_base64_url_encoding} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Register
#
# POST /v1/webauthn/register
# operationId: api_webauthn_v1_Register
export def "webauthn-register Register" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user_id: string # The `user_id` of an active user the Passkey or WebAuthn registration should be tied to. You may use an `external_id` here if one is set for the user.
  public_key_credential: string # The response of the [navigator.credentials.create()](https://www.w3.org/TR/webauthn-2/#sctn-createCredential).
  --session-token: string # The `session_token` associated with a User's existing Session.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will not be created. (format: int32)
  --session-jwt: string # The `session_jwt` associated with a User's existing Session.
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To delete a key, supply a null value.    Custom claims made with reserved claims ("iss", "sub", "aud", "exp", "nbf", "iat", "jti") will be ignored. Total custom claims size cannot exceed four kilobytes.
  --telemetry-id: string # If the `telemetry_id` is passed, as part of this request, Stytch will call the [Fingerprint Lookup API](https://stytch.com/docs/fraud/api/fingerprint-lookup) and store the associated fingerprints and IPGEO information for the User. Your workspace must be enabled for Device Fingerprinting to use this feature.
]: any -> record<request_id: string, user_id: string, webauthn_registration_id: string, session_token: string, session_jwt: string, user: record<user_id: string, emails: list<record>, status: string, phone_numbers: list<record>, webauthn_registrations: list<record>, providers: list<record>, totps: list<record>, crypto_wallets: list<record>, biometric_registrations: list<record>, is_locked: bool, roles: list<string>, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, status_code: int, session: record<session_id: string, user_id: string, authentication_factors: list<record>, roles: list<string>, started_at: string, last_accessed_at: string, expires_at: string, attributes: record<ip_address: string, user_agent: string>, custom_claims: record>, user_device: record<visitor_id: string, visitor_id_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_address: string, ip_address_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_geo_city: string, ip_geo_region: string, ip_geo_country: string, ip_geo_country_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/webauthn/register")
  let body = {user_id: $user_id, public_key_credential: $public_key_credential, session_token: $session_token, session_duration_minutes: $session_duration_minutes, session_jwt: $session_jwt, session_custom_claims: $session_custom_claims, telemetry_id: $telemetry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authenticatestart
#
# POST /v1/webauthn/authenticate/start
# operationId: api_webauthn_v1_AuthenticateStart
export def "webauthn-authenticate-start AuthenticateStart" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  domain: string # The domain for Passkeys or WebAuthn. Defaults to `window.location.hostname`.
  --user-id: string # The `user_id` of an active user the Passkey or WebAuthn registration should be tied to. You may use an `external_id` here if one is set for the user.
  --return-passkey-credential-options: oneof<nothing, bool> # If true, the `public_key_credential_creation_options` returned will be optimized for Passkeys with `userVerification` set to `"preferred"`.       
  --use-base64-url-encoding: oneof<nothing, bool> # If true, values in the `public_key_credential_creation_options` will be base64 URL encoded. Set this option to true when using built-in browser methods like `navigator.credentials.create` and `navigator.credentials.get`.
]: any -> record<request_id: string, user_id: string, public_key_credential_request_options: string, status_code: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/webauthn/authenticate/start")
  let body = {domain: $domain, user_id: $user_id, return_passkey_credential_options: $return_passkey_credential_options, use_base64_url_encoding: $use_base64_url_encoding} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Authenticate
#
# POST /v1/webauthn/authenticate
# operationId: api_webauthn_v1_Authenticate
export def "webauthn-authenticate Authenticate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  public_key_credential: string # The response of the [navigator.credentials.create()](https://www.w3.org/TR/webauthn-2/#sctn-createCredential).
  --session-token: string # The `session_token` associated with a User's existing Session.
  --session-duration-minutes: int # Set the session lifetime to be this many minutes from now. This will start a new session if one doesn't already exist,   returning both an opaque `session_token` and `session_jwt` for this session. Remember that the `session_jwt` will have a fixed lifetime of   five minutes regardless of the underlying session duration, and will need to be refreshed over time.    This value must be a minimum of 5 and a maximum of 527040 minutes (366 days).    If a `session_token` or `session_jwt` is provided then a successful authentication will continue to extend the session this many minutes.    If the `session_duration_minutes` parameter is not specified, a Stytch session will not be created. (format: int32)
  --session-jwt: string # The `session_jwt` associated with a User's existing Session.
  --session-custom-claims: record # Add a custom claims map to the Session being authenticated. Claims are only created if a Session is initialized by providing a value in `session_duration_minutes`. Claims will be included on the Session object and in the JWT. To update a key in an existing Session, supply a new value. To delete a key, supply a null value.    Custom claims made with reserved claims ("iss", "sub", "aud", "exp", "nbf", "iat", "jti") will be ignored. Total custom claims size cannot exceed four kilobytes.
  --telemetry-id: string # If the `telemetry_id` is passed, as part of this request, Stytch will call the [Fingerprint Lookup API](https://stytch.com/docs/fraud/api/fingerprint-lookup) and store the associated fingerprints and IPGEO information for the User. Your workspace must be enabled for Device Fingerprinting to use this feature.
]: any -> record<request_id: string, user_id: string, webauthn_registration_id: string, session_token: string, session_jwt: string, user: record<user_id: string, emails: list<record>, status: string, phone_numbers: list<record>, webauthn_registrations: list<record>, providers: list<record>, totps: list<record>, crypto_wallets: list<record>, biometric_registrations: list<record>, is_locked: bool, roles: list<string>, name: record<first_name: string, middle_name: string, last_name: string>, created_at: string, password: record<password_id: string, requires_reset: bool>, trusted_metadata: record, untrusted_metadata: record, external_id: string, lock_created_at: string, lock_expires_at: string>, status_code: int, session: record<session_id: string, user_id: string, authentication_factors: list<record>, roles: list<string>, started_at: string, last_accessed_at: string, expires_at: string, attributes: record<ip_address: string, user_agent: string>, custom_claims: record>, user_device: record<visitor_id: string, visitor_id_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_address: string, ip_address_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>, ip_geo_city: string, ip_geo_region: string, ip_geo_country: string, ip_geo_country_details: record<is_new: bool, first_seen_at: string, last_seen_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/webauthn/authenticate")
  let body = {public_key_credential: $public_key_credential, session_token: $session_token, session_duration_minutes: $session_duration_minutes, session_jwt: $session_jwt, session_custom_claims: $session_custom_claims, telemetry_id: $telemetry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update
#
# PUT /v1/webauthn/{webauthn_registration_id}
# operationId: api_webauthn_v1_Update
export def "webauthn Update" [
  webauthn_registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The `name` of the WebAuthn registration or Passkey.
]: any -> record<request_id: string, status_code: int, webauthn_registration: record<webauthn_registration_id: string, domain: string, user_agent: string, verified: bool, authenticator_type: string, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/webauthn/($webauthn_registration_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Listcredentials
#
# GET /v1/webauthn/credentials/{user_id}/{domain}
# operationId: api_webauthn_v1_ListCredentials
export def "webauthn-credentials ListCredentials" [
  user_id: string
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<credentials: table<credential_id: string, webauthn_registration_id: string, type: string, public_key: string>, request_id: string, status_code: int> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/webauthn/credentials/($user_id)/($domain)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
