# Auto-generated client for Discord HTTP API (Preview) v10
# Source: https://raw.githubusercontent.com/discord/discord-api-spec/main/specs/openapi.json
# Auth: --token flag or $env.DISCORD_HTTP_API_PREVIEW_TOKEN

const BASE_URL = "https://discord.com/api/v10"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DISCORD_HTTP_API_PREVIEW_TOKEN | default "" }
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

def base-url-completer [] { ["https://discord.com/api/v10"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def trigger-type-completer [] { ["4"] }
def entity-type-completer [] { ["3"] }
def type-completer [] { ["8"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "applications-me application" } } | get name | first)
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

# GET /applications/@me
#
# operationId: get_my_application
export def "applications-me application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, icon: string, description: string, type: any, cover_image: string, primary_sku_id: string, bot: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, slug: string, guild_id: string, rpc_origins: list<string>, bot_public: bool, bot_require_code_grant: bool, terms_of_service_url: string, privacy_policy_url: string, custom_install_url: string, install_params: record<scopes: list<string>, permissions: string>, integration_types_config: record, verify_key: string, flags: int, flags_new: string, max_participants: int, tags: list<string>, redirect_uris: list<string>, interactions_endpoint_url: string, role_connections_verification_url: string, owner: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, approximate_guild_count: int, approximate_user_install_count: int, approximate_user_authorization_count: int, event_webhooks_url: string, event_webhooks_status: int, event_webhooks_types: list<string>, explicit_content_filter: int, team: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/applications/@me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /applications/@me
#
# operationId: update_my_application
# --description shape: {default: string, localizations?: record}
export def "applications-me application-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: record # nullable — shape: {default: string, localizations?: record}
  --icon: string # nullable
  --cover-image: string # nullable
  --team-id: any
  --flags: int # nullable
  --interactions-endpoint-url: string # nullable, format: uri
  --explicit-content-filter: any
  --max-participants: int # nullable, format: int32
  --type: any
  --tags: list # nullable
  --custom-install-url: string # nullable, format: uri
  --install-params: any
  --role-connections-verification-url: string # nullable, format: uri
  --integration-types-config: record # nullable
  --event-webhooks-status: any
  --event-webhooks-url: string # Event webhooks URL for the app to receive webhook events (nullable, format: uri)
  --event-webhooks-types: list # nullable
]: any -> record<id: string, name: string, icon: string, description: string, type: any, cover_image: string, primary_sku_id: string, bot: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, slug: string, guild_id: string, rpc_origins: list<string>, bot_public: bool, bot_require_code_grant: bool, terms_of_service_url: string, privacy_policy_url: string, custom_install_url: string, install_params: record<scopes: list<string>, permissions: string>, integration_types_config: record, verify_key: string, flags: int, flags_new: string, max_participants: int, tags: list<string>, redirect_uris: list<string>, interactions_endpoint_url: string, role_connections_verification_url: string, owner: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, approximate_guild_count: int, approximate_user_install_count: int, approximate_user_authorization_count: int, event_webhooks_url: string, event_webhooks_status: int, event_webhooks_types: list<string>, explicit_content_filter: int, team: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/applications/@me")
  let body = {description: $description, icon: $icon, cover_image: $cover_image, team_id: $team_id, flags: $flags, interactions_endpoint_url: $interactions_endpoint_url, explicit_content_filter: $explicit_content_filter, max_participants: $max_participants, type: $type, tags: $tags, custom_install_url: $custom_install_url, install_params: $install_params, role_connections_verification_url: $role_connections_verification_url, integration_types_config: $integration_types_config, event_webhooks_status: $event_webhooks_status, event_webhooks_url: $event_webhooks_url, event_webhooks_types: $event_webhooks_types} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /applications/{application_id}
#
# operationId: get_application
export def "applications application-by-application_id" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, icon: string, description: string, type: any, cover_image: string, primary_sku_id: string, bot: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, slug: string, guild_id: string, rpc_origins: list<string>, bot_public: bool, bot_require_code_grant: bool, terms_of_service_url: string, privacy_policy_url: string, custom_install_url: string, install_params: record<scopes: list<string>, permissions: string>, integration_types_config: record, verify_key: string, flags: int, flags_new: string, max_participants: int, tags: list<string>, redirect_uris: list<string>, interactions_endpoint_url: string, role_connections_verification_url: string, owner: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, approximate_guild_count: int, approximate_user_install_count: int, approximate_user_authorization_count: int, event_webhooks_url: string, event_webhooks_status: int, event_webhooks_types: list<string>, explicit_content_filter: int, team: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($application_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /applications/{application_id}
#
# operationId: update_application
# --description shape: {default: string, localizations?: record}
export def "applications application-by-application_id-1" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: record # nullable — shape: {default: string, localizations?: record}
  --icon: string # nullable
  --cover-image: string # nullable
  --team-id: any
  --flags: int # nullable
  --interactions-endpoint-url: string # nullable, format: uri
  --explicit-content-filter: any
  --max-participants: int # nullable, format: int32
  --type: any
  --tags: list # nullable
  --custom-install-url: string # nullable, format: uri
  --install-params: any
  --role-connections-verification-url: string # nullable, format: uri
  --integration-types-config: record # nullable
  --event-webhooks-status: any
  --event-webhooks-url: string # Event webhooks URL for the app to receive webhook events (nullable, format: uri)
  --event-webhooks-types: list # nullable
]: any -> record<id: string, name: string, icon: string, description: string, type: any, cover_image: string, primary_sku_id: string, bot: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, slug: string, guild_id: string, rpc_origins: list<string>, bot_public: bool, bot_require_code_grant: bool, terms_of_service_url: string, privacy_policy_url: string, custom_install_url: string, install_params: record<scopes: list<string>, permissions: string>, integration_types_config: record, verify_key: string, flags: int, flags_new: string, max_participants: int, tags: list<string>, redirect_uris: list<string>, interactions_endpoint_url: string, role_connections_verification_url: string, owner: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, approximate_guild_count: int, approximate_user_install_count: int, approximate_user_authorization_count: int, event_webhooks_url: string, event_webhooks_status: int, event_webhooks_types: list<string>, explicit_content_filter: int, team: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($application_id)")
  let body = {description: $description, icon: $icon, cover_image: $cover_image, team_id: $team_id, flags: $flags, interactions_endpoint_url: $interactions_endpoint_url, explicit_content_filter: $explicit_content_filter, max_participants: $max_participants, type: $type, tags: $tags, custom_install_url: $custom_install_url, install_params: $install_params, role_connections_verification_url: $role_connections_verification_url, integration_types_config: $integration_types_config, event_webhooks_status: $event_webhooks_status, event_webhooks_url: $event_webhooks_url, event_webhooks_types: $event_webhooks_types} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /applications/{application_id}/activity-instances/{instance_id}
#
# operationId: applications_get_activity_instance
export def "applications-activity-instances instance" [
  application_id: string
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<application_id: string, instance_id: string, launch_id: string, location: any, users: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($application_id)/activity-instances/($instance_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /applications/{application_id}/attachment
#
# operationId: upload_application_attachment
export def "applications-attachment attachment" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  file: string
]: any -> record<attachment: record<id: string, filename: string, size: int, url: string, proxy_url: string, width: int, height: int, duration_secs: float, waveform: string, description: string, content_type: string, ephemeral: bool, flags: int, placeholder: string, placeholder_version: int, title: string, application: record<id: string, name: string, icon: string, description: string, type: any, cover_image: string, primary_sku_id: string, bot: record, slug: string, guild_id: string, rpc_origins: list, bot_public: bool, bot_require_code_grant: bool, terms_of_service_url: string, privacy_policy_url: string, custom_install_url: string, install_params: record, integration_types_config: record, verify_key: string, flags: int, flags_new: string, max_participants: int, tags: list>, clip_created_at: string, clip_participants: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($application_id)/attachment")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# GET /applications/{application_id}/commands
#
# operationId: list_application_commands
export def "applications-commands commands-by-application_id" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --with-localizations: oneof<nothing, bool>
]: nothing -> table<id: string, application_id: string, version: string, default_member_permissions: string, type: int, name: string, name_localized: string, name_localizations: record, description: string, description_localized: string, description_localizations: record, guild_id: string, dm_permission: bool, contexts: list<int>, integration_types: list<int>, options: list<any>, nsfw: bool, handler: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_localizations" $with_localizations "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/applications/($application_id)/commands" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /applications/{application_id}/commands
#
# operationId: bulk_set_application_commands
export def "applications-commands commands-by-application_id-1" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<id: string, application_id: string, version: string, default_member_permissions: string, type: int, name: string, name_localized: string, name_localizations: record, description: string, description_localized: string, description_localizations: record, guild_id: string, dm_permission: bool, contexts: list<int>, integration_types: list<int>, options: list<any>, nsfw: bool, handler: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($application_id)/commands")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /applications/{application_id}/commands
#
# operationId: create_application_command
export def "applications-commands command-by-application_id" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --name-localizations: record # nullable
  --description: string # nullable
  --description-localizations: record # nullable
  --options: list # nullable
  --default-member-permissions: int # nullable
  --dm-permission: oneof<nothing, bool> # nullable
  --contexts: list # nullable
  --integration-types: list # nullable
  --handler: any # Determines whether the interaction is handled by the app's interactions handler or by Discord
  --type: any
]: any -> record<id: string, application_id: string, version: string, default_member_permissions: string, type: int, name: string, name_localized: string, name_localizations: record, description: string, description_localized: string, description_localizations: record, guild_id: string, dm_permission: bool, contexts: list<int>, integration_types: list<int>, options: list<any>, nsfw: bool, handler: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($application_id)/commands")
  let body = {name: $name, name_localizations: $name_localizations, description: $description, description_localizations: $description_localizations, options: $options, default_member_permissions: $default_member_permissions, dm_permission: $dm_permission, contexts: $contexts, integration_types: $integration_types, handler: $handler, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /applications/{application_id}/commands/{command_id}
#
# operationId: get_application_command
export def "applications-commands command-by-application_id-command_id" [
  application_id: string
  command_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, application_id: string, version: string, default_member_permissions: string, type: int, name: string, name_localized: string, name_localizations: record, description: string, description_localized: string, description_localizations: record, guild_id: string, dm_permission: bool, contexts: list<int>, integration_types: list<int>, options: list<any>, nsfw: bool, handler: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($application_id)/commands/($command_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /applications/{application_id}/commands/{command_id}
#
# operationId: delete_application_command
export def "applications-commands command-by-application_id-command_id-1" [
  application_id: string
  command_id: string
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
  let full_url = (build-url $base $"/applications/($application_id)/commands/($command_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /applications/{application_id}/commands/{command_id}
#
# operationId: update_application_command
export def "applications-commands command-by-application_id-command_id-2" [
  application_id: string
  command_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --name-localizations: record # nullable
  --description: string # nullable
  --description-localizations: record # nullable
  --options: list # nullable
  --default-member-permissions: int # nullable
  --dm-permission: oneof<nothing, bool> # nullable
  --contexts: list # nullable
  --integration-types: list # nullable
  --handler: any # Determines whether the interaction is handled by the app's interactions handler or by Discord
]: any -> record<id: string, application_id: string, version: string, default_member_permissions: string, type: int, name: string, name_localized: string, name_localizations: record, description: string, description_localized: string, description_localizations: record, guild_id: string, dm_permission: bool, contexts: list<int>, integration_types: list<int>, options: list<any>, nsfw: bool, handler: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($application_id)/commands/($command_id)")
  let body = {name: $name, name_localizations: $name_localizations, description: $description, description_localizations: $description_localizations, options: $options, default_member_permissions: $default_member_permissions, dm_permission: $dm_permission, contexts: $contexts, integration_types: $integration_types, handler: $handler} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /applications/{application_id}/emojis
#
# operationId: list_application_emojis
export def "applications-emojis emojis" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<items: table<id: string, name: string, user: record, roles: list, require_colons: bool, managed: bool, animated: bool, available: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($application_id)/emojis")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /applications/{application_id}/emojis
#
# operationId: create_application_emoji
export def "applications-emojis emoji-by-application_id" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  image: string
]: any -> record<id: string, name: string, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, roles: list<string>, require_colons: bool, managed: bool, animated: bool, available: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($application_id)/emojis")
  let body = {name: $name, image: $image} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /applications/{application_id}/emojis/{emoji_id}
#
# operationId: get_application_emoji
export def "applications-emojis emoji-by-application_id-emoji_id" [
  application_id: string
  emoji_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, roles: list<string>, require_colons: bool, managed: bool, animated: bool, available: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($application_id)/emojis/($emoji_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /applications/{application_id}/emojis/{emoji_id}
#
# operationId: delete_application_emoji
export def "applications-emojis emoji-by-application_id-emoji_id-1" [
  application_id: string
  emoji_id: string
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
  let full_url = (build-url $base $"/applications/($application_id)/emojis/($emoji_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /applications/{application_id}/emojis/{emoji_id}
#
# operationId: update_application_emoji
export def "applications-emojis emoji-by-application_id-emoji_id-2" [
  application_id: string
  emoji_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
]: any -> record<id: string, name: string, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, roles: list<string>, require_colons: bool, managed: bool, animated: bool, available: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($application_id)/emojis/($emoji_id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /applications/{application_id}/entitlements
#
# operationId: get_entitlements
export def "applications-entitlements entitlements" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --user-id: string # format: snowflake
  --sku-ids: string
  --guild-id: string # format: snowflake
  --before: string # format: snowflake
  --after: string # format: snowflake
  --limit: int
  --exclude-ended: oneof<nothing, bool>
  --exclude-deleted: oneof<nothing, bool>
  --only-active: oneof<nothing, bool>
]: nothing -> table<id: string, sku_id: string, application_id: string, user_id: string, guild_id: any, deleted: bool, starts_at: string, ends_at: string, type: int, fulfilled_at: string, fulfillment_status: any, consumed: bool, gifter_user_id: any, parent_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "sku_ids" $sku_ids "scalar") (serialize-qp "guild_id" $guild_id "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "exclude_ended" $exclude_ended "scalar") (serialize-qp "exclude_deleted" $exclude_deleted "scalar") (serialize-qp "only_active" $only_active "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/applications/($application_id)/entitlements" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /applications/{application_id}/entitlements
#
# operationId: create_entitlement
export def "applications-entitlements entitlement-by-application_id" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sku_id: string # format: snowflake
  owner_id: string # format: snowflake
  owner_type: int # format: int32
]: any -> record<id: string, sku_id: string, application_id: string, user_id: string, guild_id: any, deleted: bool, starts_at: string, ends_at: string, type: int, fulfilled_at: string, fulfillment_status: any, consumed: bool, gifter_user_id: any, parent_id: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($application_id)/entitlements")
  let body = {sku_id: $sku_id, owner_id: $owner_id, owner_type: $owner_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /applications/{application_id}/entitlements/{entitlement_id}
#
# operationId: get_entitlement
export def "applications-entitlements entitlement-by-application_id-entitlement_id" [
  application_id: string
  entitlement_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, sku_id: string, application_id: string, user_id: string, guild_id: any, deleted: bool, starts_at: string, ends_at: string, type: int, fulfilled_at: string, fulfillment_status: any, consumed: bool, gifter_user_id: any, parent_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($application_id)/entitlements/($entitlement_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /applications/{application_id}/entitlements/{entitlement_id}
#
# operationId: delete_entitlement
export def "applications-entitlements entitlement-by-application_id-entitlement_id-1" [
  application_id: string
  entitlement_id: string
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
  let full_url = (build-url $base $"/applications/($application_id)/entitlements/($entitlement_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /applications/{application_id}/entitlements/{entitlement_id}/consume
#
# operationId: consume_entitlement
export def "applications-entitlements-consume entitlement" [
  application_id: string
  entitlement_id: string
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
  let full_url = (build-url $base $"/applications/($application_id)/entitlements/($entitlement_id)/consume")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /applications/{application_id}/guilds/{guild_id}/commands
#
# operationId: list_guild_application_commands
export def "applications-guilds-commands commands-by-application_id-guild_id" [
  application_id: string
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --with-localizations: oneof<nothing, bool>
]: nothing -> table<id: string, application_id: string, version: string, default_member_permissions: string, type: int, name: string, name_localized: string, name_localizations: record, description: string, description_localized: string, description_localizations: record, guild_id: string, dm_permission: bool, contexts: list<int>, integration_types: list<int>, options: list<any>, nsfw: bool, handler: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_localizations" $with_localizations "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/applications/($application_id)/guilds/($guild_id)/commands" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /applications/{application_id}/guilds/{guild_id}/commands
#
# operationId: bulk_set_guild_application_commands
export def "applications-guilds-commands commands-by-application_id-guild_id-1" [
  application_id: string
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<id: string, application_id: string, version: string, default_member_permissions: string, type: int, name: string, name_localized: string, name_localizations: record, description: string, description_localized: string, description_localizations: record, guild_id: string, dm_permission: bool, contexts: list<int>, integration_types: list<int>, options: list<any>, nsfw: bool, handler: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($application_id)/guilds/($guild_id)/commands")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /applications/{application_id}/guilds/{guild_id}/commands
#
# operationId: create_guild_application_command
export def "applications-guilds-commands command-by-application_id-guild_id" [
  application_id: string
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --name-localizations: record # nullable
  --description: string # nullable
  --description-localizations: record # nullable
  --options: list # nullable
  --default-member-permissions: int # nullable
  --dm-permission: oneof<nothing, bool> # nullable
  --contexts: list # nullable
  --integration-types: list # nullable
  --handler: any # Determines whether the interaction is handled by the app's interactions handler or by Discord
  --type: any
]: any -> record<id: string, application_id: string, version: string, default_member_permissions: string, type: int, name: string, name_localized: string, name_localizations: record, description: string, description_localized: string, description_localizations: record, guild_id: string, dm_permission: bool, contexts: list<int>, integration_types: list<int>, options: list<any>, nsfw: bool, handler: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($application_id)/guilds/($guild_id)/commands")
  let body = {name: $name, name_localizations: $name_localizations, description: $description, description_localizations: $description_localizations, options: $options, default_member_permissions: $default_member_permissions, dm_permission: $dm_permission, contexts: $contexts, integration_types: $integration_types, handler: $handler, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /applications/{application_id}/guilds/{guild_id}/commands/permissions
#
# operationId: list_guild_application_command_permissions
export def "applications-guilds-commands-permissions permissions-by-application_id-guild_id" [
  application_id: string
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, application_id: string, guild_id: string, permissions: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($application_id)/guilds/($guild_id)/commands/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /applications/{application_id}/guilds/{guild_id}/commands/{command_id}
#
# operationId: get_guild_application_command
export def "applications-guilds-commands command-by-application_id-guild_id-command_id" [
  application_id: string
  guild_id: string
  command_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, application_id: string, version: string, default_member_permissions: string, type: int, name: string, name_localized: string, name_localizations: record, description: string, description_localized: string, description_localizations: record, guild_id: string, dm_permission: bool, contexts: list<int>, integration_types: list<int>, options: list<any>, nsfw: bool, handler: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($application_id)/guilds/($guild_id)/commands/($command_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /applications/{application_id}/guilds/{guild_id}/commands/{command_id}
#
# operationId: delete_guild_application_command
export def "applications-guilds-commands command-by-application_id-guild_id-command_id-1" [
  application_id: string
  guild_id: string
  command_id: string
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
  let full_url = (build-url $base $"/applications/($application_id)/guilds/($guild_id)/commands/($command_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /applications/{application_id}/guilds/{guild_id}/commands/{command_id}
#
# operationId: update_guild_application_command
export def "applications-guilds-commands command-by-application_id-guild_id-command_id-2" [
  application_id: string
  guild_id: string
  command_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --name-localizations: record # nullable
  --description: string # nullable
  --description-localizations: record # nullable
  --options: list # nullable
  --default-member-permissions: int # nullable
  --dm-permission: oneof<nothing, bool> # nullable
  --contexts: list # nullable
  --integration-types: list # nullable
  --handler: any # Determines whether the interaction is handled by the app's interactions handler or by Discord
]: any -> record<id: string, application_id: string, version: string, default_member_permissions: string, type: int, name: string, name_localized: string, name_localizations: record, description: string, description_localized: string, description_localizations: record, guild_id: string, dm_permission: bool, contexts: list<int>, integration_types: list<int>, options: list<any>, nsfw: bool, handler: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($application_id)/guilds/($guild_id)/commands/($command_id)")
  let body = {name: $name, name_localizations: $name_localizations, description: $description, description_localizations: $description_localizations, options: $options, default_member_permissions: $default_member_permissions, dm_permission: $dm_permission, contexts: $contexts, integration_types: $integration_types, handler: $handler} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /applications/{application_id}/guilds/{guild_id}/commands/{command_id}/permissions
#
# operationId: get_guild_application_command_permissions
export def "applications-guilds-commands-permissions permissions-by-application_id-guild_id-command_id" [
  application_id: string
  guild_id: string
  command_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, application_id: string, guild_id: string, permissions: table<id: string, type: int, permission: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($application_id)/guilds/($guild_id)/commands/($command_id)/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /applications/{application_id}/guilds/{guild_id}/commands/{command_id}/permissions
#
# operationId: set_guild_application_command_permissions
# --permissions item shape: {id: string, type: int, permission: bool}
export def "applications-guilds-commands-permissions permissions-by-application_id-guild_id-command_id-1" [
  application_id: string
  guild_id: string
  command_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --permissions: list # nullable — item shape: {id: string, type: int, permission: bool}
]: any -> record<id: string, application_id: string, guild_id: string, permissions: table<id: string, type: int, permission: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($application_id)/guilds/($guild_id)/commands/($command_id)/permissions")
  let body = {permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /applications/{application_id}/role-connections/metadata
#
# operationId: get_application_role_connections_metadata
export def "applications-role-connections-metadata metadata-by-application_id" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<type: int, key: string, name: string, name_localizations: record, description: string, description_localizations: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($application_id)/role-connections/metadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /applications/{application_id}/role-connections/metadata
#
# operationId: update_application_role_connections_metadata
export def "applications-role-connections-metadata metadata-by-application_id-1" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<type: int, key: string, name: string, name_localizations: record, description: string, description_localizations: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/applications/($application_id)/role-connections/metadata")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /channels/{channel_id}
#
# operationId: get_channel
export def "channels channel-by-channel_id" [
  channel_id: string
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
  let full_url = (build-url $base $"/channels/($channel_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /channels/{channel_id}
#
# operationId: delete_channel
export def "channels channel-by-channel_id-1" [
  channel_id: string
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
  let full_url = (build-url $base $"/channels/($channel_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /channels/{channel_id}
#
# operationId: update_channel
# --permission_overwrites item shape: {id: string, type?: any, allow?: int, deny?: int}
# --available_tags item shape: {name: string, emoji_id?: any, emoji_name?: string, moderated?: bool, id?: any}
export def "channels channel-by-channel_id-2" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # nullable
  --icon: string # nullable
  --type: any
  --position: int # nullable, format: int32
  --topic: string # nullable
  --bitrate: int # nullable, format: int32
  --user-limit: int # nullable, format: int32
  --nsfw: oneof<nothing, bool> # nullable
  --rate-limit-per-user: int # nullable
  --parent-id: any
  --permission-overwrites: list # nullable — item shape: {id: string, type?: any, allow?: int, deny?: int}
  --rtc-region: string # nullable
  --video-quality-mode: any
  --default-auto-archive-duration: any
  --default-reaction-emoji: any
  --default-thread-rate-limit-per-user: int # nullable
  --default-sort-order: any
  --default-forum-layout: any
  --default-tag-setting: any
  --flags: int # nullable
  --available-tags: list # nullable — item shape: {name: string, emoji_id?: any, emoji_name?: string, moderated?: bool, id?: any}
  --archived: oneof<nothing, bool> # nullable
  --locked: oneof<nothing, bool> # nullable
  --invitable: oneof<nothing, bool> # nullable
  --auto-archive-duration: any
  --applied-tags: list # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/channels/($channel_id)")
  let body = {name: $name, icon: $icon, type: $type, position: $position, topic: $topic, bitrate: $bitrate, user_limit: $user_limit, nsfw: $nsfw, rate_limit_per_user: $rate_limit_per_user, parent_id: $parent_id, permission_overwrites: $permission_overwrites, rtc_region: $rtc_region, video_quality_mode: $video_quality_mode, default_auto_archive_duration: $default_auto_archive_duration, default_reaction_emoji: $default_reaction_emoji, default_thread_rate_limit_per_user: $default_thread_rate_limit_per_user, default_sort_order: $default_sort_order, default_forum_layout: $default_forum_layout, default_tag_setting: $default_tag_setting, flags: $flags, available_tags: $available_tags, archived: $archived, locked: $locked, invitable: $invitable, auto_archive_duration: $auto_archive_duration, applied_tags: $applied_tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /channels/{channel_id}/followers
#
# operationId: follow_channel
export def "channels-followers channel" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  webhook_channel_id: string # format: snowflake
]: any -> record<channel_id: string, webhook_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/channels/($channel_id)/followers")
  let body = {webhook_channel_id: $webhook_channel_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /channels/{channel_id}/invites
#
# operationId: list_channel_invites
export def "channels-invites invites" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/channels/($channel_id)/invites")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /channels/{channel_id}/invites
#
# operationId: create_channel_invite
export def "channels-invites invite" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --max-age: int # nullable
  --temporary: oneof<nothing, bool> # nullable
  --max-uses: int # nullable
  --unique: oneof<nothing, bool> # nullable
  --target-user-id: any
  --target-application-id: any
  --target-type: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/channels/($channel_id)/invites")
  let body = {max_age: $max_age, temporary: $temporary, max_uses: $max_uses, unique: $unique, target_user_id: $target_user_id, target_application_id: $target_application_id, target_type: $target_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /channels/{channel_id}/messages
#
# operationId: list_messages
export def "channels-messages messages" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --around: string # format: snowflake
  --before: string # format: snowflake
  --after: string # format: snowflake
  --limit: int
]: nothing -> table<type: int, content: string, mentions: list<record>, mention_roles: list<string>, attachments: list<record>, embeds: list<record>, timestamp: string, edited_timestamp: string, flags: int, components: list<any>, stickers: list<any>, sticker_items: list<record>, id: string, channel_id: string, author: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, pinned: bool, mention_everyone: bool, tts: bool, call: record<ended_timestamp: string, participants: list>, activity: record<type: int, party_id: string>, application: record<id: string, name: string, icon: string, description: string, type: any, cover_image: string, primary_sku_id: string, bot: record>, application_id: string, interaction: record<id: string, type: int, name: string, user: record, name_localized: string>, nonce: any, webhook_id: string, message_reference: record<type: int, channel_id: string, message_id: string, guild_id: string>, thread: record<id: string, type: int, last_message_id: any, flags: int, last_pin_timestamp: string, guild_id: string, name: string, parent_id: any, rate_limit_per_user: int, bitrate: int, user_limit: int, rtc_region: string, video_quality_mode: int, permissions: string, owner_id: string, thread_metadata: record, message_count: int, member_count: int, total_message_sent: int, applied_tags: list, member: record>, mention_channels: list<record>, role_subscription_data: record<role_subscription_listing_id: string, tier_name: string, total_months_subscribed: int, is_renewal: bool>, purchase_notification: record<type: int, guild_product_purchase: record>, position: int, resolved: record<users: record, members: record, channels: record, roles: record>, poll: record<question: record, answers: list, expiry: string, allow_multiselect: bool, layout_type: int, results: record>, shared_client_theme: record<colors: list, gradient_angle: int, base_mix: int, base_theme: int>, interaction_metadata: any, message_snapshots: list<record>, reactions: list<record>, referenced_message: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "around" $around "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/channels/($channel_id)/messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /channels/{channel_id}/messages
#
# operationId: create_message
# --embeds item shape: {type?: string, url?: string, title?: string, color?: int, timestamp?: string, description?: string, author?: any, image?: any, thumbnail?: any, footer?: any, fields?: list, provider?: any, video?: any}
# --attachments item shape: {id: string, filename?: string, description?: string, duration_secs?: float, waveform?: string, title?: string, is_remix?: bool}
export def "channels-messages message-by-channel_id" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --content: string # nullable
  --embeds: list # nullable — item shape: {type?: string, url?: string, title?: string, color?: int, timestamp?: string, description?: string, author?: any, image?: any, thumbnail?: any, footer?: any, fields?: list, provider?: any, video?: any}
  --allowed-mentions: any
  --sticker-ids: list # nullable
  --components: list # nullable
  --flags: int # nullable
  --attachments: list # nullable — item shape: {id: string, filename?: string, description?: string, duration_secs?: float, waveform?: string, title?: string, is_remix?: bool}
  --poll: any
  --shared-client-theme: any
  --message-reference: any
  --nonce: any
  --enforce-nonce: oneof<nothing, bool> # nullable
  --tts: oneof<nothing, bool> # nullable
]: any -> record<type: int, content: string, mentions: table<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, mention_roles: list<string>, attachments: table<id: string, filename: string, size: int, url: string, proxy_url: string, width: int, height: int, duration_secs: float, waveform: string, description: string, content_type: string, ephemeral: bool, flags: int, placeholder: string, placeholder_version: int, title: string, application: record, clip_created_at: string, clip_participants: list>, embeds: table<type: string, url: string, title: string, description: string, color: int, timestamp: string, fields: list, author: record, provider: record, image: record, thumbnail: record, video: record, footer: record, flags: int, components: list>, timestamp: string, edited_timestamp: string, flags: int, components: list<any>, stickers: list<any>, sticker_items: table<id: string, name: string, format_type: int>, id: string, channel_id: string, author: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, pinned: bool, mention_everyone: bool, tts: bool, call: record<ended_timestamp: string, participants: list<string>>, activity: record<type: int, party_id: string>, application: record<id: string, name: string, icon: string, description: string, type: any, cover_image: string, primary_sku_id: string, bot: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>>, application_id: string, interaction: record<id: string, type: int, name: string, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, name_localized: string>, nonce: any, webhook_id: string, message_reference: record<type: int, channel_id: string, message_id: string, guild_id: string>, thread: record<id: string, type: int, last_message_id: any, flags: int, last_pin_timestamp: string, guild_id: string, name: string, parent_id: any, rate_limit_per_user: int, bitrate: int, user_limit: int, rtc_region: string, video_quality_mode: int, permissions: string, owner_id: string, thread_metadata: record<archived: bool, archive_timestamp: string, auto_archive_duration: int, locked: bool, create_timestamp: string, invitable: bool>, message_count: int, member_count: int, total_message_sent: int, applied_tags: list<string>, member: record<id: string, user_id: string, join_timestamp: string, flags: int, member: record>>, mention_channels: table<id: string, name: string, type: int, guild_id: string>, role_subscription_data: record<role_subscription_listing_id: string, tier_name: string, total_months_subscribed: int, is_renewal: bool>, purchase_notification: record<type: int, guild_product_purchase: record<listing_id: string, product_name: string>>, position: int, resolved: record<users: record, members: record, channels: record, roles: record>, poll: record<question: record<text: string, emoji: record>, answers: list<record>, expiry: string, allow_multiselect: bool, layout_type: int, results: record<answer_counts: list, is_finalized: bool>>, shared_client_theme: record<colors: list<string>, gradient_angle: int, base_mix: int, base_theme: int>, interaction_metadata: any, message_snapshots: table<message: record>, reactions: table<emoji: record, count: int, count_details: record, burst_colors: list, me_burst: bool, me: bool>, referenced_message: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/channels/($channel_id)/messages")
  let body = {content: $content, embeds: $embeds, allowed_mentions: $allowed_mentions, sticker_ids: $sticker_ids, components: $components, flags: $flags, attachments: $attachments, poll: $poll, shared_client_theme: $shared_client_theme, message_reference: $message_reference, nonce: $nonce, enforce_nonce: $enforce_nonce, tts: $tts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /channels/{channel_id}/messages/bulk-delete
#
# operationId: bulk_delete_messages
export def "channels-messages-bulk-delete messages" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  messages: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/channels/($channel_id)/messages/bulk-delete")
  let body = {messages: $messages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /channels/{channel_id}/messages/pins
#
# operationId: list_pins
export def "channels-messages-pins pins" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # format: date-time
  --limit: int
]: nothing -> record<items: table<pinned_at: string, message: record>, has_more: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/channels/($channel_id)/messages/pins" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /channels/{channel_id}/messages/pins/{message_id}
#
# operationId: create_pin
export def "channels-messages-pins pin-by-channel_id-message_id" [
  channel_id: string
  message_id: string
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
  let full_url = (build-url $base $"/channels/($channel_id)/messages/pins/($message_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /channels/{channel_id}/messages/pins/{message_id}
#
# operationId: delete_pin
export def "channels-messages-pins pin-by-channel_id-message_id-1" [
  channel_id: string
  message_id: string
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
  let full_url = (build-url $base $"/channels/($channel_id)/messages/pins/($message_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /channels/{channel_id}/messages/{message_id}
#
# operationId: get_message
export def "channels-messages message-by-channel_id-message_id" [
  channel_id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: int, content: string, mentions: table<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, mention_roles: list<string>, attachments: table<id: string, filename: string, size: int, url: string, proxy_url: string, width: int, height: int, duration_secs: float, waveform: string, description: string, content_type: string, ephemeral: bool, flags: int, placeholder: string, placeholder_version: int, title: string, application: record, clip_created_at: string, clip_participants: list>, embeds: table<type: string, url: string, title: string, description: string, color: int, timestamp: string, fields: list, author: record, provider: record, image: record, thumbnail: record, video: record, footer: record, flags: int, components: list>, timestamp: string, edited_timestamp: string, flags: int, components: list<any>, stickers: list<any>, sticker_items: table<id: string, name: string, format_type: int>, id: string, channel_id: string, author: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, pinned: bool, mention_everyone: bool, tts: bool, call: record<ended_timestamp: string, participants: list<string>>, activity: record<type: int, party_id: string>, application: record<id: string, name: string, icon: string, description: string, type: any, cover_image: string, primary_sku_id: string, bot: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>>, application_id: string, interaction: record<id: string, type: int, name: string, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, name_localized: string>, nonce: any, webhook_id: string, message_reference: record<type: int, channel_id: string, message_id: string, guild_id: string>, thread: record<id: string, type: int, last_message_id: any, flags: int, last_pin_timestamp: string, guild_id: string, name: string, parent_id: any, rate_limit_per_user: int, bitrate: int, user_limit: int, rtc_region: string, video_quality_mode: int, permissions: string, owner_id: string, thread_metadata: record<archived: bool, archive_timestamp: string, auto_archive_duration: int, locked: bool, create_timestamp: string, invitable: bool>, message_count: int, member_count: int, total_message_sent: int, applied_tags: list<string>, member: record<id: string, user_id: string, join_timestamp: string, flags: int, member: record>>, mention_channels: table<id: string, name: string, type: int, guild_id: string>, role_subscription_data: record<role_subscription_listing_id: string, tier_name: string, total_months_subscribed: int, is_renewal: bool>, purchase_notification: record<type: int, guild_product_purchase: record<listing_id: string, product_name: string>>, position: int, resolved: record<users: record, members: record, channels: record, roles: record>, poll: record<question: record<text: string, emoji: record>, answers: list<record>, expiry: string, allow_multiselect: bool, layout_type: int, results: record<answer_counts: list, is_finalized: bool>>, shared_client_theme: record<colors: list<string>, gradient_angle: int, base_mix: int, base_theme: int>, interaction_metadata: any, message_snapshots: table<message: record>, reactions: table<emoji: record, count: int, count_details: record, burst_colors: list, me_burst: bool, me: bool>, referenced_message: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/channels/($channel_id)/messages/($message_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /channels/{channel_id}/messages/{message_id}
#
# operationId: delete_message
export def "channels-messages message-by-channel_id-message_id-1" [
  channel_id: string
  message_id: string
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
  let full_url = (build-url $base $"/channels/($channel_id)/messages/($message_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /channels/{channel_id}/messages/{message_id}
#
# operationId: update_message
# --embeds item shape: {type?: string, url?: string, title?: string, color?: int, timestamp?: string, description?: string, author?: any, image?: any, thumbnail?: any, footer?: any, fields?: list, provider?: any, video?: any}
# --attachments item shape: {id: string, filename?: string, description?: string, duration_secs?: float, waveform?: string, title?: string, is_remix?: bool}
export def "channels-messages message-by-channel_id-message_id-2" [
  channel_id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --content: string # nullable
  --embeds: list # nullable — item shape: {type?: string, url?: string, title?: string, color?: int, timestamp?: string, description?: string, author?: any, image?: any, thumbnail?: any, footer?: any, fields?: list, provider?: any, video?: any}
  --flags: int # nullable
  --allowed-mentions: any
  --sticker-ids: list # nullable
  --components: list # nullable
  --attachments: list # nullable — item shape: {id: string, filename?: string, description?: string, duration_secs?: float, waveform?: string, title?: string, is_remix?: bool}
]: any -> record<type: int, content: string, mentions: table<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, mention_roles: list<string>, attachments: table<id: string, filename: string, size: int, url: string, proxy_url: string, width: int, height: int, duration_secs: float, waveform: string, description: string, content_type: string, ephemeral: bool, flags: int, placeholder: string, placeholder_version: int, title: string, application: record, clip_created_at: string, clip_participants: list>, embeds: table<type: string, url: string, title: string, description: string, color: int, timestamp: string, fields: list, author: record, provider: record, image: record, thumbnail: record, video: record, footer: record, flags: int, components: list>, timestamp: string, edited_timestamp: string, flags: int, components: list<any>, stickers: list<any>, sticker_items: table<id: string, name: string, format_type: int>, id: string, channel_id: string, author: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, pinned: bool, mention_everyone: bool, tts: bool, call: record<ended_timestamp: string, participants: list<string>>, activity: record<type: int, party_id: string>, application: record<id: string, name: string, icon: string, description: string, type: any, cover_image: string, primary_sku_id: string, bot: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>>, application_id: string, interaction: record<id: string, type: int, name: string, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, name_localized: string>, nonce: any, webhook_id: string, message_reference: record<type: int, channel_id: string, message_id: string, guild_id: string>, thread: record<id: string, type: int, last_message_id: any, flags: int, last_pin_timestamp: string, guild_id: string, name: string, parent_id: any, rate_limit_per_user: int, bitrate: int, user_limit: int, rtc_region: string, video_quality_mode: int, permissions: string, owner_id: string, thread_metadata: record<archived: bool, archive_timestamp: string, auto_archive_duration: int, locked: bool, create_timestamp: string, invitable: bool>, message_count: int, member_count: int, total_message_sent: int, applied_tags: list<string>, member: record<id: string, user_id: string, join_timestamp: string, flags: int, member: record>>, mention_channels: table<id: string, name: string, type: int, guild_id: string>, role_subscription_data: record<role_subscription_listing_id: string, tier_name: string, total_months_subscribed: int, is_renewal: bool>, purchase_notification: record<type: int, guild_product_purchase: record<listing_id: string, product_name: string>>, position: int, resolved: record<users: record, members: record, channels: record, roles: record>, poll: record<question: record<text: string, emoji: record>, answers: list<record>, expiry: string, allow_multiselect: bool, layout_type: int, results: record<answer_counts: list, is_finalized: bool>>, shared_client_theme: record<colors: list<string>, gradient_angle: int, base_mix: int, base_theme: int>, interaction_metadata: any, message_snapshots: table<message: record>, reactions: table<emoji: record, count: int, count_details: record, burst_colors: list, me_burst: bool, me: bool>, referenced_message: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/channels/($channel_id)/messages/($message_id)")
  let body = {content: $content, embeds: $embeds, flags: $flags, allowed_mentions: $allowed_mentions, sticker_ids: $sticker_ids, components: $components, attachments: $attachments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /channels/{channel_id}/messages/{message_id}/crosspost
#
# operationId: crosspost_message
export def "channels-messages-crosspost message" [
  channel_id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: int, content: string, mentions: table<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, mention_roles: list<string>, attachments: table<id: string, filename: string, size: int, url: string, proxy_url: string, width: int, height: int, duration_secs: float, waveform: string, description: string, content_type: string, ephemeral: bool, flags: int, placeholder: string, placeholder_version: int, title: string, application: record, clip_created_at: string, clip_participants: list>, embeds: table<type: string, url: string, title: string, description: string, color: int, timestamp: string, fields: list, author: record, provider: record, image: record, thumbnail: record, video: record, footer: record, flags: int, components: list>, timestamp: string, edited_timestamp: string, flags: int, components: list<any>, stickers: list<any>, sticker_items: table<id: string, name: string, format_type: int>, id: string, channel_id: string, author: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, pinned: bool, mention_everyone: bool, tts: bool, call: record<ended_timestamp: string, participants: list<string>>, activity: record<type: int, party_id: string>, application: record<id: string, name: string, icon: string, description: string, type: any, cover_image: string, primary_sku_id: string, bot: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>>, application_id: string, interaction: record<id: string, type: int, name: string, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, name_localized: string>, nonce: any, webhook_id: string, message_reference: record<type: int, channel_id: string, message_id: string, guild_id: string>, thread: record<id: string, type: int, last_message_id: any, flags: int, last_pin_timestamp: string, guild_id: string, name: string, parent_id: any, rate_limit_per_user: int, bitrate: int, user_limit: int, rtc_region: string, video_quality_mode: int, permissions: string, owner_id: string, thread_metadata: record<archived: bool, archive_timestamp: string, auto_archive_duration: int, locked: bool, create_timestamp: string, invitable: bool>, message_count: int, member_count: int, total_message_sent: int, applied_tags: list<string>, member: record<id: string, user_id: string, join_timestamp: string, flags: int, member: record>>, mention_channels: table<id: string, name: string, type: int, guild_id: string>, role_subscription_data: record<role_subscription_listing_id: string, tier_name: string, total_months_subscribed: int, is_renewal: bool>, purchase_notification: record<type: int, guild_product_purchase: record<listing_id: string, product_name: string>>, position: int, resolved: record<users: record, members: record, channels: record, roles: record>, poll: record<question: record<text: string, emoji: record>, answers: list<record>, expiry: string, allow_multiselect: bool, layout_type: int, results: record<answer_counts: list, is_finalized: bool>>, shared_client_theme: record<colors: list<string>, gradient_angle: int, base_mix: int, base_theme: int>, interaction_metadata: any, message_snapshots: table<message: record>, reactions: table<emoji: record, count: int, count_details: record, burst_colors: list, me_burst: bool, me: bool>, referenced_message: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/channels/($channel_id)/messages/($message_id)/crosspost")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /channels/{channel_id}/messages/{message_id}/reactions
#
# operationId: delete_all_message_reactions
export def "channels-messages-reactions reactions" [
  channel_id: string
  message_id: string
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
  let full_url = (build-url $base $"/channels/($channel_id)/messages/($message_id)/reactions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /channels/{channel_id}/messages/{message_id}/reactions/{emoji_name}
#
# operationId: list_message_reactions_by_emoji
export def "channels-messages-reactions emoji-by-channel_id-message_id-emoji_name" [
  channel_id: string
  message_id: string
  emoji_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string # format: snowflake
  --limit: int
  --type: int # format: int32
]: nothing -> table<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/channels/($channel_id)/messages/($message_id)/reactions/($emoji_name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /channels/{channel_id}/messages/{message_id}/reactions/{emoji_name}
#
# operationId: delete_all_message_reactions_by_emoji
export def "channels-messages-reactions emoji-by-channel_id-message_id-emoji_name-1" [
  channel_id: string
  message_id: string
  emoji_name: string
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
  let full_url = (build-url $base $"/channels/($channel_id)/messages/($message_id)/reactions/($emoji_name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /channels/{channel_id}/messages/{message_id}/reactions/{emoji_name}/@me
#
# operationId: add_my_message_reaction
export def "channels-messages-reactions-me reaction-by-channel_id-message_id-emoji_name" [
  channel_id: string
  message_id: string
  emoji_name: string
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
  let full_url = (build-url $base $"/channels/($channel_id)/messages/($message_id)/reactions/($emoji_name)/@me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /channels/{channel_id}/messages/{message_id}/reactions/{emoji_name}/@me
#
# operationId: delete_my_message_reaction
export def "channels-messages-reactions-me reaction-by-channel_id-message_id-emoji_name-1" [
  channel_id: string
  message_id: string
  emoji_name: string
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
  let full_url = (build-url $base $"/channels/($channel_id)/messages/($message_id)/reactions/($emoji_name)/@me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /channels/{channel_id}/messages/{message_id}/reactions/{emoji_name}/{user_id}
#
# operationId: delete_user_message_reaction
export def "channels-messages-reactions reaction" [
  channel_id: string
  message_id: string
  emoji_name: string
  user_id: string
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
  let full_url = (build-url $base $"/channels/($channel_id)/messages/($message_id)/reactions/($emoji_name)/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /channels/{channel_id}/messages/{message_id}/threads
#
# operationId: create_thread_from_message
export def "channels-messages-threads message" [
  channel_id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --auto-archive-duration: any
  --rate-limit-per-user: int # nullable
]: any -> record<id: string, type: int, last_message_id: any, flags: int, last_pin_timestamp: string, guild_id: string, name: string, parent_id: any, rate_limit_per_user: int, bitrate: int, user_limit: int, rtc_region: string, video_quality_mode: int, permissions: string, owner_id: string, thread_metadata: record<archived: bool, archive_timestamp: string, auto_archive_duration: int, locked: bool, create_timestamp: string, invitable: bool>, message_count: int, member_count: int, total_message_sent: int, applied_tags: list<string>, member: record<id: string, user_id: string, join_timestamp: string, flags: int, member: record<avatar: string, avatar_decoration_data: any, banner: string, communication_disabled_until: string, flags: int, joined_at: string, nick: string, pending: bool, premium_since: string, roles: list, collectibles: any, user: record, mute: bool, deaf: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/channels/($channel_id)/messages/($message_id)/threads")
  let body = {name: $name, auto_archive_duration: $auto_archive_duration, rate_limit_per_user: $rate_limit_per_user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /channels/{channel_id}/permissions/{overwrite_id}
#
# operationId: set_channel_permission_overwrite
export def "channels-permissions overwrite-by-channel_id-overwrite_id" [
  channel_id: string
  overwrite_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: any
  --allow: int # nullable
  --deny: int # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/channels/($channel_id)/permissions/($overwrite_id)")
  let body = {type: $type, allow: $allow, deny: $deny} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /channels/{channel_id}/permissions/{overwrite_id}
#
# operationId: delete_channel_permission_overwrite
export def "channels-permissions overwrite-by-channel_id-overwrite_id-1" [
  channel_id: string
  overwrite_id: string
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
  let full_url = (build-url $base $"/channels/($channel_id)/permissions/($overwrite_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /channels/{channel_id}/pins
#
# operationId: deprecated_list_pins
export def "channels-pins pins" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<type: int, content: string, mentions: list<record>, mention_roles: list<string>, attachments: list<record>, embeds: list<record>, timestamp: string, edited_timestamp: string, flags: int, components: list<any>, stickers: list<any>, sticker_items: list<record>, id: string, channel_id: string, author: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, pinned: bool, mention_everyone: bool, tts: bool, call: record<ended_timestamp: string, participants: list>, activity: record<type: int, party_id: string>, application: record<id: string, name: string, icon: string, description: string, type: any, cover_image: string, primary_sku_id: string, bot: record>, application_id: string, interaction: record<id: string, type: int, name: string, user: record, name_localized: string>, nonce: any, webhook_id: string, message_reference: record<type: int, channel_id: string, message_id: string, guild_id: string>, thread: record<id: string, type: int, last_message_id: any, flags: int, last_pin_timestamp: string, guild_id: string, name: string, parent_id: any, rate_limit_per_user: int, bitrate: int, user_limit: int, rtc_region: string, video_quality_mode: int, permissions: string, owner_id: string, thread_metadata: record, message_count: int, member_count: int, total_message_sent: int, applied_tags: list, member: record>, mention_channels: list<record>, role_subscription_data: record<role_subscription_listing_id: string, tier_name: string, total_months_subscribed: int, is_renewal: bool>, purchase_notification: record<type: int, guild_product_purchase: record>, position: int, resolved: record<users: record, members: record, channels: record, roles: record>, poll: record<question: record, answers: list, expiry: string, allow_multiselect: bool, layout_type: int, results: record>, shared_client_theme: record<colors: list, gradient_angle: int, base_mix: int, base_theme: int>, interaction_metadata: any, message_snapshots: list<record>, reactions: list<record>, referenced_message: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/channels/($channel_id)/pins")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /channels/{channel_id}/pins/{message_id}
#
# operationId: deprecated_create_pin
export def "channels-pins pin-by-channel_id-message_id" [
  channel_id: string
  message_id: string
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
  let full_url = (build-url $base $"/channels/($channel_id)/pins/($message_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /channels/{channel_id}/pins/{message_id}
#
# operationId: deprecated_delete_pin
export def "channels-pins pin-by-channel_id-message_id-1" [
  channel_id: string
  message_id: string
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
  let full_url = (build-url $base $"/channels/($channel_id)/pins/($message_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /channels/{channel_id}/polls/{message_id}/answers/{answer_id}
#
# operationId: get_answer_voters
export def "channels-polls-answers voters" [
  channel_id: string
  message_id: string
  answer_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string # format: snowflake
  --limit: int
]: nothing -> record<users: table<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/channels/($channel_id)/polls/($message_id)/answers/($answer_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /channels/{channel_id}/polls/{message_id}/expire
#
# operationId: poll_expire
export def "channels-polls-expire expire" [
  channel_id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<type: int, content: string, mentions: table<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, mention_roles: list<string>, attachments: table<id: string, filename: string, size: int, url: string, proxy_url: string, width: int, height: int, duration_secs: float, waveform: string, description: string, content_type: string, ephemeral: bool, flags: int, placeholder: string, placeholder_version: int, title: string, application: record, clip_created_at: string, clip_participants: list>, embeds: table<type: string, url: string, title: string, description: string, color: int, timestamp: string, fields: list, author: record, provider: record, image: record, thumbnail: record, video: record, footer: record, flags: int, components: list>, timestamp: string, edited_timestamp: string, flags: int, components: list<any>, stickers: list<any>, sticker_items: table<id: string, name: string, format_type: int>, id: string, channel_id: string, author: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, pinned: bool, mention_everyone: bool, tts: bool, call: record<ended_timestamp: string, participants: list<string>>, activity: record<type: int, party_id: string>, application: record<id: string, name: string, icon: string, description: string, type: any, cover_image: string, primary_sku_id: string, bot: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>>, application_id: string, interaction: record<id: string, type: int, name: string, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, name_localized: string>, nonce: any, webhook_id: string, message_reference: record<type: int, channel_id: string, message_id: string, guild_id: string>, thread: record<id: string, type: int, last_message_id: any, flags: int, last_pin_timestamp: string, guild_id: string, name: string, parent_id: any, rate_limit_per_user: int, bitrate: int, user_limit: int, rtc_region: string, video_quality_mode: int, permissions: string, owner_id: string, thread_metadata: record<archived: bool, archive_timestamp: string, auto_archive_duration: int, locked: bool, create_timestamp: string, invitable: bool>, message_count: int, member_count: int, total_message_sent: int, applied_tags: list<string>, member: record<id: string, user_id: string, join_timestamp: string, flags: int, member: record>>, mention_channels: table<id: string, name: string, type: int, guild_id: string>, role_subscription_data: record<role_subscription_listing_id: string, tier_name: string, total_months_subscribed: int, is_renewal: bool>, purchase_notification: record<type: int, guild_product_purchase: record<listing_id: string, product_name: string>>, position: int, resolved: record<users: record, members: record, channels: record, roles: record>, poll: record<question: record<text: string, emoji: record>, answers: list<record>, expiry: string, allow_multiselect: bool, layout_type: int, results: record<answer_counts: list, is_finalized: bool>>, shared_client_theme: record<colors: list<string>, gradient_angle: int, base_mix: int, base_theme: int>, interaction_metadata: any, message_snapshots: table<message: record>, reactions: table<emoji: record, count: int, count_details: record, burst_colors: list, me_burst: bool, me: bool>, referenced_message: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/channels/($channel_id)/polls/($message_id)/expire")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /channels/{channel_id}/recipients/{user_id}
#
# operationId: add_group_dm_user
export def "channels-recipients user-by-channel_id-user_id" [
  channel_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --access-token: string # nullable
  --nick: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/channels/($channel_id)/recipients/($user_id)")
  let body = {access_token: $access_token, nick: $nick} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /channels/{channel_id}/recipients/{user_id}
#
# operationId: delete_group_dm_user
export def "channels-recipients user-by-channel_id-user_id-1" [
  channel_id: string
  user_id: string
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
  let full_url = (build-url $base $"/channels/($channel_id)/recipients/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /channels/{channel_id}/send-soundboard-sound
#
# operationId: send_soundboard_sound
export def "channels-send-soundboard-sound sound" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sound_id: string # format: snowflake
  --source-guild-id: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/channels/($channel_id)/send-soundboard-sound")
  let body = {sound_id: $sound_id, source_guild_id: $source_guild_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /channels/{channel_id}/thread-members
#
# operationId: list_thread_members
export def "channels-thread-members members" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --with-member: oneof<nothing, bool>
  --limit: int
  --after: string # format: snowflake
]: nothing -> table<id: string, user_id: string, join_timestamp: string, flags: int, member: record<avatar: string, avatar_decoration_data: any, banner: string, communication_disabled_until: string, flags: int, joined_at: string, nick: string, pending: bool, premium_since: string, roles: list, collectibles: any, user: record, mute: bool, deaf: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_member" $with_member "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/channels/($channel_id)/thread-members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /channels/{channel_id}/thread-members/@me
#
# operationId: join_thread
export def "channels-thread-members-me thread-by-channel_id" [
  channel_id: string
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
  let full_url = (build-url $base $"/channels/($channel_id)/thread-members/@me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /channels/{channel_id}/thread-members/@me
#
# operationId: leave_thread
export def "channels-thread-members-me thread-by-channel_id-1" [
  channel_id: string
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
  let full_url = (build-url $base $"/channels/($channel_id)/thread-members/@me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /channels/{channel_id}/thread-members/{user_id}
#
# operationId: get_thread_member
export def "channels-thread-members member-by-channel_id-user_id" [
  channel_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --with-member: oneof<nothing, bool>
]: nothing -> record<id: string, user_id: string, join_timestamp: string, flags: int, member: record<avatar: string, avatar_decoration_data: any, banner: string, communication_disabled_until: string, flags: int, joined_at: string, nick: string, pending: bool, premium_since: string, roles: list<string>, collectibles: any, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, mute: bool, deaf: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_member" $with_member "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/channels/($channel_id)/thread-members/($user_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /channels/{channel_id}/thread-members/{user_id}
#
# operationId: add_thread_member
export def "channels-thread-members member-by-channel_id-user_id-1" [
  channel_id: string
  user_id: string
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
  let full_url = (build-url $base $"/channels/($channel_id)/thread-members/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /channels/{channel_id}/thread-members/{user_id}
#
# operationId: delete_thread_member
export def "channels-thread-members member-by-channel_id-user_id-2" [
  channel_id: string
  user_id: string
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
  let full_url = (build-url $base $"/channels/($channel_id)/thread-members/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /channels/{channel_id}/threads
#
# operationId: create_thread
# --message shape: {content?: string, embeds?: list, allowed_mentions?: any, sticker_ids?: list, components?: list, flags?: int, attachments?: list, poll?: any, shared_client_theme?: any}
export def "channels-threads thread" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --auto-archive-duration: any
  --rate-limit-per-user: int # nullable
  --applied-tags: list # nullable
  --message: record # shape: {content?: string, embeds?: list, allowed_mentions?: any, sticker_ids?: list, components?: list, flags?: int, attachments?: list, poll?: any, shared_client_theme?: any}
  --type: any
  --invitable: oneof<nothing, bool> # nullable
]: any -> record<id: string, type: int, last_message_id: any, flags: int, last_pin_timestamp: string, guild_id: string, name: string, parent_id: any, rate_limit_per_user: int, bitrate: int, user_limit: int, rtc_region: string, video_quality_mode: int, permissions: string, owner_id: string, thread_metadata: record<archived: bool, archive_timestamp: string, auto_archive_duration: int, locked: bool, create_timestamp: string, invitable: bool>, message_count: int, member_count: int, total_message_sent: int, applied_tags: list<string>, member: record<id: string, user_id: string, join_timestamp: string, flags: int, member: record<avatar: string, avatar_decoration_data: any, banner: string, communication_disabled_until: string, flags: int, joined_at: string, nick: string, pending: bool, premium_since: string, roles: list, collectibles: any, user: record, mute: bool, deaf: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/channels/($channel_id)/threads")
  let body = {name: $name, auto_archive_duration: $auto_archive_duration, rate_limit_per_user: $rate_limit_per_user, applied_tags: $applied_tags, message: $message, type: $type, invitable: $invitable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /channels/{channel_id}/threads/archived/private
#
# operationId: list_private_archived_threads
export def "channels-threads-archived-private threads" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # format: date-time
  --limit: int
]: nothing -> record<threads: table<id: string, type: int, last_message_id: any, flags: int, last_pin_timestamp: string, guild_id: string, name: string, parent_id: any, rate_limit_per_user: int, bitrate: int, user_limit: int, rtc_region: string, video_quality_mode: int, permissions: string, owner_id: string, thread_metadata: record, message_count: int, member_count: int, total_message_sent: int, applied_tags: list, member: record>, members: table<id: string, user_id: string, join_timestamp: string, flags: int, member: record>, has_more: bool, first_messages: table<type: int, content: string, mentions: list, mention_roles: list, attachments: list, embeds: list, timestamp: string, edited_timestamp: string, flags: int, components: list, stickers: list, sticker_items: list, id: string, channel_id: string, author: record, pinned: bool, mention_everyone: bool, tts: bool, call: record, activity: record, application: record, application_id: string, interaction: record, nonce: any, webhook_id: string, message_reference: record, thread: record, mention_channels: list, role_subscription_data: record, purchase_notification: record, position: int, resolved: record, poll: record, shared_client_theme: record, interaction_metadata: any, message_snapshots: list, reactions: list, referenced_message: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/channels/($channel_id)/threads/archived/private" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /channels/{channel_id}/threads/archived/public
#
# operationId: list_public_archived_threads
export def "channels-threads-archived-public threads" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # format: date-time
  --limit: int
]: nothing -> record<threads: table<id: string, type: int, last_message_id: any, flags: int, last_pin_timestamp: string, guild_id: string, name: string, parent_id: any, rate_limit_per_user: int, bitrate: int, user_limit: int, rtc_region: string, video_quality_mode: int, permissions: string, owner_id: string, thread_metadata: record, message_count: int, member_count: int, total_message_sent: int, applied_tags: list, member: record>, members: table<id: string, user_id: string, join_timestamp: string, flags: int, member: record>, has_more: bool, first_messages: table<type: int, content: string, mentions: list, mention_roles: list, attachments: list, embeds: list, timestamp: string, edited_timestamp: string, flags: int, components: list, stickers: list, sticker_items: list, id: string, channel_id: string, author: record, pinned: bool, mention_everyone: bool, tts: bool, call: record, activity: record, application: record, application_id: string, interaction: record, nonce: any, webhook_id: string, message_reference: record, thread: record, mention_channels: list, role_subscription_data: record, purchase_notification: record, position: int, resolved: record, poll: record, shared_client_theme: record, interaction_metadata: any, message_snapshots: list, reactions: list, referenced_message: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/channels/($channel_id)/threads/archived/public" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /channels/{channel_id}/threads/search
#
# operationId: thread_search
export def "channels-threads-search search" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --slop: int
  --min-id: string # format: snowflake
  --max-id: string # format: snowflake
  --tag: string
  --tag-setting: string
  --archived: oneof<nothing, bool>
  --sort-by: string
  --sort-order: string
  --limit: int
  --offset: int
]: nothing -> record<threads: table<id: string, type: int, last_message_id: any, flags: int, last_pin_timestamp: string, guild_id: string, name: string, parent_id: any, rate_limit_per_user: int, bitrate: int, user_limit: int, rtc_region: string, video_quality_mode: int, permissions: string, owner_id: string, thread_metadata: record, message_count: int, member_count: int, total_message_sent: int, applied_tags: list, member: record>, members: table<id: string, user_id: string, join_timestamp: string, flags: int, member: record>, has_more: bool, first_messages: table<type: int, content: string, mentions: list, mention_roles: list, attachments: list, embeds: list, timestamp: string, edited_timestamp: string, flags: int, components: list, stickers: list, sticker_items: list, id: string, channel_id: string, author: record, pinned: bool, mention_everyone: bool, tts: bool, call: record, activity: record, application: record, application_id: string, interaction: record, nonce: any, webhook_id: string, message_reference: record, thread: record, mention_channels: list, role_subscription_data: record, purchase_notification: record, position: int, resolved: record, poll: record, shared_client_theme: record, interaction_metadata: any, message_snapshots: list, reactions: list, referenced_message: any>, total_results: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "slop" $slop "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "tag" $tag "scalar") (serialize-qp "tag_setting" $tag_setting "scalar") (serialize-qp "archived" $archived "scalar") (serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/channels/($channel_id)/threads/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /channels/{channel_id}/typing
#
# operationId: trigger_typing_indicator
export def "channels-typing indicator" [
  channel_id: string
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
  let full_url = (build-url $base $"/channels/($channel_id)/typing")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /channels/{channel_id}/users/@me/threads/archived/private
#
# operationId: list_my_private_archived_threads
export def "channels-users-me-threads-archived-private threads" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # format: snowflake
  --limit: int
]: nothing -> record<threads: table<id: string, type: int, last_message_id: any, flags: int, last_pin_timestamp: string, guild_id: string, name: string, parent_id: any, rate_limit_per_user: int, bitrate: int, user_limit: int, rtc_region: string, video_quality_mode: int, permissions: string, owner_id: string, thread_metadata: record, message_count: int, member_count: int, total_message_sent: int, applied_tags: list, member: record>, members: table<id: string, user_id: string, join_timestamp: string, flags: int, member: record>, has_more: bool, first_messages: table<type: int, content: string, mentions: list, mention_roles: list, attachments: list, embeds: list, timestamp: string, edited_timestamp: string, flags: int, components: list, stickers: list, sticker_items: list, id: string, channel_id: string, author: record, pinned: bool, mention_everyone: bool, tts: bool, call: record, activity: record, application: record, application_id: string, interaction: record, nonce: any, webhook_id: string, message_reference: record, thread: record, mention_channels: list, role_subscription_data: record, purchase_notification: record, position: int, resolved: record, poll: record, shared_client_theme: record, interaction_metadata: any, message_snapshots: list, reactions: list, referenced_message: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/channels/($channel_id)/users/@me/threads/archived/private" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set a voice channel's status.
#
# PUT /channels/{channel_id}/voice-status
# operationId: update_voice_channel_status
export def "channels-voice-status status" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string # The new voice channel status (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/channels/($channel_id)/voice-status")
  let body = {status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /channels/{channel_id}/webhooks
#
# operationId: list_channel_webhooks
export def "channels-webhooks webhooks" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/channels/($channel_id)/webhooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /channels/{channel_id}/webhooks
#
# operationId: create_webhook
export def "channels-webhooks webhook" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --avatar: string # nullable
]: any -> record<application_id: any, avatar: string, channel_id: any, guild_id: any, id: string, name: string, type: int, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, token: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/channels/($channel_id)/webhooks")
  let body = {name: $name, avatar: $avatar} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /gateway
#
# operationId: get_gateway
export def "gateway gateway" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/gateway")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /gateway/bot
#
# operationId: get_bot_gateway
export def "gateway-bot gateway" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<url: string, session_start_limit: record<max_concurrency: int, remaining: int, reset_after: int, total: int>, shards: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/gateway/bot")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /guilds/templates/{code}
#
# operationId: get_guild_template
export def "guilds-templates template-by-code" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, name: string, description: string, usage_count: int, creator_id: string, creator: any, created_at: string, updated_at: string, source_guild_id: string, serialized_source_guild: record<name: string, description: string, region: string, verification_level: int, default_message_notifications: int, explicit_content_filter: int, preferred_locale: string, afk_channel_id: any, afk_timeout: int, system_channel_id: any, system_channel_flags: int, roles: list<record>, channels: list<record>>, is_dirty: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/templates/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /guilds/{guild_id}
#
# operationId: get_guild
export def "guilds guild-by-guild_id" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --with-counts: oneof<nothing, bool>
]: nothing -> record<id: string, name: string, icon: string, description: string, home_header: string, splash: string, discovery_splash: string, features: list<string>, banner: string, owner_id: string, application_id: any, region: string, afk_channel_id: any, afk_timeout: int, system_channel_id: any, system_channel_flags: int, widget_enabled: bool, widget_channel_id: any, verification_level: int, roles: table<id: string, name: string, permissions: string, position: int, color: int, colors: record, hoist: bool, managed: bool, mentionable: bool, icon: string, unicode_emoji: string, tags: record, flags: int>, default_message_notifications: int, mfa_level: int, explicit_content_filter: int, max_presences: int, max_members: int, max_stage_video_channel_users: int, max_video_channel_users: int, vanity_url_code: string, premium_tier: int, premium_subscription_count: int, preferred_locale: string, rules_channel_id: any, safety_alerts_channel_id: any, public_updates_channel_id: any, premium_progress_bar_enabled: bool, premium_progress_bar_enabled_user_updated_at: string, nsfw: bool, nsfw_level: int, emojis: table<id: string, name: string, user: record, roles: list, require_colons: bool, managed: bool, animated: bool, available: bool>, stickers: table<id: string, name: string, tags: string, type: int, format_type: any, description: string, available: bool, guild_id: string, user: record>, incidents_data: any, approximate_member_count: int, approximate_presence_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_counts" $with_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/guilds/($guild_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /guilds/{guild_id}
#
# operationId: update_guild
export def "guilds guild-by-guild_id-1" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --description: string # nullable
  --region: string # nullable
  --icon: string # nullable
  --verification-level: any
  --default-message-notifications: any
  --explicit-content-filter: any
  --preferred-locale: any
  --afk-timeout: any
  --afk-channel-id: any
  --system-channel-id: any
  --splash: string # nullable
  --banner: string # nullable
  --system-channel-flags: int # nullable
  --features: list # nullable
  --discovery-splash: string # nullable
  --home-header: string # nullable
  --rules-channel-id: any
  --safety-alerts-channel-id: any
  --public-updates-channel-id: any
  --premium-progress-bar-enabled: oneof<nothing, bool> # nullable
]: any -> record<id: string, name: string, icon: string, description: string, home_header: string, splash: string, discovery_splash: string, features: list<string>, banner: string, owner_id: string, application_id: any, region: string, afk_channel_id: any, afk_timeout: int, system_channel_id: any, system_channel_flags: int, widget_enabled: bool, widget_channel_id: any, verification_level: int, roles: table<id: string, name: string, permissions: string, position: int, color: int, colors: record, hoist: bool, managed: bool, mentionable: bool, icon: string, unicode_emoji: string, tags: record, flags: int>, default_message_notifications: int, mfa_level: int, explicit_content_filter: int, max_presences: int, max_members: int, max_stage_video_channel_users: int, max_video_channel_users: int, vanity_url_code: string, premium_tier: int, premium_subscription_count: int, preferred_locale: string, rules_channel_id: any, safety_alerts_channel_id: any, public_updates_channel_id: any, premium_progress_bar_enabled: bool, premium_progress_bar_enabled_user_updated_at: string, nsfw: bool, nsfw_level: int, emojis: table<id: string, name: string, user: record, roles: list, require_colons: bool, managed: bool, animated: bool, available: bool>, stickers: table<id: string, name: string, tags: string, type: int, format_type: any, description: string, available: bool, guild_id: string, user: record>, incidents_data: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)")
  let body = {name: $name, description: $description, region: $region, icon: $icon, verification_level: $verification_level, default_message_notifications: $default_message_notifications, explicit_content_filter: $explicit_content_filter, preferred_locale: $preferred_locale, afk_timeout: $afk_timeout, afk_channel_id: $afk_channel_id, system_channel_id: $system_channel_id, splash: $splash, banner: $banner, system_channel_flags: $system_channel_flags, features: $features, discovery_splash: $discovery_splash, home_header: $home_header, rules_channel_id: $rules_channel_id, safety_alerts_channel_id: $safety_alerts_channel_id, public_updates_channel_id: $public_updates_channel_id, premium_progress_bar_enabled: $premium_progress_bar_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /guilds/{guild_id}/audit-logs
#
# operationId: list_guild_audit_log_entries
export def "guilds-audit-logs entries" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --user-id: string # format: snowflake
  --target-id: string # format: snowflake
  --action-type: int # format: int32
  --before: string # format: snowflake
  --after: string # format: snowflake
  --limit: int
]: nothing -> record<audit_log_entries: table<id: string, action_type: int, user_id: any, target_id: any, changes: list, options: record, reason: string>, users: table<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, integrations: list<any>, webhooks: list<any>, guild_scheduled_events: list<any>, threads: table<id: string, type: int, last_message_id: any, flags: int, last_pin_timestamp: string, guild_id: string, name: string, parent_id: any, rate_limit_per_user: int, bitrate: int, user_limit: int, rtc_region: string, video_quality_mode: int, permissions: string, owner_id: string, thread_metadata: record, message_count: int, member_count: int, total_message_sent: int, applied_tags: list, member: record>, application_commands: table<id: string, application_id: string, version: string, default_member_permissions: string, type: int, name: string, name_localized: string, name_localizations: record, description: string, description_localized: string, description_localizations: record, guild_id: string, dm_permission: bool, contexts: list, integration_types: list, options: list, nsfw: bool, handler: int>, auto_moderation_rules: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar") (serialize-qp "target_id" $target_id "scalar") (serialize-qp "action_type" $action_type "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/guilds/($guild_id)/audit-logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /guilds/{guild_id}/auto-moderation/rules
#
# operationId: list_auto_moderation_rules
export def "guilds-auto-moderation-rules rules" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/auto-moderation/rules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /guilds/{guild_id}/auto-moderation/rules
#
# operationId: create_auto_moderation_rule
# --trigger_metadata shape: {allow_list?: list, presets?: list}
export def "guilds-auto-moderation-rules rule-by-guild_id" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --event-type: int # format: int32
  --actions: list # nullable
  --enabled: oneof<nothing, bool> # nullable
  --exempt-roles: list # nullable
  --exempt-channels: list # nullable
  --trigger-type: int@trigger-type-completer # format: int32
  --trigger-metadata: record # shape: {allow_list?: list, presets?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/auto-moderation/rules")
  let body = {name: $name, event_type: $event_type, actions: $actions, enabled: $enabled, exempt_roles: $exempt_roles, exempt_channels: $exempt_channels, trigger_type: $trigger_type, trigger_metadata: $trigger_metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /guilds/{guild_id}/auto-moderation/rules/{rule_id}
#
# operationId: get_auto_moderation_rule
export def "guilds-auto-moderation-rules rule-by-guild_id-rule_id" [
  guild_id: string
  rule_id: string
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
  let full_url = (build-url $base $"/guilds/($guild_id)/auto-moderation/rules/($rule_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /guilds/{guild_id}/auto-moderation/rules/{rule_id}
#
# operationId: delete_auto_moderation_rule
export def "guilds-auto-moderation-rules rule-by-guild_id-rule_id-1" [
  guild_id: string
  rule_id: string
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
  let full_url = (build-url $base $"/guilds/($guild_id)/auto-moderation/rules/($rule_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /guilds/{guild_id}/auto-moderation/rules/{rule_id}
#
# operationId: update_auto_moderation_rule
# --trigger_metadata shape: {allow_list?: list, presets?: list}
export def "guilds-auto-moderation-rules rule-by-guild_id-rule_id-2" [
  guild_id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --event-type: int # format: int32
  --actions: list # nullable
  --enabled: oneof<nothing, bool> # nullable
  --exempt-roles: list # nullable
  --exempt-channels: list # nullable
  --trigger-type: int@trigger-type-completer # format: int32
  --trigger-metadata: record # shape: {allow_list?: list, presets?: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/auto-moderation/rules/($rule_id)")
  let body = {name: $name, event_type: $event_type, actions: $actions, enabled: $enabled, exempt_roles: $exempt_roles, exempt_channels: $exempt_channels, trigger_type: $trigger_type, trigger_metadata: $trigger_metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /guilds/{guild_id}/bans
#
# operationId: list_guild_bans
export def "guilds-bans bans" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int
  --before: string # format: snowflake
  --after: string # format: snowflake
]: nothing -> table<user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/guilds/($guild_id)/bans" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /guilds/{guild_id}/bans/{user_id}
#
# operationId: get_guild_ban
export def "guilds-bans ban" [
  guild_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, reason: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/bans/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /guilds/{guild_id}/bans/{user_id}
#
# operationId: ban_user_from_guild
export def "guilds-bans guild-by-guild_id-user_id" [
  guild_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --delete-message-seconds: int # nullable
  --delete-message-days: int # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/bans/($user_id)")
  let body = {delete_message_seconds: $delete_message_seconds, delete_message_days: $delete_message_days} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /guilds/{guild_id}/bans/{user_id}
#
# operationId: unban_user_from_guild
export def "guilds-bans guild-by-guild_id-user_id-1" [
  guild_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/bans/($user_id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /guilds/{guild_id}/bulk-ban
#
# operationId: bulk_ban_users_from_guild
export def "guilds-bulk-ban guild" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user_ids: list
  --delete-message-seconds: int # nullable
]: any -> record<banned_users: list<string>, failed_users: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/bulk-ban")
  let body = {user_ids: $user_ids, delete_message_seconds: $delete_message_seconds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /guilds/{guild_id}/channels
#
# operationId: list_guild_channels
export def "guilds-channels channels-by-guild_id" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/channels")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /guilds/{guild_id}/channels
#
# operationId: create_guild_channel
# --permission_overwrites item shape: {id: string, type?: any, allow?: int, deny?: int}
export def "guilds-channels channel" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: any
  name: string
  --position: int # nullable, format: int32
  --topic: string # nullable
  --bitrate: int # nullable, format: int32
  --user-limit: int # nullable, format: int32
  --nsfw: oneof<nothing, bool> # nullable
  --rate-limit-per-user: int # nullable
  --parent-id: any
  --permission-overwrites: list # nullable — item shape: {id: string, type?: any, allow?: int, deny?: int}
  --rtc-region: string # nullable
  --video-quality-mode: any
  --default-auto-archive-duration: any
  --default-reaction-emoji: any
  --default-thread-rate-limit-per-user: int # nullable
  --default-sort-order: any
  --default-forum-layout: any
  --default-tag-setting: any
  --available-tags: list # nullable
]: any -> record<id: string, type: int, last_message_id: any, flags: int, last_pin_timestamp: string, guild_id: string, name: string, parent_id: any, rate_limit_per_user: int, bitrate: int, user_limit: int, rtc_region: string, video_quality_mode: int, permissions: string, topic: string, default_auto_archive_duration: int, default_thread_rate_limit_per_user: int, position: int, permission_overwrites: table<id: string, type: int, allow: string, deny: string>, nsfw: bool, available_tags: table<id: string, name: string, moderated: bool, emoji_id: any, emoji_name: string>, default_reaction_emoji: any, default_sort_order: any, default_forum_layout: int, default_tag_setting: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/channels")
  let body = {type: $type, name: $name, position: $position, topic: $topic, bitrate: $bitrate, user_limit: $user_limit, nsfw: $nsfw, rate_limit_per_user: $rate_limit_per_user, parent_id: $parent_id, permission_overwrites: $permission_overwrites, rtc_region: $rtc_region, video_quality_mode: $video_quality_mode, default_auto_archive_duration: $default_auto_archive_duration, default_reaction_emoji: $default_reaction_emoji, default_thread_rate_limit_per_user: $default_thread_rate_limit_per_user, default_sort_order: $default_sort_order, default_forum_layout: $default_forum_layout, default_tag_setting: $default_tag_setting, available_tags: $available_tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PATCH /guilds/{guild_id}/channels
#
# operationId: bulk_update_guild_channels
export def "guilds-channels channels-by-guild_id-1" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/channels")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /guilds/{guild_id}/emojis
#
# operationId: list_guild_emojis
export def "guilds-emojis emojis" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, name: string, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, roles: list<string>, require_colons: bool, managed: bool, animated: bool, available: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/emojis")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /guilds/{guild_id}/emojis
#
# operationId: create_guild_emoji
export def "guilds-emojis emoji-by-guild_id" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  image: string
  --roles: list # nullable
]: any -> record<id: string, name: string, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, roles: list<string>, require_colons: bool, managed: bool, animated: bool, available: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/emojis")
  let body = {name: $name, image: $image, roles: $roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /guilds/{guild_id}/emojis/{emoji_id}
#
# operationId: get_guild_emoji
export def "guilds-emojis emoji-by-guild_id-emoji_id" [
  guild_id: string
  emoji_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, roles: list<string>, require_colons: bool, managed: bool, animated: bool, available: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/emojis/($emoji_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /guilds/{guild_id}/emojis/{emoji_id}
#
# operationId: delete_guild_emoji
export def "guilds-emojis emoji-by-guild_id-emoji_id-1" [
  guild_id: string
  emoji_id: string
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
  let full_url = (build-url $base $"/guilds/($guild_id)/emojis/($emoji_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /guilds/{guild_id}/emojis/{emoji_id}
#
# operationId: update_guild_emoji
export def "guilds-emojis emoji-by-guild_id-emoji_id-2" [
  guild_id: string
  emoji_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --roles: list # nullable
]: any -> record<id: string, name: string, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, roles: list<string>, require_colons: bool, managed: bool, animated: bool, available: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/emojis/($emoji_id)")
  let body = {name: $name, roles: $roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Modifies the incident actions of the guild
#
# PUT /guilds/{guild_id}/incident-actions
# operationId: update_guild_incident_actions
export def "guilds-incident-actions actions" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --invites-disabled-until: string # When invites will be enabled again (nullable, format: date-time)
  --dms-disabled-until: string # When direct messages will be enabled again (nullable, format: date-time)
]: any -> record<invites_disabled_until: string, dms_disabled_until: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/incident-actions")
  let body = {invites_disabled_until: $invites_disabled_until, dms_disabled_until: $dms_disabled_until} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /guilds/{guild_id}/integrations
#
# operationId: list_guild_integrations
export def "guilds-integrations integrations" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/integrations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /guilds/{guild_id}/integrations/{integration_id}
#
# operationId: delete_guild_integration
export def "guilds-integrations integration" [
  guild_id: string
  integration_id: string
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
  let full_url = (build-url $base $"/guilds/($guild_id)/integrations/($integration_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /guilds/{guild_id}/invites
#
# operationId: list_guild_invites
export def "guilds-invites invites" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/invites")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /guilds/{guild_id}/members
#
# operationId: list_guild_members
export def "guilds-members members" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int
  --after: int
]: nothing -> table<avatar: string, avatar_decoration_data: any, banner: string, communication_disabled_until: string, flags: int, joined_at: string, nick: string, pending: bool, premium_since: string, roles: list<string>, collectibles: any, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, mute: bool, deaf: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/guilds/($guild_id)/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /guilds/{guild_id}/members/@me
#
# operationId: update_my_guild_member
export def "guilds-members-me member" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --nick: string # nullable
  --avatar: string # nullable
  --bio: string # nullable
  --banner: string # nullable
]: any -> record<avatar: string, avatar_decoration_data: any, banner: string, communication_disabled_until: string, flags: int, joined_at: string, nick: string, pending: bool, premium_since: string, roles: list<string>, collectibles: any, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, mute: bool, deaf: bool, permissions: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/members/@me")
  let body = {nick: $nick, avatar: $avatar, bio: $bio, banner: $banner} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /guilds/{guild_id}/members/search
#
# operationId: search_guild_members
export def "guilds-members-search members" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int
  --qp-query: string
]: nothing -> table<avatar: string, avatar_decoration_data: any, banner: string, communication_disabled_until: string, flags: int, joined_at: string, nick: string, pending: bool, premium_since: string, roles: list<string>, collectibles: any, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, mute: bool, deaf: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/guilds/($guild_id)/members/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /guilds/{guild_id}/members/{user_id}
#
# operationId: get_guild_member
export def "guilds-members member-by-guild_id-user_id" [
  guild_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<avatar: string, avatar_decoration_data: any, banner: string, communication_disabled_until: string, flags: int, joined_at: string, nick: string, pending: bool, premium_since: string, roles: list<string>, collectibles: any, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, mute: bool, deaf: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/members/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /guilds/{guild_id}/members/{user_id}
#
# operationId: add_guild_member
export def "guilds-members member-by-guild_id-user_id-1" [
  guild_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --nick: string # nullable
  --roles: list # nullable
  --mute: oneof<nothing, bool> # nullable
  --deaf: oneof<nothing, bool> # nullable
  access_token: string
  --flags: int # nullable
]: any -> record<avatar: string, avatar_decoration_data: any, banner: string, communication_disabled_until: string, flags: int, joined_at: string, nick: string, pending: bool, premium_since: string, roles: list<string>, collectibles: any, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, mute: bool, deaf: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/members/($user_id)")
  let body = {nick: $nick, roles: $roles, mute: $mute, deaf: $deaf, access_token: $access_token, flags: $flags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /guilds/{guild_id}/members/{user_id}
#
# operationId: delete_guild_member
export def "guilds-members member-by-guild_id-user_id-2" [
  guild_id: string
  user_id: string
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
  let full_url = (build-url $base $"/guilds/($guild_id)/members/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /guilds/{guild_id}/members/{user_id}
#
# operationId: update_guild_member
export def "guilds-members member-by-guild_id-user_id-3" [
  guild_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --nick: string # nullable
  --roles: list # nullable
  --mute: oneof<nothing, bool> # nullable
  --deaf: oneof<nothing, bool> # nullable
  --channel-id: any
  --communication-disabled-until: string # nullable, format: date-time
  --flags: int # nullable
]: any -> record<avatar: string, avatar_decoration_data: any, banner: string, communication_disabled_until: string, flags: int, joined_at: string, nick: string, pending: bool, premium_since: string, roles: list<string>, collectibles: any, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, mute: bool, deaf: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/members/($user_id)")
  let body = {nick: $nick, roles: $roles, mute: $mute, deaf: $deaf, channel_id: $channel_id, communication_disabled_until: $communication_disabled_until, flags: $flags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /guilds/{guild_id}/members/{user_id}/roles/{role_id}
#
# operationId: add_guild_member_role
export def "guilds-members-roles role-by-guild_id-user_id-role_id" [
  guild_id: string
  user_id: string
  role_id: string
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
  let full_url = (build-url $base $"/guilds/($guild_id)/members/($user_id)/roles/($role_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /guilds/{guild_id}/members/{user_id}/roles/{role_id}
#
# operationId: delete_guild_member_role
export def "guilds-members-roles role-by-guild_id-user_id-role_id-1" [
  guild_id: string
  user_id: string
  role_id: string
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
  let full_url = (build-url $base $"/guilds/($guild_id)/members/($user_id)/roles/($role_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /guilds/{guild_id}/messages/search
#
# operationId: guild_search
export def "guilds-messages-search search" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sort-by: string
  --sort-order: string
  --content: string
  --slop: int
  --author-id: list
  --author-type: list
  --mentions: list
  --mentions-role-id: list
  --replied-to-user-id: list
  --replied-to-message-id: list
  --mention-everyone: oneof<nothing, bool>
  --min-id: string # format: snowflake
  --max-id: string # format: snowflake
  --limit: int
  --offset: int
  --has: list
  --link-hostname: list
  --embed-provider: list
  --embed-type: list
  --attachment-extension: list
  --attachment-filename: list
  --pinned: oneof<nothing, bool>
  --include-nsfw: oneof<nothing, bool>
  --channel-id: list
]: nothing -> record<messages: list<list<record>>, doing_deep_historical_index: bool, total_results: int, threads: table<id: string, type: int, last_message_id: any, flags: int, last_pin_timestamp: string, guild_id: string, name: string, parent_id: any, rate_limit_per_user: int, bitrate: int, user_limit: int, rtc_region: string, video_quality_mode: int, permissions: string, owner_id: string, thread_metadata: record, message_count: int, member_count: int, total_message_sent: int, applied_tags: list, member: record>, members: table<id: string, user_id: string, join_timestamp: string, flags: int, member: record>, documents_indexed: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort_by" $sort_by "scalar") (serialize-qp "sort_order" $sort_order "scalar") (serialize-qp "content" $content "scalar") (serialize-qp "slop" $slop "scalar") (serialize-qp "author_id" $author_id "multi") (serialize-qp "author_type" $author_type "multi") (serialize-qp "mentions" $mentions "multi") (serialize-qp "mentions_role_id" $mentions_role_id "multi") (serialize-qp "replied_to_user_id" $replied_to_user_id "multi") (serialize-qp "replied_to_message_id" $replied_to_message_id "multi") (serialize-qp "mention_everyone" $mention_everyone "scalar") (serialize-qp "min_id" $min_id "scalar") (serialize-qp "max_id" $max_id "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "has" $has "multi") (serialize-qp "link_hostname" $link_hostname "multi") (serialize-qp "embed_provider" $embed_provider "multi") (serialize-qp "embed_type" $embed_type "multi") (serialize-qp "attachment_extension" $attachment_extension "multi") (serialize-qp "attachment_filename" $attachment_filename "multi") (serialize-qp "pinned" $pinned "scalar") (serialize-qp "include_nsfw" $include_nsfw "scalar") (serialize-qp "channel_id" $channel_id "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/guilds/($guild_id)/messages/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /guilds/{guild_id}/new-member-welcome
#
# operationId: get_guild_new_member_welcome
export def "guilds-new-member-welcome welcome" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<guild_id: string, enabled: bool, welcome_message: record<author_ids: list<string>, message: string>, new_member_actions: table<channel_id: string, action_type: int, title: string, description: string, emoji: record, icon: string>, resource_channels: table<channel_id: string, title: string, emoji: record, icon: string, description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/new-member-welcome")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /guilds/{guild_id}/onboarding
#
# operationId: get_guilds_onboarding
export def "guilds-onboarding onboarding-by-guild_id" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<guild_id: string, prompts: table<id: string, title: string, options: list, single_select: bool, required: bool, in_onboarding: bool, type: int>, default_channel_ids: list<string>, enabled: bool, mode: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/onboarding")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /guilds/{guild_id}/onboarding
#
# operationId: put_guilds_onboarding
# --prompts item shape: {title: string, options: list, single_select?: bool, required?: bool, in_onboarding?: bool, type?: any, id: string}
export def "guilds-onboarding onboarding-by-guild_id-1" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --prompts: list # nullable — item shape: {title: string, options: list, single_select?: bool, required?: bool, in_onboarding?: bool, type?: any, id: string}
  --enabled: oneof<nothing, bool> # nullable
  --default-channel-ids: list # nullable
  --mode: any
]: any -> record<guild_id: string, prompts: table<id: string, title: string, options: list, single_select: bool, required: bool, in_onboarding: bool, type: int>, default_channel_ids: list<string>, enabled: bool, mode: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/onboarding")
  let body = {prompts: $prompts, enabled: $enabled, default_channel_ids: $default_channel_ids, mode: $mode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /guilds/{guild_id}/preview
#
# operationId: get_guild_preview
export def "guilds-preview preview" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, icon: string, description: string, home_header: string, splash: string, discovery_splash: string, features: list<string>, approximate_member_count: int, approximate_presence_count: int, emojis: table<id: string, name: string, user: record, roles: list, require_colons: bool, managed: bool, animated: bool, available: bool>, stickers: table<id: string, name: string, tags: string, type: int, format_type: any, description: string, available: bool, guild_id: string, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/preview")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /guilds/{guild_id}/prune
#
# operationId: preview_prune_guild
export def "guilds-prune guild-by-guild_id" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --days: int
  --include-roles: string
]: nothing -> record<pruned: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "days" $days "scalar") (serialize-qp "include_roles" $include_roles "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/guilds/($guild_id)/prune" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /guilds/{guild_id}/prune
#
# operationId: prune_guild
export def "guilds-prune guild-by-guild_id-1" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --days: int # nullable
  --compute-prune-count: oneof<nothing, bool> # nullable
  --include-roles: any
]: any -> record<pruned: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/prune")
  let body = {days: $days, compute_prune_count: $compute_prune_count, include_roles: $include_roles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /guilds/{guild_id}/regions
#
# operationId: list_guild_voice_regions
export def "guilds-regions regions" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, name: string, custom: bool, deprecated: bool, optimal: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/regions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List join requests for guild, optionally filtered by application status
#
# GET /guilds/{guild_id}/requests
# operationId: get_guild_join_requests
export def "guilds-requests requests" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string
  --limit: int
  --before: string # format: snowflake
  --after: string # format: snowflake
]: nothing -> record<total: int, guild_join_requests: table<id: string, created_at: string, reviewed_at: string, application_status: any, rejection_reason: string, guild_id: string, user_id: string, user: any, form_responses: list, actioned_by_user: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/guilds/($guild_id)/requests" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Approve or reject guild join request
#
# PATCH /guilds/{guild_id}/requests/{request_id}
# operationId: action_guild_join_request
export def "guilds-requests request" [
  guild_id: string
  request_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --action: string # Whether to approve or reject the join request
  --rejection-reason: string # Reason for rejection. Only used when action is REJECTED (nullable)
]: any -> record<id: string, created_at: string, reviewed_at: string, application_status: any, rejection_reason: string, guild_id: string, user_id: string, user: any, form_responses: list<any>, actioned_by_user: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/requests/($request_id)")
  let body = {action: $action, rejection_reason: $rejection_reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /guilds/{guild_id}/roles
#
# operationId: list_guild_roles
export def "guilds-roles roles-by-guild_id" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, name: string, permissions: string, position: int, color: int, colors: record<primary_color: int, secondary_color: int, tertiary_color: int>, hoist: bool, managed: bool, mentionable: bool, icon: string, unicode_emoji: string, tags: record<premium_subscriber: any, bot_id: string, integration_id: string, subscription_listing_id: string, available_for_purchase: any, guild_connections: any>, flags: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /guilds/{guild_id}/roles
#
# operationId: create_guild_role
export def "guilds-roles role-by-guild_id" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # nullable
  --permissions: int # nullable
  --color: int # nullable
  --colors: any
  --hoist: oneof<nothing, bool> # nullable
  --mentionable: oneof<nothing, bool> # nullable
  --icon: string # nullable
  --unicode-emoji: string # nullable
]: any -> record<id: string, name: string, permissions: string, position: int, color: int, colors: record<primary_color: int, secondary_color: int, tertiary_color: int>, hoist: bool, managed: bool, mentionable: bool, icon: string, unicode_emoji: string, tags: record<premium_subscriber: any, bot_id: string, integration_id: string, subscription_listing_id: string, available_for_purchase: any, guild_connections: any>, flags: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/roles")
  let body = {name: $name, permissions: $permissions, color: $color, colors: $colors, hoist: $hoist, mentionable: $mentionable, icon: $icon, unicode_emoji: $unicode_emoji} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PATCH /guilds/{guild_id}/roles
#
# operationId: bulk_update_guild_roles
export def "guilds-roles roles-by-guild_id-1" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<id: string, name: string, permissions: string, position: int, color: int, colors: record<primary_color: int, secondary_color: int, tertiary_color: int>, hoist: bool, managed: bool, mentionable: bool, icon: string, unicode_emoji: string, tags: record<premium_subscriber: any, bot_id: string, integration_id: string, subscription_listing_id: string, available_for_purchase: any, guild_connections: any>, flags: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/roles")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /guilds/{guild_id}/roles/member-counts
#
# operationId: guild_role_member_counts
export def "guilds-roles-member-counts counts" [
  guild_id: string
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
  let full_url = (build-url $base $"/guilds/($guild_id)/roles/member-counts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /guilds/{guild_id}/roles/{role_id}
#
# operationId: get_guild_role
export def "guilds-roles role-by-guild_id-role_id" [
  guild_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, permissions: string, position: int, color: int, colors: record<primary_color: int, secondary_color: int, tertiary_color: int>, hoist: bool, managed: bool, mentionable: bool, icon: string, unicode_emoji: string, tags: record<premium_subscriber: any, bot_id: string, integration_id: string, subscription_listing_id: string, available_for_purchase: any, guild_connections: any>, flags: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/roles/($role_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /guilds/{guild_id}/roles/{role_id}
#
# operationId: delete_guild_role
export def "guilds-roles role-by-guild_id-role_id-1" [
  guild_id: string
  role_id: string
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
  let full_url = (build-url $base $"/guilds/($guild_id)/roles/($role_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /guilds/{guild_id}/roles/{role_id}
#
# operationId: update_guild_role
export def "guilds-roles role-by-guild_id-role_id-2" [
  guild_id: string
  role_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # nullable
  --permissions: int # nullable
  --color: int # nullable
  --colors: any
  --hoist: oneof<nothing, bool> # nullable
  --mentionable: oneof<nothing, bool> # nullable
  --icon: string # nullable
  --unicode-emoji: string # nullable
]: any -> record<id: string, name: string, permissions: string, position: int, color: int, colors: record<primary_color: int, secondary_color: int, tertiary_color: int>, hoist: bool, managed: bool, mentionable: bool, icon: string, unicode_emoji: string, tags: record<premium_subscriber: any, bot_id: string, integration_id: string, subscription_listing_id: string, available_for_purchase: any, guild_connections: any>, flags: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/roles/($role_id)")
  let body = {name: $name, permissions: $permissions, color: $color, colors: $colors, hoist: $hoist, mentionable: $mentionable, icon: $icon, unicode_emoji: $unicode_emoji} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /guilds/{guild_id}/scheduled-events
#
# operationId: list_guild_scheduled_events
export def "guilds-scheduled-events events" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --with-user-count: oneof<nothing, bool>
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_user_count" $with_user_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/guilds/($guild_id)/scheduled-events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /guilds/{guild_id}/scheduled-events
#
# operationId: create_guild_scheduled_event
# --entity_metadata shape: {location: string}
export def "guilds-scheduled-events event-by-guild_id" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --description: string # nullable
  --image: string # nullable
  --scheduled-start-time: string # format: date-time
  --scheduled-end-time: string # nullable, format: date-time
  --privacy-level: int # format: int32
  --entity-type: int@entity-type-completer # format: int32
  --channel-id: any
  --recurrence-rule: any # Recurrence rule for the scheduled event
  --entity-metadata: record # shape: {location: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/scheduled-events")
  let body = {name: $name, description: $description, image: $image, scheduled_start_time: $scheduled_start_time, scheduled_end_time: $scheduled_end_time, privacy_level: $privacy_level, entity_type: $entity_type, channel_id: $channel_id, recurrence_rule: $recurrence_rule, entity_metadata: $entity_metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /guilds/{guild_id}/scheduled-events/{guild_scheduled_event_id}
#
# operationId: get_guild_scheduled_event
export def "guilds-scheduled-events event-by-guild_id-guild_scheduled_event_id" [
  guild_id: string
  guild_scheduled_event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --with-user-count: oneof<nothing, bool>
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_user_count" $with_user_count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/guilds/($guild_id)/scheduled-events/($guild_scheduled_event_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /guilds/{guild_id}/scheduled-events/{guild_scheduled_event_id}
#
# operationId: delete_guild_scheduled_event
export def "guilds-scheduled-events event-by-guild_id-guild_scheduled_event_id-1" [
  guild_id: string
  guild_scheduled_event_id: string
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
  let full_url = (build-url $base $"/guilds/($guild_id)/scheduled-events/($guild_scheduled_event_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /guilds/{guild_id}/scheduled-events/{guild_scheduled_event_id}
#
# operationId: update_guild_scheduled_event
# --entity_metadata shape: {location: string}
export def "guilds-scheduled-events event-by-guild_id-guild_scheduled_event_id-2" [
  guild_id: string
  guild_scheduled_event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: any
  --name: string
  --description: string # nullable
  --image: string # nullable
  --scheduled-start-time: string # format: date-time
  --scheduled-end-time: string # nullable, format: date-time
  --entity-type: any
  --privacy-level: int # format: int32
  --channel-id: any
  --recurrence-rule: any # Recurrence rule for the scheduled event
  --entity-metadata: record # shape: {location: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/scheduled-events/($guild_scheduled_event_id)")
  let body = {status: $status, name: $name, description: $description, image: $image, scheduled_start_time: $scheduled_start_time, scheduled_end_time: $scheduled_end_time, entity_type: $entity_type, privacy_level: $privacy_level, channel_id: $channel_id, recurrence_rule: $recurrence_rule, entity_metadata: $entity_metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an exception to a recurring guild scheduled event
#
# POST /guilds/{guild_id}/scheduled-events/{guild_scheduled_event_id}/exceptions
# operationId: create_guild_scheduled_event_exception
export def "guilds-scheduled-events-exceptions exception-by-guild_id-guild_scheduled_event_id" [
  guild_id: string
  guild_scheduled_event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scheduled-start-time: string # Overridden start time of this occurrence (nullable, format: date-time)
  --scheduled-end-time: string # Overridden end time of this occurrence (nullable, format: date-time)
  original_scheduled_start_time: string # The original start time of the occurrence to create an exception for (format: date-time)
  --is-canceled: oneof<nothing, bool> # Whether this occurrence is canceled (nullable)
]: any -> record<event_id: string, event_exception_id: string, scheduled_start_time: string, scheduled_end_time: string, is_canceled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/scheduled-events/($guild_scheduled_event_id)/exceptions")
  let body = {scheduled_start_time: $scheduled_start_time, scheduled_end_time: $scheduled_end_time, original_scheduled_start_time: $original_scheduled_start_time, is_canceled: $is_canceled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an exception to a recurring guild scheduled event
#
# DELETE /guilds/{guild_id}/scheduled-events/{guild_scheduled_event_id}/exceptions/{exception_id}
# operationId: delete_guild_scheduled_event_exception
export def "guilds-scheduled-events-exceptions exception-by-guild_id-guild_scheduled_event_id-exception_id" [
  guild_id: string
  guild_scheduled_event_id: string
  exception_id: string
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
  let full_url = (build-url $base $"/guilds/($guild_id)/scheduled-events/($guild_scheduled_event_id)/exceptions/($exception_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Modify an exception to a recurring guild scheduled event
#
# PATCH /guilds/{guild_id}/scheduled-events/{guild_scheduled_event_id}/exceptions/{exception_id}
# operationId: update_guild_scheduled_event_exception
export def "guilds-scheduled-events-exceptions exception-by-guild_id-guild_scheduled_event_id-exception_id-1" [
  guild_id: string
  guild_scheduled_event_id: string
  exception_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --scheduled-start-time: string # Overridden start time of this occurrence (nullable, format: date-time)
  --scheduled-end-time: string # Overridden end time of this occurrence (nullable, format: date-time)
  --is-canceled: oneof<nothing, bool> # Whether this occurrence is canceled (nullable)
]: any -> record<event_id: string, event_exception_id: string, scheduled_start_time: string, scheduled_end_time: string, is_canceled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/scheduled-events/($guild_scheduled_event_id)/exceptions/($exception_id)")
  let body = {scheduled_start_time: $scheduled_start_time, scheduled_end_time: $scheduled_end_time, is_canceled: $is_canceled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /guilds/{guild_id}/scheduled-events/{guild_scheduled_event_id}/users
#
# operationId: list_guild_scheduled_event_users
export def "guilds-scheduled-events-users list" [
  guild_id: string
  guild_scheduled_event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --with-member: oneof<nothing, bool>
  --limit: int
  --before: string # format: snowflake
  --after: string # format: snowflake
]: nothing -> table<guild_scheduled_event_id: string, guild_scheduled_event_exception_id: any, user_id: string, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, member: record<avatar: string, avatar_decoration_data: any, banner: string, communication_disabled_until: string, flags: int, joined_at: string, nick: string, pending: bool, premium_since: string, roles: list, collectibles: any, user: record, mute: bool, deaf: bool>, response: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_member" $with_member "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/guilds/($guild_id)/scheduled-events/($guild_scheduled_event_id)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the count of users subscribed to a guild scheduled event
#
# GET /guilds/{guild_id}/scheduled-events/{guild_scheduled_event_id}/users/counts
# operationId: count_guild_scheduled_event_users
export def "guilds-scheduled-events-users-counts users" [
  guild_id: string
  guild_scheduled_event_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --guild-scheduled-event-exception-ids: list
]: nothing -> record<guild_scheduled_event_count: int, guild_scheduled_event_exception_counts: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "guild_scheduled_event_exception_ids" $guild_scheduled_event_exception_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/guilds/($guild_id)/scheduled-events/($guild_scheduled_event_id)/users/counts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of users subscribed to a guild scheduled event exception
#
# GET /guilds/{guild_id}/scheduled-events/{guild_scheduled_event_id}/{guild_scheduled_event_exception_id}/users
# operationId: list_guild_scheduled_event_exception_users
export def "guilds-scheduled-events-users users" [
  guild_id: string
  guild_scheduled_event_id: string
  guild_scheduled_event_exception_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --with-member: oneof<nothing, bool>
  --limit: int
  --before: string # format: snowflake
  --after: string # format: snowflake
]: nothing -> table<guild_scheduled_event_id: string, guild_scheduled_event_exception_id: any, user_id: string, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, member: record<avatar: string, avatar_decoration_data: any, banner: string, communication_disabled_until: string, flags: int, joined_at: string, nick: string, pending: bool, premium_since: string, roles: list, collectibles: any, user: record, mute: bool, deaf: bool>, response: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_member" $with_member "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/guilds/($guild_id)/scheduled-events/($guild_scheduled_event_id)/($guild_scheduled_event_exception_id)/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /guilds/{guild_id}/soundboard-sounds
#
# operationId: list_guild_soundboard_sounds
export def "guilds-soundboard-sounds sounds" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<items: table<name: string, sound_id: string, volume: float, emoji_id: any, emoji_name: string, guild_id: string, available: bool, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/soundboard-sounds")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /guilds/{guild_id}/soundboard-sounds
#
# operationId: create_guild_soundboard_sound
export def "guilds-soundboard-sounds sound-by-guild_id" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --volume: float # nullable, format: double
  --emoji-id: any
  --emoji-name: string # nullable
  sound: string
]: any -> record<name: string, sound_id: string, volume: float, emoji_id: any, emoji_name: string, guild_id: string, available: bool, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/soundboard-sounds")
  let body = {name: $name, volume: $volume, emoji_id: $emoji_id, emoji_name: $emoji_name, sound: $sound} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /guilds/{guild_id}/soundboard-sounds/{sound_id}
#
# operationId: get_guild_soundboard_sound
export def "guilds-soundboard-sounds sound-by-guild_id-sound_id" [
  guild_id: string
  sound_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<name: string, sound_id: string, volume: float, emoji_id: any, emoji_name: string, guild_id: string, available: bool, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/soundboard-sounds/($sound_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /guilds/{guild_id}/soundboard-sounds/{sound_id}
#
# operationId: delete_guild_soundboard_sound
export def "guilds-soundboard-sounds sound-by-guild_id-sound_id-1" [
  guild_id: string
  sound_id: string
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
  let full_url = (build-url $base $"/guilds/($guild_id)/soundboard-sounds/($sound_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /guilds/{guild_id}/soundboard-sounds/{sound_id}
#
# operationId: update_guild_soundboard_sound
export def "guilds-soundboard-sounds sound-by-guild_id-sound_id-2" [
  guild_id: string
  sound_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --volume: float # nullable, format: double
  --emoji-id: any
  --emoji-name: string # nullable
]: any -> record<name: string, sound_id: string, volume: float, emoji_id: any, emoji_name: string, guild_id: string, available: bool, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/soundboard-sounds/($sound_id)")
  let body = {name: $name, volume: $volume, emoji_id: $emoji_id, emoji_name: $emoji_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /guilds/{guild_id}/stickers
#
# operationId: list_guild_stickers
export def "guilds-stickers stickers" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, name: string, tags: string, type: int, format_type: any, description: string, available: bool, guild_id: string, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/stickers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /guilds/{guild_id}/stickers
#
# operationId: create_guild_sticker
export def "guilds-stickers sticker-by-guild_id" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  tags: string
  --description: string # nullable
  file: string
]: any -> record<id: string, name: string, tags: string, type: int, format_type: any, description: string, available: bool, guild_id: string, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/stickers")
  let body = {name: $name, tags: $tags, description: $description, file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# GET /guilds/{guild_id}/stickers/{sticker_id}
#
# operationId: get_guild_sticker
export def "guilds-stickers sticker-by-guild_id-sticker_id" [
  guild_id: string
  sticker_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, tags: string, type: int, format_type: any, description: string, available: bool, guild_id: string, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/stickers/($sticker_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /guilds/{guild_id}/stickers/{sticker_id}
#
# operationId: delete_guild_sticker
export def "guilds-stickers sticker-by-guild_id-sticker_id-1" [
  guild_id: string
  sticker_id: string
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
  let full_url = (build-url $base $"/guilds/($guild_id)/stickers/($sticker_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /guilds/{guild_id}/stickers/{sticker_id}
#
# operationId: update_guild_sticker
export def "guilds-stickers sticker-by-guild_id-sticker_id-2" [
  guild_id: string
  sticker_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --tags: string
  --description: string # nullable
]: any -> record<id: string, name: string, tags: string, type: int, format_type: any, description: string, available: bool, guild_id: string, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/stickers/($sticker_id)")
  let body = {name: $name, tags: $tags, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /guilds/{guild_id}/templates
#
# operationId: list_guild_templates
export def "guilds-templates templates" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<code: string, name: string, description: string, usage_count: int, creator_id: string, creator: any, created_at: string, updated_at: string, source_guild_id: string, serialized_source_guild: record<name: string, description: string, region: string, verification_level: int, default_message_notifications: int, explicit_content_filter: int, preferred_locale: string, afk_channel_id: any, afk_timeout: int, system_channel_id: any, system_channel_flags: int, roles: list, channels: list>, is_dirty: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/templates")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /guilds/{guild_id}/templates
#
# operationId: create_guild_template
export def "guilds-templates template-by-guild_id" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
  --description: string # nullable
]: any -> record<code: string, name: string, description: string, usage_count: int, creator_id: string, creator: any, created_at: string, updated_at: string, source_guild_id: string, serialized_source_guild: record<name: string, description: string, region: string, verification_level: int, default_message_notifications: int, explicit_content_filter: int, preferred_locale: string, afk_channel_id: any, afk_timeout: int, system_channel_id: any, system_channel_flags: int, roles: list<record>, channels: list<record>>, is_dirty: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/templates")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /guilds/{guild_id}/templates/{code}
#
# operationId: sync_guild_template
export def "guilds-templates template-by-guild_id-code" [
  guild_id: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, name: string, description: string, usage_count: int, creator_id: string, creator: any, created_at: string, updated_at: string, source_guild_id: string, serialized_source_guild: record<name: string, description: string, region: string, verification_level: int, default_message_notifications: int, explicit_content_filter: int, preferred_locale: string, afk_channel_id: any, afk_timeout: int, system_channel_id: any, system_channel_flags: int, roles: list<record>, channels: list<record>>, is_dirty: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/templates/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /guilds/{guild_id}/templates/{code}
#
# operationId: delete_guild_template
export def "guilds-templates template-by-guild_id-code-1" [
  guild_id: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, name: string, description: string, usage_count: int, creator_id: string, creator: any, created_at: string, updated_at: string, source_guild_id: string, serialized_source_guild: record<name: string, description: string, region: string, verification_level: int, default_message_notifications: int, explicit_content_filter: int, preferred_locale: string, afk_channel_id: any, afk_timeout: int, system_channel_id: any, system_channel_flags: int, roles: list<record>, channels: list<record>>, is_dirty: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/templates/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /guilds/{guild_id}/templates/{code}
#
# operationId: update_guild_template
export def "guilds-templates template-by-guild_id-code-2" [
  guild_id: string
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --description: string # nullable
]: any -> record<code: string, name: string, description: string, usage_count: int, creator_id: string, creator: any, created_at: string, updated_at: string, source_guild_id: string, serialized_source_guild: record<name: string, description: string, region: string, verification_level: int, default_message_notifications: int, explicit_content_filter: int, preferred_locale: string, afk_channel_id: any, afk_timeout: int, system_channel_id: any, system_channel_flags: int, roles: list<record>, channels: list<record>>, is_dirty: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/templates/($code)")
  let body = {name: $name, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /guilds/{guild_id}/threads/active
#
# operationId: get_active_guild_threads
export def "guilds-threads-active threads" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<threads: table<id: string, type: int, last_message_id: any, flags: int, last_pin_timestamp: string, guild_id: string, name: string, parent_id: any, rate_limit_per_user: int, bitrate: int, user_limit: int, rtc_region: string, video_quality_mode: int, permissions: string, owner_id: string, thread_metadata: record, message_count: int, member_count: int, total_message_sent: int, applied_tags: list, member: record>, members: table<id: string, user_id: string, join_timestamp: string, flags: int, member: record>, has_more: bool, first_messages: table<type: int, content: string, mentions: list, mention_roles: list, attachments: list, embeds: list, timestamp: string, edited_timestamp: string, flags: int, components: list, stickers: list, sticker_items: list, id: string, channel_id: string, author: record, pinned: bool, mention_everyone: bool, tts: bool, call: record, activity: record, application: record, application_id: string, interaction: record, nonce: any, webhook_id: string, message_reference: record, thread: record, mention_channels: list, role_subscription_data: record, purchase_notification: record, position: int, resolved: record, poll: record, shared_client_theme: record, interaction_metadata: any, message_snapshots: list, reactions: list, referenced_message: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/threads/active")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /guilds/{guild_id}/vanity-url
#
# operationId: get_guild_vanity_url
export def "guilds-vanity-url url" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string, uses: int, error: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/vanity-url")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /guilds/{guild_id}/voice-states/@me
#
# operationId: get_self_voice_state
export def "guilds-voice-states-me state-by-guild_id" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<channel_id: any, deaf: bool, guild_id: any, member: record<avatar: string, avatar_decoration_data: any, banner: string, communication_disabled_until: string, flags: int, joined_at: string, nick: string, pending: bool, premium_since: string, roles: list<string>, collectibles: any, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, mute: bool, deaf: bool>, mute: bool, request_to_speak_timestamp: string, suppress: bool, self_stream: bool, self_deaf: bool, self_mute: bool, self_video: bool, session_id: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/voice-states/@me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /guilds/{guild_id}/voice-states/@me
#
# operationId: update_self_voice_state
export def "guilds-voice-states-me state-by-guild_id-1" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --request-to-speak-timestamp: string # nullable, format: date-time
  --suppress: oneof<nothing, bool> # nullable
  --channel-id: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/voice-states/@me")
  let body = {request_to_speak_timestamp: $request_to_speak_timestamp, suppress: $suppress, channel_id: $channel_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /guilds/{guild_id}/voice-states/{user_id}
#
# operationId: get_voice_state
export def "guilds-voice-states state-by-guild_id-user_id" [
  guild_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<channel_id: any, deaf: bool, guild_id: any, member: record<avatar: string, avatar_decoration_data: any, banner: string, communication_disabled_until: string, flags: int, joined_at: string, nick: string, pending: bool, premium_since: string, roles: list<string>, collectibles: any, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, mute: bool, deaf: bool>, mute: bool, request_to_speak_timestamp: string, suppress: bool, self_stream: bool, self_deaf: bool, self_mute: bool, self_video: bool, session_id: string, user_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/voice-states/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /guilds/{guild_id}/voice-states/{user_id}
#
# operationId: update_voice_state
export def "guilds-voice-states state-by-guild_id-user_id-1" [
  guild_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --suppress: oneof<nothing, bool> # nullable
  --channel-id: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/voice-states/($user_id)")
  let body = {suppress: $suppress, channel_id: $channel_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /guilds/{guild_id}/webhooks
#
# operationId: get_guild_webhooks
export def "guilds-webhooks webhooks" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/webhooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /guilds/{guild_id}/welcome-screen
#
# operationId: get_guild_welcome_screen
export def "guilds-welcome-screen screen-by-guild_id" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<description: string, welcome_channels: table<channel_id: string, description: string, emoji_id: any, emoji_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/welcome-screen")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /guilds/{guild_id}/welcome-screen
#
# operationId: update_guild_welcome_screen
# --welcome_channels item shape: {channel_id: string, description: string, emoji_id?: any, emoji_name?: string}
export def "guilds-welcome-screen screen-by-guild_id-1" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string # nullable
  --welcome-channels: list # nullable — item shape: {channel_id: string, description: string, emoji_id?: any, emoji_name?: string}
  --enabled: oneof<nothing, bool> # nullable
]: any -> record<description: string, welcome_channels: table<channel_id: string, description: string, emoji_id: any, emoji_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/welcome-screen")
  let body = {description: $description, welcome_channels: $welcome_channels, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /guilds/{guild_id}/widget
#
# operationId: get_guild_widget_settings
export def "guilds-widget settings-by-guild_id" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<enabled: bool, channel_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/widget")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /guilds/{guild_id}/widget
#
# operationId: update_guild_widget_settings
export def "guilds-widget settings-by-guild_id-1" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --channel-id: any
  --enabled: oneof<nothing, bool> # nullable
]: any -> record<enabled: bool, channel_id: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/widget")
  let body = {channel_id: $channel_id, enabled: $enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /guilds/{guild_id}/widget.json
#
# operationId: get_guild_widget
export def "guilds-widgetjson widget" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, instant_invite: string, channels: table<id: string, name: string, position: int>, members: table<id: string, username: string, discriminator: string, avatar: any, status: string, avatar_url: string, activity: record, deaf: bool, mute: bool, self_deaf: bool, self_mute: bool, suppress: bool, channel_id: string>, presence_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/guilds/($guild_id)/widget.json")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /guilds/{guild_id}/widget.png
#
# operationId: get_guild_widget_png
export def "guilds-widgetpng png" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --style: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "style" $style "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/guilds/($guild_id)/widget.png" $qp)
  let accept_val = "image/png"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /interactions/{interaction_id}/{interaction_token}/callback
#
# operationId: create_interaction_response
export def "interactions-callback response" [
  interaction_id: string
  interaction_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --with-response: oneof<nothing, bool>
  --type: int@type-completer # format: int32
  --data: any
]: any -> record<interaction: record<id: string, type: int, activity_instance_id: string, response_message_id: string, response_message_loading: bool, response_message_ephemeral: bool, channel_id: string, guild_id: string>, resource: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_response" $with_response "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/interactions/($interaction_id)/($interaction_token)/callback" $qp)
  let body = {type: $type, data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /invites/{code}
#
# operationId: invite_resolve
export def "invites resolve" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --with-counts: oneof<nothing, bool>
  --guild-scheduled-event-id: string # format: snowflake
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_counts" $with_counts "scalar") (serialize-qp "guild_scheduled_event_id" $guild_scheduled_event_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/invites/($code)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /invites/{code}
#
# operationId: invite_revoke
export def "invites revoke" [
  code: string
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
  let full_url = (build-url $base $"/invites/($code)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the target users for an invite.
#
# GET /invites/{code}/target-users
# operationId: get_invite_target_users
export def "invites-target-users users-by-code" [
  code: string
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
  let full_url = (build-url $base $"/invites/($code)/target-users")
  let accept_val = "text/csv"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the target users for an existing invite.
#
# PUT /invites/{code}/target-users
# operationId: update_invite_target_users
export def "invites-target-users users-by-code-1" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  target_users_file: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invites/($code)/target-users")
  let body = {target_users_file: $target_users_file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Get the target users job status for an invite.
#
# GET /invites/{code}/target-users/job-status
# operationId: get_invite_target_users_job_status
export def "invites-target-users-job-status status" [
  code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<status: int, total_users: int, processed_users: int, created_at: string, completed_at: string, error_message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/invites/($code)/target-users/job-status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /lobbies
#
# operationId: create_or_join_lobby
export def "lobbies lobby" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idle-timeout-seconds: int # nullable, format: int32
  --lobby-metadata: record # nullable
  --member-metadata: record # nullable
  secret: string
  --flags: any
]: any -> record<id: string, application_id: string, metadata: record, members: table<id: string, metadata: record, flags: int>, linked_channel: record<id: string, type: int, last_message_id: any, flags: int, last_pin_timestamp: string, guild_id: string, name: string, parent_id: any, rate_limit_per_user: int, bitrate: int, user_limit: int, rtc_region: string, video_quality_mode: int, permissions: string, topic: string, default_auto_archive_duration: int, default_thread_rate_limit_per_user: int, position: int, permission_overwrites: list<record>, nsfw: bool, available_tags: list<record>, default_reaction_emoji: any, default_sort_order: any, default_forum_layout: int, default_tag_setting: any>, flags: int, override_event_webhooks_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lobbies")
  let body = {idle_timeout_seconds: $idle_timeout_seconds, lobby_metadata: $lobby_metadata, member_metadata: $member_metadata, secret: $secret, flags: $flags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /lobbies
#
# operationId: create_lobby
# --members item shape: {id: string, metadata?: record, flags?: any}
export def "lobbies lobby-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idle-timeout-seconds: int # nullable, format: int32
  --members: list # nullable — item shape: {id: string, metadata?: record, flags?: any}
  --metadata: record # nullable
  --flags: any
  --override-event-webhooks-url: string # nullable, format: uri
]: any -> record<id: string, application_id: string, metadata: record, members: table<id: string, metadata: record, flags: int>, linked_channel: record<id: string, type: int, last_message_id: any, flags: int, last_pin_timestamp: string, guild_id: string, name: string, parent_id: any, rate_limit_per_user: int, bitrate: int, user_limit: int, rtc_region: string, video_quality_mode: int, permissions: string, topic: string, default_auto_archive_duration: int, default_thread_rate_limit_per_user: int, position: int, permission_overwrites: list<record>, nsfw: bool, available_tags: list<record>, default_reaction_emoji: any, default_sort_order: any, default_forum_layout: int, default_tag_setting: any>, flags: int, override_event_webhooks_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/lobbies")
  let body = {idle_timeout_seconds: $idle_timeout_seconds, members: $members, metadata: $metadata, flags: $flags, override_event_webhooks_url: $override_event_webhooks_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /lobbies/{lobby_id}
#
# operationId: get_lobby
export def "lobbies lobby-by-lobby_id" [
  lobby_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, application_id: string, metadata: record, members: table<id: string, metadata: record, flags: int>, linked_channel: record<id: string, type: int, last_message_id: any, flags: int, last_pin_timestamp: string, guild_id: string, name: string, parent_id: any, rate_limit_per_user: int, bitrate: int, user_limit: int, rtc_region: string, video_quality_mode: int, permissions: string, topic: string, default_auto_archive_duration: int, default_thread_rate_limit_per_user: int, position: int, permission_overwrites: list<record>, nsfw: bool, available_tags: list<record>, default_reaction_emoji: any, default_sort_order: any, default_forum_layout: int, default_tag_setting: any>, flags: int, override_event_webhooks_url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lobbies/($lobby_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Deletes the specified lobby if it exists. It is safe to call even if the lobby is already deleted.
#
# DELETE /lobbies/{lobby_id}
# operationId: delete_lobby
export def "lobbies lobby-by-lobby_id-1" [
  lobby_id: string
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
  let full_url = (build-url $base $"/lobbies/($lobby_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /lobbies/{lobby_id}
#
# operationId: edit_lobby
# --members item shape: {id: string, metadata?: record, flags?: any}
export def "lobbies lobby-by-lobby_id-2" [
  lobby_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --idle-timeout-seconds: int # nullable, format: int32
  --metadata: record # nullable
  --members: list # nullable — item shape: {id: string, metadata?: record, flags?: any}
  --flags: any
  --override-event-webhooks-url: string # nullable, format: uri
]: any -> record<id: string, application_id: string, metadata: record, members: table<id: string, metadata: record, flags: int>, linked_channel: record<id: string, type: int, last_message_id: any, flags: int, last_pin_timestamp: string, guild_id: string, name: string, parent_id: any, rate_limit_per_user: int, bitrate: int, user_limit: int, rtc_region: string, video_quality_mode: int, permissions: string, topic: string, default_auto_archive_duration: int, default_thread_rate_limit_per_user: int, position: int, permission_overwrites: list<record>, nsfw: bool, available_tags: list<record>, default_reaction_emoji: any, default_sort_order: any, default_forum_layout: int, default_tag_setting: any>, flags: int, override_event_webhooks_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lobbies/($lobby_id)")
  let body = {idle_timeout_seconds: $idle_timeout_seconds, metadata: $metadata, members: $members, flags: $flags, override_event_webhooks_url: $override_event_webhooks_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PATCH /lobbies/{lobby_id}/channel-linking
#
# operationId: edit_lobby_channel_link
export def "lobbies-channel-linking link" [
  lobby_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --channel-id: any
]: any -> record<id: string, application_id: string, metadata: record, members: table<id: string, metadata: record, flags: int>, linked_channel: record<id: string, type: int, last_message_id: any, flags: int, last_pin_timestamp: string, guild_id: string, name: string, parent_id: any, rate_limit_per_user: int, bitrate: int, user_limit: int, rtc_region: string, video_quality_mode: int, permissions: string, topic: string, default_auto_archive_duration: int, default_thread_rate_limit_per_user: int, position: int, permission_overwrites: list<record>, nsfw: bool, available_tags: list<record>, default_reaction_emoji: any, default_sort_order: any, default_forum_layout: int, default_tag_setting: any>, flags: int, override_event_webhooks_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lobbies/($lobby_id)/channel-linking")
  let body = {channel_id: $channel_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /lobbies/{lobby_id}/members/@me
#
# operationId: leave_lobby
export def "lobbies-members-me lobby" [
  lobby_id: string
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
  let full_url = (build-url $base $"/lobbies/($lobby_id)/members/@me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /lobbies/{lobby_id}/members/@me/invites
#
# operationId: create_linked_lobby_guild_invite_for_self
export def "lobbies-members-me-invites self" [
  lobby_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lobbies/($lobby_id)/members/@me/invites")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /lobbies/{lobby_id}/members/bulk
#
# operationId: bulk_update_lobby_members
export def "lobbies-members-bulk members" [
  lobby_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<id: string, metadata: record, flags: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lobbies/($lobby_id)/members/bulk")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# PUT /lobbies/{lobby_id}/members/{user_id}
#
# operationId: add_lobby_member
export def "lobbies-members member-by-lobby_id-user_id" [
  lobby_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metadata: record # nullable
  --flags: any
]: any -> record<id: string, metadata: record, flags: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lobbies/($lobby_id)/members/($user_id)")
  let body = {metadata: $metadata, flags: $flags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /lobbies/{lobby_id}/members/{user_id}
#
# operationId: delete_lobby_member
export def "lobbies-members member-by-lobby_id-user_id-1" [
  lobby_id: string
  user_id: string
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
  let full_url = (build-url $base $"/lobbies/($lobby_id)/members/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /lobbies/{lobby_id}/members/{user_id}/invites
#
# operationId: create_linked_lobby_guild_invite_for_user
export def "lobbies-members-invites user" [
  lobby_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<code: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lobbies/($lobby_id)/members/($user_id)/invites")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /lobbies/{lobby_id}/messages
#
# operationId: get_lobby_messages
export def "lobbies-messages messages" [
  lobby_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int
]: nothing -> table<id: string, type: int, content: string, lobby_id: string, channel_id: string, author: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, metadata: record, moderation_metadata: record, flags: int, application_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/lobbies/($lobby_id)/messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /lobbies/{lobby_id}/messages
#
# operationId: create_lobby_message
# --embeds item shape: {type?: string, url?: string, title?: string, color?: int, timestamp?: string, description?: string, author?: any, image?: any, thumbnail?: any, footer?: any, fields?: list, provider?: any, video?: any}
# --attachments item shape: {id: string, filename?: string, description?: string, duration_secs?: float, waveform?: string, title?: string, is_remix?: bool}
export def "lobbies-messages message" [
  lobby_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --content: string # nullable
  --embeds: list # nullable — item shape: {type?: string, url?: string, title?: string, color?: int, timestamp?: string, description?: string, author?: any, image?: any, thumbnail?: any, footer?: any, fields?: list, provider?: any, video?: any}
  --allowed-mentions: any
  --sticker-ids: list # nullable
  --components: list # nullable
  --flags: int # nullable
  --attachments: list # nullable — item shape: {id: string, filename?: string, description?: string, duration_secs?: float, waveform?: string, title?: string, is_remix?: bool}
  --poll: any
  --shared-client-theme: any
  --message-reference: any
  --nonce: any
  --enforce-nonce: oneof<nothing, bool> # nullable
  --tts: oneof<nothing, bool> # nullable
]: any -> record<id: string, type: int, content: string, lobby_id: string, channel_id: string, author: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, metadata: record, moderation_metadata: record, flags: int, application_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lobbies/($lobby_id)/messages")
  let body = {content: $content, embeds: $embeds, allowed_mentions: $allowed_mentions, sticker_ids: $sticker_ids, components: $components, flags: $flags, attachments: $attachments, poll: $poll, shared_client_theme: $shared_client_theme, message_reference: $message_reference, nonce: $nonce, enforce_nonce: $enforce_nonce, tts: $tts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update the external moderation metadata for a lobby message.
#
# PUT /lobbies/{lobby_id}/messages/{message_id}/moderation-metadata
# operationId: update_lobby_message_external_moderation_metadata
export def "lobbies-messages-moderation-metadata metadata" [
  lobby_id: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/lobbies/($lobby_id)/messages/($message_id)/moderation-metadata")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /oauth2/@me
#
# operationId: get_my_oauth2_authorization
export def "oauth2-me authorization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<application: record<id: string, name: string, icon: string, description: string, type: any, cover_image: string, primary_sku_id: string, bot: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, slug: string, guild_id: string, rpc_origins: list<string>, bot_public: bool, bot_require_code_grant: bool, terms_of_service_url: string, privacy_policy_url: string, custom_install_url: string, install_params: record<scopes: list, permissions: string>, integration_types_config: record, verify_key: string, flags: int, flags_new: string, max_participants: int, tags: list<string>>, expires: string, scopes: list<string>, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/@me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /oauth2/applications/@me
#
# operationId: get_my_oauth2_application
export def "oauth2-applications-me application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, name: string, icon: string, description: string, type: any, cover_image: string, primary_sku_id: string, bot: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, slug: string, guild_id: string, rpc_origins: list<string>, bot_public: bool, bot_require_code_grant: bool, terms_of_service_url: string, privacy_policy_url: string, custom_install_url: string, install_params: record<scopes: list<string>, permissions: string>, integration_types_config: record, verify_key: string, flags: int, flags_new: string, max_participants: int, tags: list<string>, redirect_uris: list<string>, interactions_endpoint_url: string, role_connections_verification_url: string, owner: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, approximate_guild_count: int, approximate_user_install_count: int, approximate_user_authorization_count: int, event_webhooks_url: string, event_webhooks_status: int, event_webhooks_types: list<string>, explicit_content_filter: int, team: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/applications/@me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /oauth2/keys
#
# operationId: get_public_keys
export def "oauth2-keys keys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<keys: table<kty: string, use: string, kid: string, n: string, e: string, alg: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /oauth2/userinfo
#
# operationId: get_openid_connect_userinfo
export def "oauth2-userinfo userinfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sub: string, email: string, email_verified: bool, preferred_username: string, nickname: string, picture: string, locale: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/oauth2/userinfo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the external moderation metadata for a user message (DM).
#
# PUT /partner-sdk/dms/{user_id_1}/{user_id_2}/messages/{message_id}/moderation-metadata
# operationId: update_user_message_external_moderation_metadata
export def "partner-sdk-dms-messages-moderation-metadata metadata" [
  user_id_1: string
  user_id_2: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/partner-sdk/dms/($user_id_1)/($user_id_2)/messages/($message_id)/moderation-metadata")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /partner-sdk/provisional-accounts/unmerge
#
# operationId: partner_sdk_unmerge_provisional_account
export def "partner-sdk-provisional-accounts-unmerge account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  client_id: string # format: snowflake
  --client-secret: string # nullable
  external_auth_token: string
  external_auth_type: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/partner-sdk/provisional-accounts/unmerge")
  let body = {client_id: $client_id, client_secret: $client_secret, external_auth_token: $external_auth_token, external_auth_type: $external_auth_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /partner-sdk/provisional-accounts/unmerge/bot
#
# operationId: bot_partner_sdk_unmerge_provisional_account
export def "partner-sdk-provisional-accounts-unmerge-bot account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  external_user_id: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/partner-sdk/provisional-accounts/unmerge/bot")
  let body = {external_user_id: $external_user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /partner-sdk/token
#
# operationId: partner_sdk_token
export def "partner-sdk-token token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  client_id: string # format: snowflake
  --client-secret: string # nullable
  external_auth_token: string
  external_auth_type: string
]: any -> record<token_type: string, access_token: string, expires_in: int, scope: string, id_token: string, refresh_token: string, scopes: list<string>, expires_at_s: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/partner-sdk/token")
  let body = {client_id: $client_id, client_secret: $client_secret, external_auth_token: $external_auth_token, external_auth_type: $external_auth_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /partner-sdk/token/bot
#
# operationId: bot_partner_sdk_token
export def "partner-sdk-token-bot token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --provisional-user-id: any
  external_user_id: string
  --preferred-global-name: string # nullable
]: any -> record<token_type: string, access_token: string, expires_in: int, scope: string, id_token: string, refresh_token: string, scopes: list<string>, expires_at_s: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/partner-sdk/token/bot")
  let body = {provisional_user_id: $provisional_user_id, external_user_id: $external_user_id, preferred_global_name: $preferred_global_name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Returns all subscriptions containing the SKU, filtered by user.
#
# GET /skus/{sku_id}/subscriptions
# operationId: get_sku_subscriptions
export def "skus-subscriptions subscriptions" [
  sku_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # format: snowflake
  --after: string # format: snowflake
  --limit: int
  --user-id: string # format: snowflake
]: nothing -> table<id: string, user_id: string, sku_ids: list<string>, renewal_sku_ids: list<string>, entitlement_ids: list<string>, current_period_start: string, current_period_end: string, status: int, canceled_at: string, country: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "user_id" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/skus/($sku_id)/subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a subscription by its ID.
#
# GET /skus/{sku_id}/subscriptions/{subscription_id}
# operationId: get_sku_subscription
export def "skus-subscriptions subscription" [
  sku_id: string
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --user-id: string # format: snowflake
]: nothing -> record<id: string, user_id: string, sku_ids: list<string>, renewal_sku_ids: list<string>, entitlement_ids: list<string>, current_period_start: string, current_period_end: string, status: int, canceled_at: string, country: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/skus/($sku_id)/subscriptions/($subscription_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /soundboard-default-sounds
#
# operationId: get_soundboard_default_sounds
export def "soundboard-default-sounds sounds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<name: string, sound_id: string, volume: float, emoji_id: any, emoji_name: string, guild_id: string, available: bool, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/soundboard-default-sounds")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /stage-instances
#
# operationId: create_stage_instance
export def "stage-instances instance" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  topic: string
  channel_id: string # format: snowflake
  --privacy-level: any
  --guild-scheduled-event-id: any
  --send-start-notification: oneof<nothing, bool> # nullable
]: any -> record<guild_id: string, channel_id: string, topic: string, privacy_level: int, id: string, discoverable_disabled: bool, guild_scheduled_event_id: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stage-instances")
  let body = {topic: $topic, channel_id: $channel_id, privacy_level: $privacy_level, guild_scheduled_event_id: $guild_scheduled_event_id, send_start_notification: $send_start_notification} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /stage-instances/{channel_id}
#
# operationId: get_stage_instance
export def "stage-instances instance-by-channel_id" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<guild_id: string, channel_id: string, topic: string, privacy_level: int, id: string, discoverable_disabled: bool, guild_scheduled_event_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/stage-instances/($channel_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /stage-instances/{channel_id}
#
# operationId: delete_stage_instance
export def "stage-instances instance-by-channel_id-1" [
  channel_id: string
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
  let full_url = (build-url $base $"/stage-instances/($channel_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /stage-instances/{channel_id}
#
# operationId: update_stage_instance
export def "stage-instances instance-by-channel_id-2" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --topic: string
  --privacy-level: int # format: int32
]: any -> record<guild_id: string, channel_id: string, topic: string, privacy_level: int, id: string, discoverable_disabled: bool, guild_scheduled_event_id: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/stage-instances/($channel_id)")
  let body = {topic: $topic, privacy_level: $privacy_level} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /sticker-packs
#
# operationId: list_sticker_packs
export def "sticker-packs packs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sticker_packs: table<id: string, sku_id: string, name: string, description: string, stickers: list, cover_sticker_id: string, banner_asset_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sticker-packs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /sticker-packs/{pack_id}
#
# operationId: get_sticker_pack
export def "sticker-packs pack" [
  pack_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, sku_id: string, name: string, description: string, stickers: table<id: string, name: string, tags: string, type: int, format_type: any, description: string, pack_id: string, sort_value: int>, cover_sticker_id: string, banner_asset_id: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/sticker-packs/($pack_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /stickers/{sticker_id}
#
# operationId: get_sticker
export def "stickers sticker" [
  sticker_id: string
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
  let full_url = (build-url $base $"/stickers/($sticker_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /users/@me
#
# operationId: get_my_user
export def "users-me user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any, mfa_enabled: bool, locale: string, premium_type: int, email: string, verified: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/@me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /users/@me
#
# operationId: update_my_user
export def "users-me user-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  username: string
  --avatar: string # nullable
  --banner: string # nullable
]: any -> record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any, mfa_enabled: bool, locale: string, premium_type: int, email: string, verified: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/@me")
  let body = {username: $username, avatar: $avatar, banner: $banner} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /users/@me/applications/{application_id}/entitlements
#
# operationId: get_current_user_application_entitlements
export def "users-me-applications-entitlements entitlements" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sku-ids: string
  --exclude-consumed: oneof<nothing, bool>
]: nothing -> table<id: string, sku_id: string, application_id: string, user_id: string, guild_id: any, deleted: bool, starts_at: string, ends_at: string, type: int, fulfilled_at: string, fulfillment_status: any, consumed: bool, gifter_user_id: any, parent_id: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sku_ids" $sku_ids "scalar") (serialize-qp "exclude_consumed" $exclude_consumed "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/users/@me/applications/($application_id)/entitlements" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /users/@me/applications/{application_id}/role-connection
#
# operationId: get_application_user_role_connection
export def "users-me-applications-role-connection connection-by-application_id" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<platform_name: string, platform_username: string, metadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/@me/applications/($application_id)/role-connection")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PUT /users/@me/applications/{application_id}/role-connection
#
# operationId: update_application_user_role_connection
export def "users-me-applications-role-connection connection-by-application_id-1" [
  application_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --platform-name: string # nullable
  --platform-username: string # nullable
  --metadata: record # nullable
]: any -> record<platform_name: string, platform_username: string, metadata: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/@me/applications/($application_id)/role-connection")
  let body = {platform_name: $platform_name, platform_username: $platform_username, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /users/@me/applications/{application_id}/role-connection
#
# operationId: delete_application_user_role_connection
export def "users-me-applications-role-connection connection-by-application_id-2" [
  application_id: string
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
  let full_url = (build-url $base $"/users/@me/applications/($application_id)/role-connection")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /users/@me/channels
#
# operationId: create_dm
export def "users-me-channels dm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --recipient-id: any
  --access-tokens: list # nullable
  --nicks: record # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/@me/channels")
  let body = {recipient_id: $recipient_id, access_tokens: $access_tokens, nicks: $nicks} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /users/@me/connections
#
# operationId: list_my_connections
export def "users-me-connections connections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, name: string, type: string, friend_sync: bool, integrations: list<record>, show_activity: bool, two_way_link: bool, verified: bool, visibility: int, revoked: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/@me/connections")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /users/@me/guilds
#
# operationId: list_my_guilds
export def "users-me-guilds guilds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --before: string # format: snowflake
  --after: string # format: snowflake
  --limit: int
  --with-counts: oneof<nothing, bool>
]: nothing -> table<id: string, name: string, icon: string, banner: string, owner: bool, permissions: string, features: list<string>, approximate_member_count: int, approximate_presence_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "before" $before "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "with_counts" $with_counts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/@me/guilds" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /users/@me/guilds/{guild_id}
#
# operationId: leave_guild
export def "users-me-guilds guild" [
  guild_id: string
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
  let full_url = (build-url $base $"/users/@me/guilds/($guild_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /users/@me/guilds/{guild_id}/member
#
# operationId: get_my_guild_member
export def "users-me-guilds-member member" [
  guild_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<avatar: string, avatar_decoration_data: any, banner: string, communication_disabled_until: string, flags: int, joined_at: string, nick: string, pending: bool, premium_since: string, roles: list<string>, collectibles: any, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, mute: bool, deaf: bool, permissions: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/@me/guilds/($guild_id)/member")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /users/{user_id}
#
# operationId: get_user
export def "users user" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/users/($user_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /voice/regions
#
# operationId: list_voice_regions
export def "voice-regions regions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: string, name: string, custom: bool, deprecated: bool, optimal: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/voice/regions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /webhooks/{webhook_id}
#
# operationId: get_webhook
export def "webhooks webhook-by-webhook_id" [
  webhook_id: string
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
  let full_url = (build-url $base $"/webhooks/($webhook_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /webhooks/{webhook_id}
#
# operationId: delete_webhook
export def "webhooks webhook-by-webhook_id-1" [
  webhook_id: string
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
  let full_url = (build-url $base $"/webhooks/($webhook_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /webhooks/{webhook_id}
#
# operationId: update_webhook
export def "webhooks webhook-by-webhook_id-2" [
  webhook_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --avatar: string # nullable
  --channel-id: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($webhook_id)")
  let body = {name: $name, avatar: $avatar, channel_id: $channel_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /webhooks/{webhook_id}/{webhook_token}
#
# operationId: get_webhook_by_token
export def "webhooks token-by-webhook_id-webhook_token" [
  webhook_id: string
  webhook_token: string
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
  let full_url = (build-url $base $"/webhooks/($webhook_id)/($webhook_token)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /webhooks/{webhook_id}/{webhook_token}
#
# operationId: execute_webhook
# --embeds item shape: {type?: string, url?: string, title?: string, color?: int, timestamp?: string, description?: string, author?: any, image?: any, thumbnail?: any, footer?: any, fields?: list, provider?: any, video?: any}
# --attachments item shape: {id: string, filename?: string, description?: string, duration_secs?: float, waveform?: string, title?: string, is_remix?: bool}
export def "webhooks webhook-by-webhook_id-webhook_token" [
  webhook_id: string
  webhook_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --wait: oneof<nothing, bool>
  --thread-id: string # format: snowflake
  --with-components: oneof<nothing, bool>
  --content: string # nullable
  --embeds: list # nullable — item shape: {type?: string, url?: string, title?: string, color?: int, timestamp?: string, description?: string, author?: any, image?: any, thumbnail?: any, footer?: any, fields?: list, provider?: any, video?: any}
  --allowed-mentions: any
  --components: list # nullable
  --attachments: list # nullable — item shape: {id: string, filename?: string, description?: string, duration_secs?: float, waveform?: string, title?: string, is_remix?: bool}
  --poll: any
  --tts: oneof<nothing, bool> # nullable
  --flags: int # nullable
  --username: string # nullable
  --avatar-url: string # nullable, format: uri
  --thread-name: string # nullable
  --applied-tags: list # nullable
]: any -> record<type: int, content: string, mentions: table<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, mention_roles: list<string>, attachments: table<id: string, filename: string, size: int, url: string, proxy_url: string, width: int, height: int, duration_secs: float, waveform: string, description: string, content_type: string, ephemeral: bool, flags: int, placeholder: string, placeholder_version: int, title: string, application: record, clip_created_at: string, clip_participants: list>, embeds: table<type: string, url: string, title: string, description: string, color: int, timestamp: string, fields: list, author: record, provider: record, image: record, thumbnail: record, video: record, footer: record, flags: int, components: list>, timestamp: string, edited_timestamp: string, flags: int, components: list<any>, stickers: list<any>, sticker_items: table<id: string, name: string, format_type: int>, id: string, channel_id: string, author: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, pinned: bool, mention_everyone: bool, tts: bool, call: record<ended_timestamp: string, participants: list<string>>, activity: record<type: int, party_id: string>, application: record<id: string, name: string, icon: string, description: string, type: any, cover_image: string, primary_sku_id: string, bot: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>>, application_id: string, interaction: record<id: string, type: int, name: string, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, name_localized: string>, nonce: any, webhook_id: string, message_reference: record<type: int, channel_id: string, message_id: string, guild_id: string>, thread: record<id: string, type: int, last_message_id: any, flags: int, last_pin_timestamp: string, guild_id: string, name: string, parent_id: any, rate_limit_per_user: int, bitrate: int, user_limit: int, rtc_region: string, video_quality_mode: int, permissions: string, owner_id: string, thread_metadata: record<archived: bool, archive_timestamp: string, auto_archive_duration: int, locked: bool, create_timestamp: string, invitable: bool>, message_count: int, member_count: int, total_message_sent: int, applied_tags: list<string>, member: record<id: string, user_id: string, join_timestamp: string, flags: int, member: record>>, mention_channels: table<id: string, name: string, type: int, guild_id: string>, role_subscription_data: record<role_subscription_listing_id: string, tier_name: string, total_months_subscribed: int, is_renewal: bool>, purchase_notification: record<type: int, guild_product_purchase: record<listing_id: string, product_name: string>>, position: int, resolved: record<users: record, members: record, channels: record, roles: record>, poll: record<question: record<text: string, emoji: record>, answers: list<record>, expiry: string, allow_multiselect: bool, layout_type: int, results: record<answer_counts: list, is_finalized: bool>>, shared_client_theme: record<colors: list<string>, gradient_angle: int, base_mix: int, base_theme: int>, interaction_metadata: any, message_snapshots: table<message: record>, reactions: table<emoji: record, count: int, count_details: record, burst_colors: list, me_burst: bool, me: bool>, referenced_message: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wait" $wait "scalar") (serialize-qp "thread_id" $thread_id "scalar") (serialize-qp "with_components" $with_components "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/webhooks/($webhook_id)/($webhook_token)" $qp)
  let body = {content: $content, embeds: $embeds, allowed_mentions: $allowed_mentions, components: $components, attachments: $attachments, poll: $poll, tts: $tts, flags: $flags, username: $username, avatar_url: $avatar_url, thread_name: $thread_name, applied_tags: $applied_tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DELETE /webhooks/{webhook_id}/{webhook_token}
#
# operationId: delete_webhook_by_token
export def "webhooks token-by-webhook_id-webhook_token-1" [
  webhook_id: string
  webhook_token: string
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
  let full_url = (build-url $base $"/webhooks/($webhook_id)/($webhook_token)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /webhooks/{webhook_id}/{webhook_token}
#
# operationId: update_webhook_by_token
export def "webhooks token-by-webhook_id-webhook_token-2" [
  webhook_id: string
  webhook_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --avatar: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/webhooks/($webhook_id)/($webhook_token)")
  let body = {name: $name, avatar: $avatar} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /webhooks/{webhook_id}/{webhook_token}/github
#
# operationId: execute_github_compatible_webhook
# --sender shape: {id: int, login: string, html_url: string, avatar_url: string}
# --commits item shape: {id: string, url: string, message: string, author: record}
export def "webhooks-github webhook" [
  webhook_id: string
  webhook_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --wait: oneof<nothing, bool>
  --thread-id: string # format: snowflake
  --action: string # nullable
  --ref: string # nullable
  --ref-type: string # nullable
  --comment: any
  --issue: any
  --pull-request: any
  --repository: any
  --forkee: any
  sender: record # shape: {id: int, login: string, html_url: string, avatar_url: string}
  --member: any
  --release: any
  --head-commit: any
  --commits: list # nullable — item shape: {id: string, url: string, message: string, author: record}
  --forced: oneof<nothing, bool> # nullable
  --compare: string # nullable, format: uri
  --review: any
  --check-run: any
  --check-suite: any
  --discussion: any
  --answer: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wait" $wait "scalar") (serialize-qp "thread_id" $thread_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/webhooks/($webhook_id)/($webhook_token)/github" $qp)
  let body = {action: $action, ref: $ref, ref_type: $ref_type, comment: $comment, issue: $issue, pull_request: $pull_request, repository: $repository, forkee: $forkee, sender: $sender, member: $member, release: $release, head_commit: $head_commit, commits: $commits, forced: $forced, compare: $compare, review: $review, check_run: $check_run, check_suite: $check_suite, discussion: $discussion, answer: $answer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /webhooks/{webhook_id}/{webhook_token}/messages/@original
#
# operationId: get_original_webhook_message
export def "webhooks-messages-original message-by-webhook_id-webhook_token" [
  webhook_id: string
  webhook_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --thread-id: string # format: snowflake
]: nothing -> record<type: int, content: string, mentions: table<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, mention_roles: list<string>, attachments: table<id: string, filename: string, size: int, url: string, proxy_url: string, width: int, height: int, duration_secs: float, waveform: string, description: string, content_type: string, ephemeral: bool, flags: int, placeholder: string, placeholder_version: int, title: string, application: record, clip_created_at: string, clip_participants: list>, embeds: table<type: string, url: string, title: string, description: string, color: int, timestamp: string, fields: list, author: record, provider: record, image: record, thumbnail: record, video: record, footer: record, flags: int, components: list>, timestamp: string, edited_timestamp: string, flags: int, components: list<any>, stickers: list<any>, sticker_items: table<id: string, name: string, format_type: int>, id: string, channel_id: string, author: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, pinned: bool, mention_everyone: bool, tts: bool, call: record<ended_timestamp: string, participants: list<string>>, activity: record<type: int, party_id: string>, application: record<id: string, name: string, icon: string, description: string, type: any, cover_image: string, primary_sku_id: string, bot: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>>, application_id: string, interaction: record<id: string, type: int, name: string, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, name_localized: string>, nonce: any, webhook_id: string, message_reference: record<type: int, channel_id: string, message_id: string, guild_id: string>, thread: record<id: string, type: int, last_message_id: any, flags: int, last_pin_timestamp: string, guild_id: string, name: string, parent_id: any, rate_limit_per_user: int, bitrate: int, user_limit: int, rtc_region: string, video_quality_mode: int, permissions: string, owner_id: string, thread_metadata: record<archived: bool, archive_timestamp: string, auto_archive_duration: int, locked: bool, create_timestamp: string, invitable: bool>, message_count: int, member_count: int, total_message_sent: int, applied_tags: list<string>, member: record<id: string, user_id: string, join_timestamp: string, flags: int, member: record>>, mention_channels: table<id: string, name: string, type: int, guild_id: string>, role_subscription_data: record<role_subscription_listing_id: string, tier_name: string, total_months_subscribed: int, is_renewal: bool>, purchase_notification: record<type: int, guild_product_purchase: record<listing_id: string, product_name: string>>, position: int, resolved: record<users: record, members: record, channels: record, roles: record>, poll: record<question: record<text: string, emoji: record>, answers: list<record>, expiry: string, allow_multiselect: bool, layout_type: int, results: record<answer_counts: list, is_finalized: bool>>, shared_client_theme: record<colors: list<string>, gradient_angle: int, base_mix: int, base_theme: int>, interaction_metadata: any, message_snapshots: table<message: record>, reactions: table<emoji: record, count: int, count_details: record, burst_colors: list, me_burst: bool, me: bool>, referenced_message: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "thread_id" $thread_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/webhooks/($webhook_id)/($webhook_token)/messages/@original" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /webhooks/{webhook_id}/{webhook_token}/messages/@original
#
# operationId: delete_original_webhook_message
export def "webhooks-messages-original message-by-webhook_id-webhook_token-1" [
  webhook_id: string
  webhook_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --thread-id: string # format: snowflake
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "thread_id" $thread_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/webhooks/($webhook_id)/($webhook_token)/messages/@original" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /webhooks/{webhook_id}/{webhook_token}/messages/@original
#
# operationId: update_original_webhook_message
# --embeds item shape: {type?: string, url?: string, title?: string, color?: int, timestamp?: string, description?: string, author?: any, image?: any, thumbnail?: any, footer?: any, fields?: list, provider?: any, video?: any}
# --attachments item shape: {id: string, filename?: string, description?: string, duration_secs?: float, waveform?: string, title?: string, is_remix?: bool}
export def "webhooks-messages-original message-by-webhook_id-webhook_token-2" [
  webhook_id: string
  webhook_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --thread-id: string # format: snowflake
  --with-components: oneof<nothing, bool>
  --content: string # nullable
  --embeds: list # nullable — item shape: {type?: string, url?: string, title?: string, color?: int, timestamp?: string, description?: string, author?: any, image?: any, thumbnail?: any, footer?: any, fields?: list, provider?: any, video?: any}
  --allowed-mentions: any
  --components: list # nullable
  --attachments: list # nullable — item shape: {id: string, filename?: string, description?: string, duration_secs?: float, waveform?: string, title?: string, is_remix?: bool}
  --poll: any
  --flags: int # nullable
]: any -> record<type: int, content: string, mentions: table<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, mention_roles: list<string>, attachments: table<id: string, filename: string, size: int, url: string, proxy_url: string, width: int, height: int, duration_secs: float, waveform: string, description: string, content_type: string, ephemeral: bool, flags: int, placeholder: string, placeholder_version: int, title: string, application: record, clip_created_at: string, clip_participants: list>, embeds: table<type: string, url: string, title: string, description: string, color: int, timestamp: string, fields: list, author: record, provider: record, image: record, thumbnail: record, video: record, footer: record, flags: int, components: list>, timestamp: string, edited_timestamp: string, flags: int, components: list<any>, stickers: list<any>, sticker_items: table<id: string, name: string, format_type: int>, id: string, channel_id: string, author: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, pinned: bool, mention_everyone: bool, tts: bool, call: record<ended_timestamp: string, participants: list<string>>, activity: record<type: int, party_id: string>, application: record<id: string, name: string, icon: string, description: string, type: any, cover_image: string, primary_sku_id: string, bot: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>>, application_id: string, interaction: record<id: string, type: int, name: string, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, name_localized: string>, nonce: any, webhook_id: string, message_reference: record<type: int, channel_id: string, message_id: string, guild_id: string>, thread: record<id: string, type: int, last_message_id: any, flags: int, last_pin_timestamp: string, guild_id: string, name: string, parent_id: any, rate_limit_per_user: int, bitrate: int, user_limit: int, rtc_region: string, video_quality_mode: int, permissions: string, owner_id: string, thread_metadata: record<archived: bool, archive_timestamp: string, auto_archive_duration: int, locked: bool, create_timestamp: string, invitable: bool>, message_count: int, member_count: int, total_message_sent: int, applied_tags: list<string>, member: record<id: string, user_id: string, join_timestamp: string, flags: int, member: record>>, mention_channels: table<id: string, name: string, type: int, guild_id: string>, role_subscription_data: record<role_subscription_listing_id: string, tier_name: string, total_months_subscribed: int, is_renewal: bool>, purchase_notification: record<type: int, guild_product_purchase: record<listing_id: string, product_name: string>>, position: int, resolved: record<users: record, members: record, channels: record, roles: record>, poll: record<question: record<text: string, emoji: record>, answers: list<record>, expiry: string, allow_multiselect: bool, layout_type: int, results: record<answer_counts: list, is_finalized: bool>>, shared_client_theme: record<colors: list<string>, gradient_angle: int, base_mix: int, base_theme: int>, interaction_metadata: any, message_snapshots: table<message: record>, reactions: table<emoji: record, count: int, count_details: record, burst_colors: list, me_burst: bool, me: bool>, referenced_message: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "thread_id" $thread_id "scalar") (serialize-qp "with_components" $with_components "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/webhooks/($webhook_id)/($webhook_token)/messages/@original" $qp)
  let body = {content: $content, embeds: $embeds, allowed_mentions: $allowed_mentions, components: $components, attachments: $attachments, poll: $poll, flags: $flags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# GET /webhooks/{webhook_id}/{webhook_token}/messages/{message_id}
#
# operationId: get_webhook_message
export def "webhooks-messages message-by-webhook_id-webhook_token-message_id" [
  webhook_id: string
  webhook_token: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --thread-id: string # format: snowflake
]: nothing -> record<type: int, content: string, mentions: table<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, mention_roles: list<string>, attachments: table<id: string, filename: string, size: int, url: string, proxy_url: string, width: int, height: int, duration_secs: float, waveform: string, description: string, content_type: string, ephemeral: bool, flags: int, placeholder: string, placeholder_version: int, title: string, application: record, clip_created_at: string, clip_participants: list>, embeds: table<type: string, url: string, title: string, description: string, color: int, timestamp: string, fields: list, author: record, provider: record, image: record, thumbnail: record, video: record, footer: record, flags: int, components: list>, timestamp: string, edited_timestamp: string, flags: int, components: list<any>, stickers: list<any>, sticker_items: table<id: string, name: string, format_type: int>, id: string, channel_id: string, author: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, pinned: bool, mention_everyone: bool, tts: bool, call: record<ended_timestamp: string, participants: list<string>>, activity: record<type: int, party_id: string>, application: record<id: string, name: string, icon: string, description: string, type: any, cover_image: string, primary_sku_id: string, bot: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>>, application_id: string, interaction: record<id: string, type: int, name: string, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, name_localized: string>, nonce: any, webhook_id: string, message_reference: record<type: int, channel_id: string, message_id: string, guild_id: string>, thread: record<id: string, type: int, last_message_id: any, flags: int, last_pin_timestamp: string, guild_id: string, name: string, parent_id: any, rate_limit_per_user: int, bitrate: int, user_limit: int, rtc_region: string, video_quality_mode: int, permissions: string, owner_id: string, thread_metadata: record<archived: bool, archive_timestamp: string, auto_archive_duration: int, locked: bool, create_timestamp: string, invitable: bool>, message_count: int, member_count: int, total_message_sent: int, applied_tags: list<string>, member: record<id: string, user_id: string, join_timestamp: string, flags: int, member: record>>, mention_channels: table<id: string, name: string, type: int, guild_id: string>, role_subscription_data: record<role_subscription_listing_id: string, tier_name: string, total_months_subscribed: int, is_renewal: bool>, purchase_notification: record<type: int, guild_product_purchase: record<listing_id: string, product_name: string>>, position: int, resolved: record<users: record, members: record, channels: record, roles: record>, poll: record<question: record<text: string, emoji: record>, answers: list<record>, expiry: string, allow_multiselect: bool, layout_type: int, results: record<answer_counts: list, is_finalized: bool>>, shared_client_theme: record<colors: list<string>, gradient_angle: int, base_mix: int, base_theme: int>, interaction_metadata: any, message_snapshots: table<message: record>, reactions: table<emoji: record, count: int, count_details: record, burst_colors: list, me_burst: bool, me: bool>, referenced_message: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "thread_id" $thread_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/webhooks/($webhook_id)/($webhook_token)/messages/($message_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# DELETE /webhooks/{webhook_id}/{webhook_token}/messages/{message_id}
#
# operationId: delete_webhook_message
export def "webhooks-messages message-by-webhook_id-webhook_token-message_id-1" [
  webhook_id: string
  webhook_token: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --thread-id: string # format: snowflake
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "thread_id" $thread_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/webhooks/($webhook_id)/($webhook_token)/messages/($message_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# PATCH /webhooks/{webhook_id}/{webhook_token}/messages/{message_id}
#
# operationId: update_webhook_message
# --embeds item shape: {type?: string, url?: string, title?: string, color?: int, timestamp?: string, description?: string, author?: any, image?: any, thumbnail?: any, footer?: any, fields?: list, provider?: any, video?: any}
# --attachments item shape: {id: string, filename?: string, description?: string, duration_secs?: float, waveform?: string, title?: string, is_remix?: bool}
export def "webhooks-messages message-by-webhook_id-webhook_token-message_id-2" [
  webhook_id: string
  webhook_token: string
  message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --thread-id: string # format: snowflake
  --with-components: oneof<nothing, bool>
  --content: string # nullable
  --embeds: list # nullable — item shape: {type?: string, url?: string, title?: string, color?: int, timestamp?: string, description?: string, author?: any, image?: any, thumbnail?: any, footer?: any, fields?: list, provider?: any, video?: any}
  --allowed-mentions: any
  --components: list # nullable
  --attachments: list # nullable — item shape: {id: string, filename?: string, description?: string, duration_secs?: float, waveform?: string, title?: string, is_remix?: bool}
  --poll: any
  --flags: int # nullable
]: any -> record<type: int, content: string, mentions: table<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, mention_roles: list<string>, attachments: table<id: string, filename: string, size: int, url: string, proxy_url: string, width: int, height: int, duration_secs: float, waveform: string, description: string, content_type: string, ephemeral: bool, flags: int, placeholder: string, placeholder_version: int, title: string, application: record, clip_created_at: string, clip_participants: list>, embeds: table<type: string, url: string, title: string, description: string, color: int, timestamp: string, fields: list, author: record, provider: record, image: record, thumbnail: record, video: record, footer: record, flags: int, components: list>, timestamp: string, edited_timestamp: string, flags: int, components: list<any>, stickers: list<any>, sticker_items: table<id: string, name: string, format_type: int>, id: string, channel_id: string, author: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, pinned: bool, mention_everyone: bool, tts: bool, call: record<ended_timestamp: string, participants: list<string>>, activity: record<type: int, party_id: string>, application: record<id: string, name: string, icon: string, description: string, type: any, cover_image: string, primary_sku_id: string, bot: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>>, application_id: string, interaction: record<id: string, type: int, name: string, user: record<id: string, username: string, avatar: string, discriminator: string, public_flags: int, flags: int, bot: bool, system: bool, banner: string, accent_color: int, global_name: string, avatar_decoration_data: any, collectibles: any, primary_guild: any>, name_localized: string>, nonce: any, webhook_id: string, message_reference: record<type: int, channel_id: string, message_id: string, guild_id: string>, thread: record<id: string, type: int, last_message_id: any, flags: int, last_pin_timestamp: string, guild_id: string, name: string, parent_id: any, rate_limit_per_user: int, bitrate: int, user_limit: int, rtc_region: string, video_quality_mode: int, permissions: string, owner_id: string, thread_metadata: record<archived: bool, archive_timestamp: string, auto_archive_duration: int, locked: bool, create_timestamp: string, invitable: bool>, message_count: int, member_count: int, total_message_sent: int, applied_tags: list<string>, member: record<id: string, user_id: string, join_timestamp: string, flags: int, member: record>>, mention_channels: table<id: string, name: string, type: int, guild_id: string>, role_subscription_data: record<role_subscription_listing_id: string, tier_name: string, total_months_subscribed: int, is_renewal: bool>, purchase_notification: record<type: int, guild_product_purchase: record<listing_id: string, product_name: string>>, position: int, resolved: record<users: record, members: record, channels: record, roles: record>, poll: record<question: record<text: string, emoji: record>, answers: list<record>, expiry: string, allow_multiselect: bool, layout_type: int, results: record<answer_counts: list, is_finalized: bool>>, shared_client_theme: record<colors: list<string>, gradient_angle: int, base_mix: int, base_theme: int>, interaction_metadata: any, message_snapshots: table<message: record>, reactions: table<emoji: record, count: int, count_details: record, burst_colors: list, me_burst: bool, me: bool>, referenced_message: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "thread_id" $thread_id "scalar") (serialize-qp "with_components" $with_components "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/webhooks/($webhook_id)/($webhook_token)/messages/($message_id)" $qp)
  let body = {content: $content, embeds: $embeds, allowed_mentions: $allowed_mentions, components: $components, attachments: $attachments, poll: $poll, flags: $flags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# POST /webhooks/{webhook_id}/{webhook_token}/slack
#
# operationId: execute_slack_compatible_webhook
# --attachments item shape: {title?: string, title_link?: string, text?: string, color?: string, ts?: int, pretext?: string, footer?: string, footer_icon?: string, author_name?: string, author_link?: string, author_icon?: string, image_url?: string, thumb_url?: string, fields?: list}
export def "webhooks-slack webhook" [
  webhook_id: string
  webhook_token: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --wait: oneof<nothing, bool>
  --thread-id: string # format: snowflake
  --text: string # nullable
  --username: string # nullable
  --icon-url: string # nullable, format: uri
  --attachments: list # nullable — item shape: {title?: string, title_link?: string, text?: string, color?: string, ts?: int, pretext?: string, footer?: string, footer_icon?: string, author_name?: string, author_link?: string, author_icon?: string, image_url?: string, thumb_url?: string, fields?: list}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "wait" $wait "scalar") (serialize-qp "thread_id" $thread_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/webhooks/($webhook_id)/($webhook_token)/slack" $qp)
  let body = {text: $text, username: $username, icon_url: $icon_url, attachments: $attachments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
