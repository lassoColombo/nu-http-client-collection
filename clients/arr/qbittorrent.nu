# Auto-generated client for qBittorrent WebUI API v2.8.3
# Source: https://raw.githubusercontent.com/qbittorrent-ecosystem/webui-api-openapi/master/specs/v2.8.3/build/openapi.yaml
# Auth: --token flag or $env.QBITTORRENT_WEBUI_API_TOKEN

const BASE_URL = "http://localhost:8080/api/v2"
const DEFAULT_AUTH = "cookie-SID"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o QBITTORRENT_WEBUI_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "cookie-SID" => { {headers: {Cookie: $"SID=($token_val)"}, query: ""} }
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
def base-url-completer [] { ["http://localhost:8080/api/v2"] }
def auth-scheme-completer [] { ["cookie-SID"] }

# Completers for enum parameters
def filter-completer [] { ["active" "all" "completed" "downloading" "errored" "inactive" "paused" "resumed" "seeding" "stalled" "stalled_downloading" "stalled_uploading"] }
def priority-completer [] { ["0" "1" "6" "7"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "auth-login authLoginPost" } } | get name | first)
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

# Login
#
# POST /auth/login
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#login — WebUI-API on qBittorrent wiki
# operationId: authLoginPost
export def "auth-login authLoginPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Referer: string
  --Origin: string
  username: string
  password: string # format: password
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/login")
  let body = {username: $username, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Referer": $Referer, "Origin": $Origin} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Logout
#
# POST /auth/logout
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#logout — WebUI-API on qBittorrent wiki
# operationId: authLogoutPost
export def "auth-logout authLogoutPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/logout")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get application version
#
# GET /app/version
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#get-application-version — WebUI-API on qBittorrent wiki
# operationId: appVersionGet
export def "app-version appVersionGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/app/version")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get API version
#
# GET /app/webapiVersion
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#get-api-version — WebUI-API on qBittorrent wiki
# operationId: appWebapiVersionGet
export def "app-webapi-version appWebapiVersionGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/app/webapiVersion")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get build info
#
# GET /app/buildInfo
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#get-build-info — WebUI-API on qBittorrent wiki
# operationId: appBuildInfoGet
export def "app-build-info appBuildInfoGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<qt: string, libtorrent: string, boost: string, openssl: string, bitness: int> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/app/buildInfo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Shutdown application
#
# GET /app/shutdown
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#shutdown-application — WebUI-API on qBittorrent wiki
# operationId: appShutdownGet
export def "app-shutdown appShutdownGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/app/shutdown")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get application preferences
#
# GET /app/preferences
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#get-application-preferences — WebUI-API on qBittorrent wiki
# operationId: appPreferencesGet
export def "app-preferences appPreferencesGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<locale: string, create_subfolder_enabled: bool, start_paused_enabled: bool, auto_delete_mode: int, preallocate_all: bool, incomplete_files_ext: bool, auto_tmm_enabled: bool, torrent_changed_tmm_enabled: bool, save_path_changed_tmm_enabled: bool, category_changed_tmm_enabled: bool, save_path: string, temp_path_enabled: bool, temp_path: string, scan_dirs: record, export_dir: string, export_dir_fin: string, mail_notification_enabled: bool, mail_notification_sender: string, mail_notification_email: string, mail_notification_smtp: string, mail_notification_ssl_enabled: bool, mail_notification_auth_enabled: bool, mail_notification_username: string, mail_notification_password: string, autorun_enabled: bool, autorun_program: string, queueing_enabled: bool, max_active_downloads: int, max_active_torrents: int, max_active_uploads: int, dont_count_slow_torrents: bool, slow_torrent_dl_rate_threshold: int, slow_torrent_ul_rate_threshold: int, slow_torrent_inactive_timer: int, max_ratio_enabled: bool, max_ratio: float, max_ratio_act: int, listen_port: int, upnp: bool, random_port: bool, dl_limit: int, up_limit: int, max_connec: int, max_connec_per_torrent: int, max_uploads: int, max_uploads_per_torrent: int, stop_tracker_timeout: int, enable_piece_extent_affinity: bool, bittorrent_protocol: int, limit_utp_rate: bool, limit_tcp_overhead: bool, limit_lan_peers: bool, alt_dl_limit: int, alt_up_limit: int, scheduler_enabled: bool, schedule_from_hour: int, schedule_from_min: int, schedule_to_hour: int, schedule_to_min: int, scheduler_days: int, dht: bool, pex: bool, lsd: bool, encryption: int, anonymous_mode: bool, proxy_type: int, proxy_ip: string, proxy_port: int, proxy_peer_connections: bool, proxy_auth_enabled: bool, proxy_username: string, proxy_password: string, proxy_torrents_only: bool, ip_filter_enabled: bool, ip_filter_path: string, ip_filter_trackers: bool, web_ui_domain_list: list<string>, web_ui_address: string, web_ui_port: int, web_ui_upnp: bool, web_ui_username: string, web_ui_csrf_protection_enabled: bool, web_ui_clickjacking_protection_enabled: bool, web_ui_secure_cookie_enabled: bool, web_ui_max_auth_fail_count: int, web_ui_ban_duration: int, web_ui_session_timeout: int, web_ui_host_header_validation_enabled: bool, bypass_local_auth: bool, bypass_auth_subnet_whitelist_enabled: bool, bypass_auth_subnet_whitelist: list<string>, alternative_webui_enabled: bool, alternative_webui_path: string, use_https: bool, ssl_key: string, ssl_cert: string, web_ui_https_key_path: string, web_ui_https_cert_path: string, dyndns_enabled: bool, dyndns_service: int, dyndns_username: string, dyndns_password: string, dyndns_domain: string, rss_refresh_interval: int, rss_max_articles_per_feed: int, rss_processing_enabled: bool, rss_auto_downloading_enabled: bool, rss_download_repack_proper_episodes: bool, rss_smart_episode_filters: string, add_trackers_enabled: bool, add_trackers: string, web_ui_use_custom_http_headers_enabled: bool, web_ui_custom_http_headers: string, max_seeding_time_enabled: bool, max_seeding_time: int, announce_ip: string, announce_to_all_tiers: bool, announce_to_all_trackers: bool, async_io_threads: int, banned_IPs: string, checking_memory_use: int, current_interface_address: string, current_network_interface: string, disk_cache: int, disk_cache_ttl: int, embedded_tracker_port: int, enable_coalesce_read_write: bool, enable_embedded_tracker: bool, enable_multi_connections_from_same_ip: bool, enable_os_cache: bool, enable_upload_suggestions: bool, file_pool_size: int, outgoing_ports_max: int, outgoing_ports_min: int, recheck_completed_torrents: bool, resolve_peer_countries: bool, save_resume_data_interval: int, send_buffer_low_watermark: int, send_buffer_watermark: int, send_buffer_watermark_factor: int, socket_backlog_size: int, upload_choking_algorithm: int, upload_slots_behavior: int, upnp_lease_duration: int, utp_tcp_mixed_mode: int> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/app/preferences")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set application preferences
#
# POST /app/setPreferences
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#set-application-preferences — WebUI-API on qBittorrent wiki
# operationId: appSetPreferencesPost
export def "app-set-preferences appSetPreferencesPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  json: any # A json object with key-value pairs of the settings you want to change and their new values.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/app/setPreferences")
  let body = {json: $json} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get default save path
#
# GET /app/defaultSavePath
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#get-default-save-path — WebUI-API on qBittorrent wiki
# operationId: appDefaultSavePathGet
export def "app-default-save-path appDefaultSavePathGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/app/defaultSavePath")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get log
#
# POST /log/main
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#get-log — WebUI-API on qBittorrent wiki
# operationId: logMainPost
export def "log-main logMainPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --normal: string@bool-completer # Include normal messages (default: `true`) (default: true)
  --info: string@bool-completer # Include info messages (default: `true`) (default: true)
  --warning: string@bool-completer # Include warning messages (default: `true`) (default: true)
  --critical: string@bool-completer # Include critical messages (default: `true`) (default: true)
  last_known_id: int # Exclude messages with "message id" <= `last_known_id` (default: `-1`) (format: int64, default: -1)
]: any -> table<id: int, message: string, timestamp: int, type: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/log/main")
  let body = {normal: $normal, info: $info, warning: $warning, critical: $critical, last_known_id: $last_known_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get peer log
#
# POST /log/peers
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#get-peer-log — WebUI-API on qBittorrent wiki
# operationId: logPeersPost
export def "log-peers logPeersPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  last_known_id: int # Exclude messages with "message id" <= `last_known_id` (default: `-1`) (format: int64, default: -1)
]: any -> table<id: int, ip: string, timestamp: int, blocked: bool, reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/log/peers")
  let body = {last_known_id: $last_known_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get main data
#
# POST /sync/maindata
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#get-main-data — WebUI-API on qBittorrent wiki
# operationId: syncMaindataPost
export def "sync-maindata syncMaindataPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rid: int # Response ID. If not provided, `rid=0` will be assumed. If the given `rid` is different from the one of last server reply, `full_update` will be `true` (see the server reply details for more info) (format: int64)
]: any -> record<rid: int, full_update: bool, torrents: record, torrents_removed: list<string>, categories: record, categories_removed: list<string>, tags: list<string>, tags_removed: list<string>, server_state: record<dl_info_speed: int, dl_info_data: int, up_info_speed: int, up_info_data: int, dl_rate_limit: int, up_rate_limit: int, dht_nodes: int, connection_status: string, queueing: bool, use_alt_speed_limits: bool, refresh_interval: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sync/maindata")
  let body = {rid: $rid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get torrent peers data
#
# POST /sync/torrentPeers
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#get-torrent-peers-data — WebUI-API on qBittorrent wiki
# operationId: syncTorrentPeersPost
export def "sync-torrent-peers syncTorrentPeersPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hash: string # Torrent hash
  --rid: int # Response ID. If not provided, `rid=0` will be assumed. If the given `rid` is different from the one of last server reply, `full_update` will be `true` (see the server reply details for more info) (format: int64)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/sync/torrentPeers")
  let body = {hash: $hash, rid: $rid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get global transfer info
#
# GET /transfer/info
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#get-global-transfer-info — WebUI-API on qBittorrent wiki
# operationId: transferInfoGet
export def "transfer-info transferInfoGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<dl_info_speed: int, dl_info_data: int, up_info_speed: int, up_info_data: int, dl_rate_limit: int, up_rate_limit: int, dht_nodes: int, connection_status: string, queueing: bool, use_alt_speed_limits: bool, refresh_interval: int> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get alternative speed limits state
#
# GET /transfer/speedLimitsMode
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#get-alternative-speed-limits-state — WebUI-API on qBittorrent wiki
# operationId: transferSpeedLimitsModeGet
export def "transfer-speed-limits-mode transferSpeedLimitsModeGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/speedLimitsMode")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Toggle alternative speed limits
#
# GET /transfer/toggleSpeedLimitsMode
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#toggle-alternative-speed-limits — WebUI-API on qBittorrent wiki
# operationId: transferToggleSpeedLimitsModeGet
export def "transfer-toggle-speed-limits-mode transferToggleSpeedLimitsModeGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/toggleSpeedLimitsMode")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get global download limit
#
# GET /transfer/downloadLimit
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#get-global-download-limit — WebUI-API on qBittorrent wiki
# operationId: transferDownloadLimitGet
export def "transfer-download-limit transferDownloadLimitGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/downloadLimit")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set global download limit
#
# POST /transfer/setDownloadLimit
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#set-global-download-limit — WebUI-API on qBittorrent wiki
# operationId: transferSetDownloadLimitPost
export def "transfer-set-download-limit transferSetDownloadLimitPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The global download speed limit to set in bytes/second (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/setDownloadLimit")
  let body = {limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get global upload limit
#
# GET /transfer/uploadLimit
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#get-global-upload-limit — WebUI-API on qBittorrent wiki
# operationId: transferUploadLimitGet
export def "transfer-upload-limit transferUploadLimitGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/uploadLimit")
  let accept_val = "text/plain"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set global upload limit
#
# POST /transfer/setUploadLimit
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#set-global-upload-limit — WebUI-API on qBittorrent wiki
# operationId: transferSetUploadLimitPost
export def "transfer-set-upload-limit transferSetUploadLimitPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # The global upload speed limit to set in bytes/second (format: int64)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/setUploadLimit")
  let body = {limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Ban peers
#
# POST /transfer/banPeers
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#ban-peers — WebUI-API on qBittorrent wiki
# operationId: transferBanPeersPost
export def "transfer-ban-peers transferBanPeersPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --peers: list # The peer to ban, or multiple peers separated by a pipe `|`. Each peer is a colon-separated `host:port`
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transfer/banPeers")
  let body = {peers: $peers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get torrent list
#
# POST /torrents/info
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#get-torrent-list — WebUI-API on qBittorrent wiki
# operationId: torrentsInfoPost
export def "torrents-info torrentsInfoPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter: string@filter-completer # Filter torrent list by state. Allowed state filters: `all`, `downloading`, `seeding`, `completed`, `paused`, `active`, `inactive`, `resumed`, `stalled`, `stalled_uploading`, `stalled_downloading`, `errored`
  --category: string # Get torrents with the given category (empty string means "without category"; no "category" parameter means "any category" <- broken until [#11748](https://github.com/qbittorrent/qBittorrent/issues/11748) is resolved). Remember to URL-encode the category name. For example, `My category` becomes `My%20category`
  --tag: string # Get torrents with the given tag (empty string means "without tag"; no "tag" parameter means "any tag". Remember to URL-encode the category name. For example, `My tag` becomes `My%20tag`
  --body-sort: string # Sort torrents by given key. They can be sorted using any field of the response's JSON array (which are documented below) as the sort key.
  --reverse: string@bool-completer # Enable reverse sorting. Defaults to `false` (default: false)
  --limit: int # Limit the number of torrents returned (format: int64)
  --offset: int # Set offset (if less than 0, offset from end) (format: int64)
  --hashes: list # Filter by hashes. Can contain multiple hashes separated by `|`
]: any -> table<added_on: int, amount_left: int, auto_tmm: bool, availability: float, category: string, completed: int, completion_on: int, content_path: string, dl_limit: int, dlspeed: int, downloaded: int, downloaded_session: int, eta: int, f_l_piece_prio: bool, force_start: bool, hash: string, last_activity: int, magnet_uri: string, max_ratio: float, max_seeding_time: int, name: string, num_complete: int, num_incomplete: int, num_leechs: int, num_seeds: int, priority: int, progress: float, ratio: float, ratio_limit: float, save_path: string, seeding_time: int, seeding_time_limit: int, seen_complete: int, seq_dl: bool, size: int, state: string, super_seeding: bool, tags: string, time_active: int, total_size: int, tracker: string, up_limit: int, uploaded: int, uploaded_session: int, upspeed: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/info")
  let body = {filter: $filter, category: $category, tag: $tag, sort: $body_sort, reverse: $reverse, limit: $limit, offset: $offset, hashes: $hashes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get torrent generic properties
#
# POST /torrents/properties
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#get-torrent-generic-properties — WebUI-API on qBittorrent wiki
# operationId: torrentsPropertiesPost
export def "torrents-properties torrentsPropertiesPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hash: string # The hash of the torrent you want to get the generic properties of
]: any -> record<save_path: string, creation_date: int, piece_size: int, comment: string, total_wasted: int, total_uploaded: int, total_uploaded_session: int, total_downloaded: int, total_downloaded_session: int, up_limit: int, dl_limit: int, time_elapsed: int, seeding_time: int, nb_connections: int, nb_connections_limit: int, share_ratio: float, addition_date: int, completion_date: int, created_by: string, dl_speed_avg: int, dl_speed: int, eta: int, last_seen: int, peers: int, peers_total: int, pieces_have: int, pieces_num: int, reannounce: int, seeds: int, seeds_total: int, total_size: int, up_speed_avg: int, up_speed: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/properties")
  let body = {hash: $hash} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get torrent trackers
#
# POST /torrents/trackers
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#get-torrent-trackers — WebUI-API on qBittorrent wiki
# operationId: torrentsTrackersPost
export def "torrents-trackers torrentsTrackersPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hash: string # The hash of the torrent you want to get the trackers of
]: any -> table<url: string, status: int, tier: int, num_peers: int, num_seeds: int, num_leeches: int, num_downloaded: int, msg: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/trackers")
  let body = {hash: $hash} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get torrent web seeds
#
# POST /torrents/webseeds
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#get-torrent-web-seeds — WebUI-API on qBittorrent wiki
# operationId: torrentWebseedsPost
export def "torrents-webseeds torrentWebseedsPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hash: string # The hash of the torrent you want to get the webseeds of
]: any -> table<url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/webseeds")
  let body = {hash: $hash} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get torrent contents
#
# POST /torrents/files
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#get-torrent-contents — WebUI-API on qBittorrent wiki
# operationId: torrentsFilesPost
export def "torrents-files torrentsFilesPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hash: string # The hash of the torrent you want to get the contents of
  --indexes: list # The indexes of the files you want to retrieve. `indexes` can contain multiple values separated by `|`.
]: any -> table<index: int, name: string, size: int, progress: float, priority: int, is_seed: bool, piece_range: list<int>, availability: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/files")
  let body = {hash: $hash, indexes: $indexes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get torrent pieces' states
#
# POST /torrents/pieceStates
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#get-torrent-pieces-states — WebUI-API on qBittorrent wiki
# operationId: torrentsPieceStatesPost
export def "torrents-piece-states torrentsPieceStatesPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hash: string # The hash of the torrent you want to get the pieces' states of
]: any -> list<int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/pieceStates")
  let body = {hash: $hash} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get torrent pieces' hashes
#
# POST /torrents/pieceHashes
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#get-torrent-pieces-hashes — WebUI-API on qBittorrent wiki
# operationId: torrentsPieceHashesPost
export def "torrents-piece-hashes torrentsPieceHashesPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hash: string # The hash of the torrent you want to get the pieces' hashes of
]: any -> list<string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/pieceHashes")
  let body = {hash: $hash} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Pause torrents
#
# POST /torrents/pause
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#pause-torrents — WebUI-API on qBittorrent wiki
# operationId: torrentsPausePost
export def "torrents-pause torrentsPausePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hashes: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/pause")
  let body = {hashes: $hashes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Resume torrents
#
# POST /torrents/resume
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#resume-torrents — WebUI-API on qBittorrent wiki
# operationId: torrentsResumePost
export def "torrents-resume torrentsResumePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hashes: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/resume")
  let body = {hashes: $hashes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete torrents
#
# POST /torrents/delete
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#delete-torrents — WebUI-API on qBittorrent wiki
# operationId: torrentsDeletePost
export def "torrents-delete torrentsDeletePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hashes: list
  --deleteFiles: string@bool-completer # If set to `true`, the downloaded data will also be deleted, otherwise has no effect.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/delete")
  let body = {hashes: $hashes, deleteFiles: $deleteFiles} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Recheck torrents
#
# POST /torrents/recheck
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#recheck-torrents — WebUI-API on qBittorrent wiki
# operationId: torrentsRecheckPost
export def "torrents-recheck torrentsRecheckPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hashes: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/recheck")
  let body = {hashes: $hashes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Reannounce torrents
#
# POST /torrents/reannounce
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#reannounce-torrents — WebUI-API on qBittorrent wiki
# operationId: torrentsReannouncePost
export def "torrents-reannounce torrentsReannouncePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hashes: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/reannounce")
  let body = {hashes: $hashes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Add new torrent
#
# POST /torrents/add
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#add-new-torrent — WebUI-API on qBittorrent wiki
# operationId: torrentsAddPost
export def "torrents-add torrentsAddPost" [
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
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/add")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Add trackers to torrent
#
# POST /torrents/addTrackers
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#add-trackers-to-torrent — WebUI-API on qBittorrent wiki
# operationId: torrentsAddTrackersPost
export def "torrents-add-trackers torrentsAddTrackersPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hash: string # e.g. 8c212779b4abde7c6bc608063a0d008b7e40ce32
  urls: string # e.g. http://192.168.0.1/announce%0Audp://192.168.0.1:3333/dummyAnnounce
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/addTrackers")
  let body = {hash: $hash, urls: $urls} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Edit trackers
#
# POST /torrents/editTracker
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#edit-trackers — WebUI-API on qBittorrent wiki
# operationId: torrentsEditTrackerPost
export def "torrents-edit-tracker torrentsEditTrackerPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hash: string # The hash of the torrent
  origUrl: string # The tracker URL you want to edit
  newUrl: string # The new URL to replace the `origUrl`
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/editTracker")
  let body = {hash: $hash, origUrl: $origUrl, newUrl: $newUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove trackers
#
# POST /torrents/removeTrackers
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#remove-trackers — WebUI-API on qBittorrent wiki
# operationId: torrentsRemoveTrackersPost
export def "torrents-remove-trackers torrentsRemoveTrackersPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hash: string # The hash of the torrent
  urls: list # URLs to remove, separated by `|`
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/removeTrackers")
  let body = {hash: $hash, urls: $urls} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Add peers
#
# POST /torrents/addPeers
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#add-peers — WebUI-API on qBittorrent wiki
# operationId: torrentsAddPeersPost
export def "torrents-add-peers torrentsAddPeersPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hashes: list # The hash of the torrent, or multiple hashes separated by a pipe `|`
  peers: list # The peer to add, or multiple peers separated by a pipe `|`. Each peer is a colon-separated `host:port`
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/addPeers")
  let body = {hashes: $hashes, peers: $peers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Increase torrent priority
#
# POST /torrents/increasePrio
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#increase-torrent-priority — WebUI-API on qBittorrent wiki
# operationId: torrentsIncreasePrioPost
export def "torrents-increase-prio torrentsIncreasePrioPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hashes: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/increasePrio")
  let body = {hashes: $hashes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Decrease torrent priority
#
# POST /torrents/decreasePrio
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#decrease-torrent-priority — WebUI-API on qBittorrent wiki
# operationId: torrentsDecreasePrioPost
export def "torrents-decrease-prio torrentsDecreasePrioPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hashes: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/decreasePrio")
  let body = {hashes: $hashes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Maximal torrent priority
#
# POST /torrents/topPrio
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#maximal-torrent-priority — WebUI-API on qBittorrent wiki
# operationId: torrentsTopPrioPost
export def "torrents-top-prio torrentsTopPrioPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hashes: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/topPrio")
  let body = {hashes: $hashes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Minimal torrent priority
#
# POST /torrents/bottomPrio
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#minimal-torrent-priority — WebUI-API on qBittorrent wiki
# operationId: torrentsBottomPrioPost
export def "torrents-bottom-prio torrentsBottomPrioPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hashes: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/bottomPrio")
  let body = {hashes: $hashes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set file priority
#
# POST /torrents/filePrio
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#set-file-priority — WebUI-API on qBittorrent wiki
# operationId: torrentsFilePrioPost
export def "torrents-file-prio torrentsFilePrioPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hash: string # The hash of the torrent
  id: list # File ids, separated by `|`
  priority: int@priority-completer # File priority to set (consult [torrent contents API](https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#get-torrent-contents) for possible values) (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/filePrio")
  let body = {hash: $hash, id: $id, priority: $priority} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get torrent download limit
#
# POST /torrents/downloadLimit
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#get-torrent-download-limit — WebUI-API on qBittorrent wiki
# operationId: torrentsDownloadLimitPost
export def "torrents-download-limit torrentsDownloadLimitPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hashes: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/downloadLimit")
  let body = {hashes: $hashes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set torrent download limit
#
# POST /torrents/setDownloadLimit
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#set-torrent-download-limit — WebUI-API on qBittorrent wiki
# operationId: torrentsSetDownloadLimitPost
export def "torrents-set-download-limit torrentsSetDownloadLimitPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hashes: list
  limit: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/setDownloadLimit")
  let body = {hashes: $hashes, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set torrent share limit
#
# POST /torrents/setShareLimits
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#set-torrent-share-limit — WebUI-API on qBittorrent wiki
# operationId: torrentsSetShareLimitsPost
export def "torrents-set-share-limits torrentsSetShareLimitsPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hashes: list
  ratioLimit: float # `ratioLimit` is the max ratio the torrent should be seeded until. `-2` means the global limit should be used, -1 means no limit. (format: float)
  seedingTimeLimit: float # `seedingTimeLimit` is the max amount of time the torrent should be seeded. `-2` means the global limit should be used, `-1` means no limit. (format: float)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/setShareLimits")
  let body = {hashes: $hashes, ratioLimit: $ratioLimit, seedingTimeLimit: $seedingTimeLimit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get torrent upload limit
#
# POST /torrents/uploadLimit
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#get-torrent-upload-limit — WebUI-API on qBittorrent wiki
# operationId: torrentsUploadLimitPost
export def "torrents-upload-limit torrentsUploadLimitPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hashes: list
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/uploadLimit")
  let body = {hashes: $hashes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set torrent upload limit
#
# POST /torrents/setUploadLimit
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#set-torrent-upload-limit — WebUI-API on qBittorrent wiki
# operationId: torrentsSetUploadLimitPost
export def "torrents-set-upload-limit torrentsSetUploadLimitPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hashes: list
  limit: int # format: int64
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/setUploadLimit")
  let body = {hashes: $hashes, limit: $limit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set torrent location
#
# POST /torrents/setLocation
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#set-torrent-location — WebUI-API on qBittorrent wiki
# operationId: torrentsSetLocationPost
export def "torrents-set-location torrentsSetLocationPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hashes: list
  location: string # `location` is the location to download the torrent to. If the location doesn't exist, the torrent's location is unchanged.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/setLocation")
  let body = {hashes: $hashes, location: $location} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set torrent name
#
# POST /torrents/rename
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#set-torrent-name — WebUI-API on qBittorrent wiki
# operationId: torrentsRenamePost
export def "torrents-rename torrentsRenamePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hash: string # e.g. 8c212779b4abde7c6bc608063a0d008b7e40ce32
  name: string # e.g. This%20is%20a%20test
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/rename")
  let body = {hash: $hash, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set torrent category
#
# POST /torrents/setCategory
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#set-torrent-category — WebUI-API on qBittorrent wiki
# operationId: torrentsSetCategoryPost
export def "torrents-set-category torrentsSetCategoryPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hashes: list
  category: string # `category` is the torrent category you want to set.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/setCategory")
  let body = {hashes: $hashes, category: $category} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get all categories
#
# GET /torrents/categories
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#get-all-categories — WebUI-API on qBittorrent wiki
# operationId: torrentsCategoriesGet
export def "torrents-categories torrentsCategoriesGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/categories")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add new category
#
# POST /torrents/createCategory
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#add-new-category — WebUI-API on qBittorrent wiki
# operationId: torrentsCreateCategoryPost
export def "torrents-create-category torrentsCreateCategoryPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  category: string
  savePath: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/createCategory")
  let body = {category: $category, savePath: $savePath} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Edit category
#
# POST /torrents/editCategory
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#edit-category — WebUI-API on qBittorrent wiki
# operationId: torrentsEditCategoryPost
export def "torrents-edit-category torrentsEditCategoryPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  category: string
  savePath: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/editCategory")
  let body = {category: $category, savePath: $savePath} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove categories
#
# POST /torrents/removeCategories
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#remove-categories — WebUI-API on qBittorrent wiki
# operationId: torrentsRemoveCategoriesPost
export def "torrents-remove-categories torrentsRemoveCategoriesPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  categories: string # `categories` can contain multiple cateogies separated by `\n` (%0A urlencoded) (e.g. Category1%0ACategory2)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/removeCategories")
  let body = {categories: $categories} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Add torrent tags
#
# POST /torrents/addTags
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#add-torrent-tags — WebUI-API on qBittorrent wiki
# operationId: torrentsAddTagsPost
export def "torrents-add-tags torrentsAddTagsPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hashes: list
  tags: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/addTags")
  let body = {hashes: $hashes, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove torrent tags
#
# POST /torrents/removeTags
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#remove-torrent-tags — WebUI-API on qBittorrent wiki
# operationId: torrentsRemoveTagsPost
export def "torrents-remove-tags torrentsRemoveTagsPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hashes: list
  tags: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/removeTags")
  let body = {hashes: $hashes, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get all tags
#
# GET /torrents/tags
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#get-all-tags — WebUI-API on qBittorrent wiki
# operationId: torrentsTagsGet
export def "torrents-tags torrentsTagsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create tags
#
# POST /torrents/createTags
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#create-tags — WebUI-API on qBittorrent wiki
# operationId: torrentsCreateTagsPost
export def "torrents-create-tags torrentsCreateTagsPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  tags: list # `tags` is a list of tags you want to create. Can contain multiple tags separated by `,`. (e.g. [TagName1, TagName2])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/createTags")
  let body = {tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete tags
#
# POST /torrents/deleteTags
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#delete-tags — WebUI-API on qBittorrent wiki
# operationId: torrentsDeleteTagsPost
export def "torrents-delete-tags torrentsDeleteTagsPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  tags: list # `tags` is a list of tags you want to delete. Can contain multiple tags separated by `,`. (e.g. [TagName1, TagName2])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/deleteTags")
  let body = {tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set automatic torrent management
#
# POST /torrents/setAutoManagement
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#set-automatic-torrent-management — WebUI-API on qBittorrent wiki
# operationId: torrentsSetAutoManagementPost
export def "torrents-set-auto-management torrentsSetAutoManagementPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hashes: list
  --enable: string@bool-completer # `enable` is a boolean, affects the torrents listed in `hashes`, default is `false` (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/setAutoManagement")
  let body = {hashes: $hashes, enable: $enable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Toggle sequential download
#
# POST /torrents/toggleSequentialDownload
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#toggle-sequential-download — WebUI-API on qBittorrent wiki
# operationId: torrentsToggleSequentialDownloadPost
export def "torrents-toggle-sequential-download torrentsToggleSequentialDownloadPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hashes: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/toggleSequentialDownload")
  let body = {hashes: $hashes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set first/last piece priority
#
# POST /torrents/toggleFirstLastPiecePrio
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#set-firstlast-piece-priority — WebUI-API on qBittorrent wiki
# operationId: torrentsToggleFirstLastPiecePrioPost
export def "torrents-toggle-first-last-piece-prio torrentsToggleFirstLastPiecePrioPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hashes: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/toggleFirstLastPiecePrio")
  let body = {hashes: $hashes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set force start
#
# POST /torrents/setForceStart
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#set-force-start — WebUI-API on qBittorrent wiki
# operationId: torrentsSetForceStartPost
export def "torrents-set-force-start torrentsSetForceStartPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hashes: list
  --value: string@bool-completer # `value` is a boolean, affects the torrents listed in `hashes`, default is `false` (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/setForceStart")
  let body = {hashes: $hashes, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set super seeding
#
# POST /torrents/setSuperSeeding
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#set-super-seeding — WebUI-API on qBittorrent wiki
# operationId: torrentsSetSuperSeedingPost
export def "torrents-set-super-seeding torrentsSetSuperSeedingPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hashes: list
  --value: string@bool-completer # `value` is a boolean, affects the torrents listed in `hashes`, default is `false` (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/setSuperSeeding")
  let body = {hashes: $hashes, value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Rename file
#
# POST /torrents/renameFile
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#rename-file — WebUI-API on qBittorrent wiki
# operationId: torrentsRenameFilePost
export def "torrents-rename-file torrentsRenameFilePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hash: string # The hash of the torrent
  oldPath: string # The old path of the torrent
  newPath: string # The new path to use for the file
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/renameFile")
  let body = {hash: $hash, oldPath: $oldPath, newPath: $newPath} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Rename folder
#
# POST /torrents/renameFolder
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#rename-folder — WebUI-API on qBittorrent wiki
# operationId: torrentsRenameFolderPost
export def "torrents-rename-folder torrentsRenameFolderPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  hash: string # The hash of the torrent
  oldPath: string # The old path of the torrent
  newPath: string # The new path to use for the file
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/torrents/renameFolder")
  let body = {hash: $hash, oldPath: $oldPath, newPath: $newPath} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Add folder
#
# POST /rss/addFolder
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#add-folder — WebUI-API on qBittorrent wiki
# operationId: rssAddFolderPost
export def "rss-add-folder rssAddFolderPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  path: string # Full path of added folder (e.g. "The Pirate Bay\Top100")
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rss/addFolder")
  let body = {path: $path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Add feed
#
# POST /rss/addFeed
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#add-feed — WebUI-API on qBittorrent wiki
# operationId: rssAddFeedPost
export def "rss-add-feed rssAddFeedPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-url: string # URL of RSS feed (e.g. "http://thepiratebay.org/rss//top100/200")
  --path: string # Full path of added folder (e.g. "The Pirate Bay\Top100\Video")
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rss/addFeed")
  let body = {url: $body_url, path: $path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove item
#
# POST /rss/removeItem
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#remove-item — WebUI-API on qBittorrent wiki
# operationId: rssRemoveItemPost
export def "rss-remove-item rssRemoveItemPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  path: string # Full path of removed item (e.g. "The Pirate Bay\Top100")
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rss/removeItem")
  let body = {path: $path} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Move item
#
# POST /rss/moveItem
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#move-item — WebUI-API on qBittorrent wiki
# operationId: rssMoveItemPost
export def "rss-move-item rssMoveItemPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  itemPath: string # Current full path of item (e.g. "The Pirate Bay\Top100")
  destPath: string # New full path of item (e.g. "The Pirate Bay")
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rss/moveItem")
  let body = {itemPath: $itemPath, destPath: $destPath} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get all items
#
# POST /rss/items
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#get-all-items — WebUI-API on qBittorrent wiki
# operationId: rssItemsPost
export def "rss-items rssItemsPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --withData: string@bool-completer # True if you need current feed articles
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rss/items")
  let body = {withData: $withData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Mark as read
#
# POST /rss/markAsRead
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#mark-as-read — WebUI-API on qBittorrent wiki
# operationId: rssMarkAsReadPost
export def "rss-mark-as-read rssMarkAsReadPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  itemPath: string # Current full path of item (e.g. "The Pirate Bay\Top100")
  --articleId: string # ID of article
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rss/markAsRead")
  let body = {itemPath: $itemPath, articleId: $articleId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Refresh item
#
# POST /rss/refreshItem
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#refresh-item — WebUI-API on qBittorrent wiki
# operationId: rssRefreshItemPost
export def "rss-refresh-item rssRefreshItemPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  itemPath: string # Current full path of item (e.g. "The Pirate Bay\Top100")
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rss/refreshItem")
  let body = {itemPath: $itemPath} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Set auto-downloading rule
#
# POST /rss/setRule
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#set-auto-downloading-rule — WebUI-API on qBittorrent wiki
# operationId: rssSetRulePost
# --ruleDef shape: {enabled?: bool, mustContain?: string, mustNotContain?: string, useRegex?: bool, episodeFilter?: string, smartFilter?: bool, previouslyMatchedEpisodes?: list, affectedFeeds?: list, ignoreDays?: float, lastMatch?: string, addPaused?: bool, assignedCategory?: string, savePath?: string}
export def "rss-set-rule rssSetRulePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ruleName: string # Rule name (e.g. "Punisher")
  ruleDef: record # JSON encoded rule definition  Rule definition is JSON encoded dictionary with the following fields: | Field                     | Type   | Description                                             | | ------------------------- | ------ | ------------------------------------------------------- | | enabled                   | bool   | Whether the rule is enabled                             | | mustContain               | string | The substring that the torrent name must contain        | | mustNotContain            | string | The substring that the torrent name must not contain    | | useRegex                  | bool   | Enable regex mode in "mustContain" and "mustNotContain" | | episodeFilter             | string | Episode filter definition                               | | smartFilter               | bool   | Enable smart episode filter                             | | previouslyMatchedEpisodes | list   | The list of episode IDs already matched by smart filter | | affectedFeeds             | list   | The feed URLs the rule applied to                       | | ignoreDays                | number | Ignore sunsequent rule matches                          | | lastMatch                 | string | The rule last match time                                | | addPaused                 | bool   | Add matched torrent in paused mode                      | | assignedCategory          | string | Assign category to the torrent                          | | savePath                  | string | Save torrent to the given directory                     | — shape: {enabled?: bool, mustContain?: string, mustNotContain?: string, useRegex?: bool, episodeFilter?: string, smartFilter?: bool, previouslyMatchedEpisodes?: list, affectedFeeds?: list, ignoreDays?: float, lastMatch?: string, addPaused?: bool, assignedCategory?: string, savePath?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rss/setRule")
  let body = {ruleName: $ruleName, ruleDef: $ruleDef} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Rename auto-downloading rule
#
# POST /rss/renameRule
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#rename-auto-downloading-rule — WebUI-API on qBittorrent wiki
# operationId: rssRenameRulePost
export def "rss-rename-rule rssRenameRulePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ruleName: string # Rule name (e.g. "Punisher")
  newRuleName: string # New rule name (e.g. "The Punisher")
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rss/renameRule")
  let body = {ruleName: $ruleName, newRuleName: $newRuleName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove auto-downloading rule
#
# POST /rss/removeRule
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#remove-auto-downloading-rule — WebUI-API on qBittorrent wiki
# operationId: rssRemoveRulePost
export def "rss-remove-rule rssRemoveRulePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ruleName: string # Rule name (e.g. "Punisher")
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rss/removeRule")
  let body = {ruleName: $ruleName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get all auto-downloading rules
#
# GET /rss/rules
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#get-all-auto-downloading-rules — WebUI-API on qBittorrent wiki
# operationId: rssRulesGet
export def "rss-rules rssRulesGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rss/rules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get all articles matching a rule
#
# POST /rss/matchingArticles
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#get-all-articles-matching-a-rule — WebUI-API on qBittorrent wiki
# operationId: rssMatchingArticlesPost
export def "rss-matching-articles rssMatchingArticlesPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  ruleName: string # Rule name (e.g. "Linux")
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/rss/matchingArticles")
  let body = {ruleName: $ruleName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Start search
#
# POST /search/start
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#start-search — WebUI-API on qBittorrent wiki
# operationId: searchStartPost
export def "search-start searchStartPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  pattern: string # Pattern to search for (e.g. "Ubuntu 18.04")
  plugins: list # Plugins to use for searching (e.g. "legittorrents"). Supports multiple plugins separated by `|`. Also supports `all` and `enabled`
  category: list # Categories to limit your search to (e.g. "legittorrents"). Available categories depend on the specified `plugins`. Also supports `all`
]: any -> record<id: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/search/start")
  let body = {pattern: $pattern, plugins: $plugins, category: $category} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Stop search
#
# POST /search/stop
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#stop-search — WebUI-API on qBittorrent wiki
# operationId: searchStopPost
export def "search-stop searchStopPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: float # ID of the search job
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/search/stop")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get search status
#
# POST /search/status
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#get-search-status — WebUI-API on qBittorrent wiki
# operationId: searchStatusPost
export def "search-status searchStatusPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --id: float # ID of the search job. If not specified, all search jobs are returned
]: any -> table<id: float, status: string, total: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/search/status")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get search results
#
# POST /search/results
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#get-search-results — WebUI-API on qBittorrent wiki
# operationId: searchResultsPost
export def "search-results searchResultsPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: float # ID of the search job
  --limit: float # max number of results to return. 0 or negative means no limit
  --offset: float # result to start at. A negative number means count backwards (e.g. -2 returns the 2 most recent results)
]: any -> record<results: table<descrLink: string, fileName: string, fileSize: float, fileUrl: string, nbLeechers: float, nbSeeders: float, siteUrl: string>, status: string, total: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/search/results")
  let body = {id: $id, limit: $limit, offset: $offset} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete search
#
# POST /search/delete
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#delete-search — WebUI-API on qBittorrent wiki
# operationId: searchDeletePost
export def "search-delete searchDeletePost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  id: float # ID of the search job
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/search/delete")
  let body = {id: $id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Get search plugins
#
# GET /search/plugins
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#get-search-plugins — WebUI-API on qBittorrent wiki
# operationId: searchPluginsGet
export def "search-plugins searchPluginsGet" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<enabled: bool, fullName: string, name: string, supportedCategories: list<record>, url: string, version: string> {
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/search/plugins")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Install search plugin
#
# POST /search/installPlugin
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#install-search-plugin — WebUI-API on qBittorrent wiki
# operationId: searchInstallPluginPost
export def "search-install-plugin searchInstallPluginPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  sources: list # Url or file path of the plugin to install (e.g. "https://raw.githubusercontent.com/qbittorrent/search-plugins/master/nova3/engines/legittorrents.py"). Supports multiple sources separated by `|`
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/search/installPlugin")
  let body = {sources: $sources} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Uninstall search plugin
#
# POST /search/uninstallPlugin
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#uninstall-search-plugin — WebUI-API on qBittorrent wiki
# operationId: searchUninstallPluginPost
export def "search-uninstall-plugin searchUninstallPluginPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  names: list # Name of the plugin to uninstall (e.g. "legittorrents"). Supports multiple names separated by `|`
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/search/uninstallPlugin")
  let body = {names: $names} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Enable search plugin
#
# POST /search/enablePlugin
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#enable-search-plugin — WebUI-API on qBittorrent wiki
# operationId: searchEnablePluginPost
export def "search-enable-plugin searchEnablePluginPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  names: list # Name of the plugin to enable/disable (e.g. "legittorrents"). Supports multiple names separated by `|`
  --enable: string@bool-completer # Whether the plugins should be enabled
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/search/enablePlugin")
  let body = {names: $names, enable: $enable} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Update search plugins
#
# POST /search/updatePlugins
# Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)#update-search-plugins — WebUI-API on qBittorrent wiki
# operationId: searchUpdatePluginsPost
export def "search-update-plugins searchUpdatePluginsPost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "cookie-SID"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/search/updatePlugins")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
