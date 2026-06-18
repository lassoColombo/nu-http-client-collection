# Auto-generated client for Stream Chat API vv79.19.1
# Source: https://api.apis.guru/v2/specs/stream-io-api.com/v79.19.1/openapi.json
# Auth: --token flag or $env.STREAM_CHAT_API_TOKEN

const BASE_URL = "https://chat.stream-io-api.com"
const DEFAULT_AUTH = "jwt"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o STREAM_CHAT_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "jwt" => { {headers: {Authorization: $"JWT ($token_val)"}, query: ""} }
    "query-api_key" => { {headers: {}, query: $"(encode-path-segment "api_key")=(encode-path-segment $token_val)"} }
    "stream-auth-type" => { {headers: {Stream-Auth-Type: $token_val}, query: ""} }
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

# Build a `multipart/form-data` envelope per RFC 7578. `file_fields` lists
# the field names whose value should be read from disk as bytes; every
# other field is sent as a text part (records/lists JSON-stringified).
# Returns {content_type, body} ready to pass to `do-request`.
# When `$dry_run` is true, file fields are NOT read from disk — they emit
# an empty-bytes placeholder so callers can inspect the request shape
# without the file existing on disk (issue 11.B).
def build-multipart-body [parts: record, file_fields: list<string>, dry_run: bool = false]: nothing -> record {
  let boundary = $"----nu-(random chars --length 24)"
  let crlf = "\r\n"
  let chunks = ($parts | items {|name, val|
    if $val == null { null } else if $name in $file_fields {
      let filename = ($val | into string | path basename)
      let bytes = if $dry_run { (0x[] | into binary) } else { (open --raw $val | into binary | collect) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"; filename=\"($filename)\"($crlf)Content-Type: application/octet-stream($crlf)($crlf)" | into binary)
      $head ++ $bytes ++ ($crlf | into binary)
    } else {
      let dt = ($val | describe)
      let s = if (($dt | str starts-with "record") or ($dt | str starts-with "list") or ($dt | str starts-with "table")) { ($val | to json --raw) } else { ($val | into string) }
      let head = ($"--($boundary)($crlf)Content-Disposition: form-data; name=\"($name)\"($crlf)($crlf)" | into binary)
      $head ++ ($"($s)($crlf)" | into binary)
    }
  } | compact)
  let trailer = ($"--($boundary)--($crlf)" | into binary)
  let body = ($chunks | reduce --fold (0x[] | into binary) {|chunk, acc| $acc ++ $chunk }) ++ $trailer
  {content_type: $"multipart/form-data; boundary=($boundary)", body: $body}
}

def base-url-completer [] { ["https://chat.stream-io-api.com" "http://localhost:3030"] }
def auth-scheme-completer [] { ["jwt" "query-api_key" "stream-auth-type"] }

# Completers for enum parameters
def enforce-unique-usernames-completer [] { ["app" "no" "team"] }
def permission-version-completer [] { ["v1" "v2"] }
def video-provider-completer [] { ["agora" "hms"] }
def type-completer [] { ["audio" "video"] }
def automod-completer [] { ["AI" "disabled" "simple"] }
def automod-behavior-completer [] { ["block" "flag"] }
def blocklist-behavior-completer [] { ["block" "flag"] }
def push-provider-type-completer [] { ["apn" "firebase" "huawei" "xiaomi"] }
def push-provider-completer [] { ["apn" "firebase" "huawei" "xiaomi"] }
def mode-completer [] { ["insert" "upsert"] }
def language-completer [] { ["af" "am" "ar" "az" "bg" "bn" "bs" "cs" "da" "de" "el" "en" "es" "es-MX" "et" "fa" "fa-AF" "fi" "fr" "fr-CA" "ha" "he" "hi" "hr" "hu" "id" "it" "ja" "ka" "ko" "lv" "ms" "nl" "no" "pl" "ps" "pt" "ro" "ru" "sk" "sl" "so" "sq" "sr" "sv" "sw" "ta" "th" "tl" "tr" "uk" "ur" "vi" "zh" "zh-TW"] }
def conversations-completer [] { ["hard" "soft"] }
def messages-completer [] { ["hard" "pruning" "soft"] }
def user-completer [] { ["hard" "pruning" "soft"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "app get" } } | get name | first)
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

# Get App Settings
#
# GET /app
# operationId: GetApp
export def "app get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<app: record<agora_options: record<app_certificate: string, app_id: string, default_role: string, role_map: record>, async_url_enrich_enabled: bool, auto_translation_enabled: bool, before_message_send_hook_url: string, campaign_enabled: bool, cdn_expiration_seconds: float, channel_configs: record, custom_action_handler_url: string, disable_auth_checks: bool, disable_permissions_checks: bool, enforce_unique_usernames: string, file_upload_config: record<allowed_file_extensions: list, allowed_mime_types: list, blocked_file_extensions: list, blocked_mime_types: list>, grants: record, hms_options: record<app_certificate: string, app_id: string, default_role: string, role_map: record>, image_moderation_enabled: bool, image_moderation_labels: list<string>, image_upload_config: record<allowed_file_extensions: list, allowed_mime_types: list, blocked_file_extensions: list, blocked_mime_types: list>, multi_tenant_enabled: bool, name: string, organization: string, permission_version: string, policies: record, push_notifications: record<apn: record, firebase: record, huawei: record, offline_only: bool, providers: list, version: string, xiaomi: record>, reminders_interval: float, revoke_tokens_issued_before: string, search_backend: string, sqs_key: string, sqs_secret: string, sqs_url: string, suspended: bool, suspended_explanation: string, user_search_disallowed_roles: list<string>, video_provider: string, webhook_events: list<string>, webhook_url: string>, duration: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/app")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update App Settings
#
# PATCH /app
# operationId: UpdateApp
# --agora_options shape: {app_certificate: string, app_id: string, default_role?: "attendee"|"publisher"|"subscriber"|"admin", role_map?: record}
# --apn_config shape: {Disabled?: bool, auth_key?: string, auth_type?: "certificate"|"token", bundle_id?: string, development?: bool, host?: string, key_id?: string, notification_template?: string, p12_cert?: string, team_id?: string}
# --async_moderation_config shape: {callback?: record, timeout_ms?: float}
# --file_upload_config shape: {allowed_file_extensions?: list<string>, allowed_mime_types?: list<string>, blocked_file_extensions?: list<string>, blocked_mime_types?: list<string>}
# --firebase_config shape: {Disabled?: bool, apn_template?: string, credentials_json?: string, data_template?: string, notification_template?: string, server_key?: string}
# --hms_options shape: {app_certificate: string, app_id: string, default_role?: "attendee"|"publisher"|"subscriber"|"admin", role_map?: record}
# --huawei_config shape: {Disabled?: bool, id?: string, secret?: string}
# --image_upload_config shape: {allowed_file_extensions?: list<string>, allowed_mime_types?: list<string>, blocked_file_extensions?: list<string>, blocked_mime_types?: list<string>}
# --push_config shape: {offline_only?: bool, version?: "v1"|"v2"}
# --xiaomi_config shape: {Disabled?: bool, package_name?: string, secret?: string}
export def "app update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --agora-options: record # shape: {app_certificate: string, app_id: string, default_role?: "attendee"|"publisher"|"subscriber"|"admin", role_map?: record}
  --apn-config: record # shape: {Disabled?: bool, auth_key?: string, auth_type?: "certificate"|"token", bundle_id?: string, development?: bool, host?: string, key_id?: string, notification_template?: string, p12_cert?: string, team_id?: string}
  --async-moderation-config: record # shape: {callback?: record, timeout_ms?: float}
  --async-url-enrich-enabled: oneof<nothing, bool>
  --auto-translation-enabled: oneof<nothing, bool>
  --before-message-send-hook-url: string
  --cdn-expiration-seconds: float
  --channel-hide-members-only: oneof<nothing, bool>
  --custom-action-handler-url: string
  --disable-auth-checks: oneof<nothing, bool>
  --disable-permissions-checks: oneof<nothing, bool>
  --enforce-unique-usernames: string@enforce-unique-usernames-completer
  --file-upload-config: record # shape: {allowed_file_extensions?: list<string>, allowed_mime_types?: list<string>, blocked_file_extensions?: list<string>, blocked_mime_types?: list<string>}
  --firebase-config: record # shape: {Disabled?: bool, apn_template?: string, credentials_json?: string, data_template?: string, notification_template?: string, server_key?: string}
  --grants: record
  --hms-options: record # shape: {app_certificate: string, app_id: string, default_role?: "attendee"|"publisher"|"subscriber"|"admin", role_map?: record}
  --huawei-config: record # shape: {Disabled?: bool, id?: string, secret?: string}
  --image-moderation-block-labels: list<string>
  --image-moderation-enabled: oneof<nothing, bool>
  --image-moderation-labels: list<string>
  --image-upload-config: record # shape: {allowed_file_extensions?: list<string>, allowed_mime_types?: list<string>, blocked_file_extensions?: list<string>, blocked_mime_types?: list<string>}
  --migrate-permissions-to-v2: oneof<nothing, bool>
  --multi-tenant-enabled: oneof<nothing, bool>
  --permission-version: string@permission-version-completer
  --push-config: record # shape: {offline_only?: bool, version?: "v1"|"v2"}
  --reminders-interval: float
  --revoke-tokens-issued-before: string # format: date-time
  --sqs-key: string
  --sqs-secret: string
  --sqs-url: string
  --user-search-disallowed-roles: list<string>
  --video-provider: string@video-provider-completer
  --webhook-events: list<string>
  --webhook-url: string
  --xiaomi-config: record # shape: {Disabled?: bool, package_name?: string, secret?: string}
]: any -> record<duration: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/app")
  let req_body = {"agora_options": $agora_options, "apn_config": $apn_config, "async_moderation_config": $async_moderation_config, "async_url_enrich_enabled": $async_url_enrich_enabled, "auto_translation_enabled": $auto_translation_enabled, "before_message_send_hook_url": $before_message_send_hook_url, "cdn_expiration_seconds": $cdn_expiration_seconds, "channel_hide_members_only": $channel_hide_members_only, "custom_action_handler_url": $custom_action_handler_url, "disable_auth_checks": $disable_auth_checks, "disable_permissions_checks": $disable_permissions_checks, "enforce_unique_usernames": $enforce_unique_usernames, "file_upload_config": $file_upload_config, "firebase_config": $firebase_config, "grants": $grants, "hms_options": $hms_options, "huawei_config": $huawei_config, "image_moderation_block_labels": $image_moderation_block_labels, "image_moderation_enabled": $image_moderation_enabled, "image_moderation_labels": $image_moderation_labels, "image_upload_config": $image_upload_config, "migrate_permissions_to_v2": $migrate_permissions_to_v2, "multi_tenant_enabled": $multi_tenant_enabled, "permission_version": $permission_version, "push_config": $push_config, "reminders_interval": $reminders_interval, "revoke_tokens_issued_before": $revoke_tokens_issued_before, "sqs_key": $sqs_key, "sqs_secret": $sqs_secret, "sqs_url": $sqs_url, "user_search_disallowed_roles": $user_search_disallowed_roles, "video_provider": $video_provider, "webhook_events": $webhook_events, "webhook_url": $webhook_url, "xiaomi_config": $xiaomi_config} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List block lists
#
# GET /blocklists
# operationId: ListBlockLists
export def "blocklists list-block-lists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<blocklists: table<created_at: string, name: string, updated_at: string, words: list>, duration: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/blocklists")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create block list
#
# POST /blocklists
# operationId: CreateBlockList
export def "blocklists create-block-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Block list name
  words: list<string> # List of words to block
]: any -> record<duration: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/blocklists")
  let req_body = {"name": $name, "words": $words} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete block list
#
# DELETE /blocklists/{name}
# operationId: DeleteBlockList
export def "blocklists delete-block-list" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<duration: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/blocklists/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get block list
#
# GET /blocklists/{name}
# operationId: GetBlockList
export def "blocklists get-block-list" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<blocklist: record<created_at: string, name: string, updated_at: string, words: list<string>>, duration: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/blocklists/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update block list
#
# PUT /blocklists/{name}
# operationId: UpdateBlockList
export def "blocklists update-block-list" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-name: string
  --words: list<string>
]: any -> record<duration: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/blocklists/{name}"))
  let req_body = {"Name": $body_name, "words": $words} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get Call Token ()
#
# POST /calls/
# operationId: GetCallToken__1
# --user shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
export def "calls get-token-by-" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string # **Server-side only**. User ID which server acts upon
]: any -> record<agora_app_id: string, agora_uid: float, duration: string, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/calls/")
  let req_body = {"user": $user, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get Call Token (call_id)
#
# POST /calls/{call_id}
# operationId: GetCallToken_call_id_0
# --user shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
export def "calls get-token-by-call_id" [
  call_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string # **Server-side only**. User ID which server acts upon
]: any -> record<agora_app_id: string, agora_uid: float, duration: string, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({call_id: (encode-path-segment $call_id)} | format pattern "/calls/{call_id}"))
  let req_body = {"user": $user, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Query campaigns
#
# GET /campaigns
# operationId: QueryCampaigns
export def "campaigns list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payload: string
]: nothing -> record<campaigns: table<attachments: list, channel_type: string, completed_at: string, created_at: string, defaults: record, description: string, details: string, errored_messages: float, failed_at: string, id: string, name: string, resumed_at: string, scheduled_at: string, scheduled_for: string, segment_id: string, sender_id: string, sent_messages: float, status: string, stopped_at: string, task_id: string, text: string, updated_at: string>, channels: record, duration: string, segments: record, users: record> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payload" $payload "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/campaigns" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create campaign
#
# POST /campaigns
# operationId: CreateCampaign
# --campaign shape: {attachments?: list, channel_type?: string, defaults?: record, description?: string, name: string, segment_id: string, sender_id: string, text: string}
export def "campaigns create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  campaign: record # shape: {attachments?: list, channel_type?: string, defaults?: record, description?: string, name: string, segment_id: string, sender_id: string, text: string}
]: any -> record<campaign: record<attachments: list<record>, channel_type: string, completed_at: string, created_at: string, defaults: record, description: string, details: string, errored_messages: float, failed_at: string, id: string, name: string, resumed_at: string, scheduled_at: string, scheduled_for: string, segment_id: string, sender_id: string, sent_messages: float, status: string, stopped_at: string, task_id: string, text: string, updated_at: string>, duration: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/campaigns")
  let req_body = {"campaign": $campaign} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete campaign
#
# DELETE /campaigns/{id}
# operationId: DeleteCampaign
export def "campaigns delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --recipients: string
]: nothing -> record<duration: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recipients" $recipients "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/campaigns/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update campaign
#
# PUT /campaigns/{id}
# operationId: UpdateCampaign
# --campaign shape: {attachments?: list, channel_type?: string, defaults?: record, description?: string, name?: string, segment_id?: string, sender_id?: string, text?: string}
export def "campaigns update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  campaign: record # shape: {attachments?: list, channel_type?: string, defaults?: record, description?: string, name?: string, segment_id?: string, sender_id?: string, text?: string}
]: any -> record<campaign: record<attachments: list<record>, channel_type: string, completed_at: string, created_at: string, defaults: record, description: string, details: string, errored_messages: float, failed_at: string, id: string, name: string, resumed_at: string, scheduled_at: string, scheduled_for: string, segment_id: string, sender_id: string, sent_messages: float, status: string, stopped_at: string, task_id: string, text: string, updated_at: string>, duration: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/campaigns/{id}"))
  let req_body = {"campaign": $campaign} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Resume campaign
#
# PATCH /campaigns/{id}/resume
# operationId: ResumeCampaign
export def "campaigns-resume update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<campaign: record<attachments: list<record>, channel_type: string, completed_at: string, created_at: string, defaults: record, description: string, details: string, errored_messages: float, failed_at: string, id: string, name: string, resumed_at: string, scheduled_at: string, scheduled_for: string, segment_id: string, sender_id: string, sent_messages: float, status: string, stopped_at: string, task_id: string, text: string, updated_at: string>, duration: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/campaigns/{id}/resume"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Schedule campaign
#
# PATCH /campaigns/{id}/schedule
# operationId: ScheduleCampaign
export def "campaigns-schedule update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --scheduled-for: float
]: any -> record<campaign: record<attachments: list<record>, channel_type: string, completed_at: string, created_at: string, defaults: record, description: string, details: string, errored_messages: float, failed_at: string, id: string, name: string, resumed_at: string, scheduled_at: string, scheduled_for: string, segment_id: string, sender_id: string, sent_messages: float, status: string, stopped_at: string, task_id: string, text: string, updated_at: string>, duration: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/campaigns/{id}/schedule"))
  let req_body = {"scheduled_for": $scheduled_for} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Stop campaign
#
# PATCH /campaigns/{id}/stop
# operationId: StopCampaign
export def "campaigns-stop stop" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<campaign: record<attachments: list<record>, channel_type: string, completed_at: string, created_at: string, defaults: record, description: string, details: string, errored_messages: float, failed_at: string, id: string, name: string, resumed_at: string, scheduled_at: string, scheduled_for: string, segment_id: string, sender_id: string, sent_messages: float, status: string, stopped_at: string, task_id: string, text: string, updated_at: string>, duration: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/campaigns/{id}/stop"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Test campaign
#
# POST /campaigns/{id}/test
# operationId: TestCampaign
export def "campaigns-test test" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  users: list<string>
]: any -> record<details: string, duration: string, results: record, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/campaigns/{id}/test"))
  let req_body = {"users": $users} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Query channels
#
# POST /channels
# operationId: QueryChannels
# --sort item shape: {direction?: float, field?: string}
# --user shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
export def "channels list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string
  --connection-id: string
  --client-id: string
  --connection-id: string
  --filter-conditions: record
  --limit: float # Number of channels to limit
  --member-limit: float # Number of members to limit
  --message-limit: float # Number of messages to limit
  --offset: float # Channel pagination offset
  --presence: oneof<nothing, bool>
  --body-sort: list # List of sort parameters — item shape: {direction?: float, field?: string}
  --state: oneof<nothing, bool> # Whether to update channel state or not
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
  --watch: oneof<nothing, bool> # Whether to start watching found channels or not
]: any -> record<channels: table<channel: record, hidden: bool, hide_messages_before: string, members: list, membership: record, messages: list, pending_messages: list, pinned_messages: list, read: list, watcher_count: float, watchers: list>, duration: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_id" $client_id "scalar") (serialize-qp "connection_id" $connection_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/channels" $qp)
  let req_body = {"client_id": $client_id, "connection_id": $connection_id, "filter_conditions": $filter_conditions, "limit": $limit, "member_limit": $member_limit, "message_limit": $message_limit, "offset": $offset, "presence": $presence, "sort": $body_sort, "state": $state, "user": $user, "user_id": $user_id, "watch": $watch} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deletes channels asynchronously
#
# POST /channels/delete
# operationId: DeleteChannels
export def "channels-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --cids: list<string> # All channels that should be deleted
  --hard-delete: oneof<nothing, bool> # Specify if channels and all ressources should be hard deleted
]: any -> record<duration: string, result: record, task_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/channels/delete")
  let req_body = {"cids": $cids, "hard_delete": $hard_delete} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Mark channels as read
#
# POST /channels/read
# operationId: MarkChannelsRead
# --user shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
export def "channels-read get-mark" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> record<duration: string, event: record<automoderation: bool, automoderation_scores: record<action: string, explicit: float, spam: float, toxic: float>, channel: record<auto_translation_enabled: bool, auto_translation_language: string, cid: string, config: record, cooldown: float, created_at: string, created_by: record, deleted_at: string, disabled: bool, frozen: bool, hidden: bool, hide_messages_before: string, id: string, last_message_at: string, member_count: float, members: list, mute_expires_at: string, muted: bool, own_capabilities: list, team: string, truncated_at: string, truncated_by: record, type: string, updated_at: string>, channel_id: string, channel_type: string, cid: string, connection_id: string, created_at: string, created_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, me: record<banned: bool, channel_mutes: list, created_at: string, deactivated_at: string, deleted_at: string, devices: list, id: string, invisible: bool, language: string, last_active: string, latest_hidden_channels: list, mutes: list, online: bool, push_notifications: record, role: string, teams: list, total_unread_count: float, unread_channels: float, unread_count: float, updated_at: string>, member: record<ban_expires: string, banned: bool, channel_role: string, created_at: string, deleted_at: string, invite_accepted_at: string, invite_rejected_at: string, invited: bool, is_moderator: bool, role: string, shadow_banned: bool, updated_at: string, user: record, user_id: string>, message: record<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>, parent_id: string, reaction: record<created_at: string, message_id: string, score: float, type: string, updated_at: string, user: record, user_id: string>, reason: string, team: string, type: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, user_id: string, watcher_count: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/channels/read")
  let req_body = {"user": $user, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get or create channel (type)
#
# POST /channels/{type}/query
# operationId: GetOrCreateChannel_type_1
# --data shape: {auto_translation_enabled?: bool, auto_translation_language?: string, config_overrides?: record, created_by?: record, disabled?: bool, frozen?: bool, members?: list, own_capabilities?: list<float>, team?: string, truncated_at?: list<float>, truncated_by?: list<float>, truncated_by_id?: string}
# --members shape: {id_gt?: float, id_gte?: float, id_lt?: float, id_lte?: float, limit?: float, offset?: float}
# --messages shape: {created_at_after?: string, created_at_after_or_equal?: string, created_at_around?: string, created_at_before?: string, created_at_before_or_equal?: string, id_around?: string, id_gt?: string, id_gte?: string, id_lt?: string, id_lte?: string, limit?: float, offset?: float}
# --watchers shape: {id_gt?: float, id_gte?: float, id_lt?: float, id_lte?: float, limit?: float, offset?: float}
export def "channels-query get-or-create-by-type" [
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string
  --connection-id: string
  --client-id: string
  --connection-id: string
  --data: record # shape: {auto_translation_enabled?: bool, auto_translation_language?: string, config_overrides?: record, created_by?: record, disabled?: bool, frozen?: bool, members?: list, own_capabilities?: list<float>, team?: string, truncated_at?: list<float>, truncated_by?: list<float>, truncated_by_id?: string}
  --members: record # shape: {id_gt?: float, id_gte?: float, id_lt?: float, id_lte?: float, limit?: float, offset?: float}
  --messages: record # shape: {created_at_after?: string, created_at_after_or_equal?: string, created_at_around?: string, created_at_before?: string, created_at_before_or_equal?: string, id_around?: string, id_gt?: string, id_gte?: string, id_lt?: string, id_lte?: string, limit?: float, offset?: float}
  --presence: oneof<nothing, bool> # Fetch user presence info
  --state: oneof<nothing, bool> # Refresh channel state
  --watch: oneof<nothing, bool> # Start watching the channel
  --watchers: record # shape: {id_gt?: float, id_gte?: float, id_lt?: float, id_lte?: float, limit?: float, offset?: float}
]: any -> record<channel: record<auto_translation_enabled: bool, auto_translation_language: string, cid: string, config: record<automod: string, automod_behavior: string, automod_thresholds: record, blocklist: string, blocklist_behavior: string, commands: list, connect_events: bool, created_at: string, custom_events: bool, grants: record, max_message_length: float, message_retention: string, mutes: bool, name: string, push_notifications: bool, quotes: bool, reactions: bool, read_events: bool, reminders: bool, replies: bool, search: bool, typing_events: bool, updated_at: string, uploads: bool, url_enrichment: bool>, cooldown: float, created_at: string, created_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, deleted_at: string, disabled: bool, frozen: bool, hidden: bool, hide_messages_before: string, id: string, last_message_at: string, member_count: float, members: list<record>, mute_expires_at: string, muted: bool, own_capabilities: list<string>, team: string, truncated_at: string, truncated_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, type: string, updated_at: string>, duration: string, hidden: bool, hide_messages_before: string, members: table<ban_expires: string, banned: bool, channel_role: string, created_at: string, deleted_at: string, invite_accepted_at: string, invite_rejected_at: string, invited: bool, is_moderator: bool, role: string, shadow_banned: bool, updated_at: string, user: record, user_id: string>, membership: record<ban_expires: string, banned: bool, channel_role: string, created_at: string, deleted_at: string, invite_accepted_at: string, invite_rejected_at: string, invited: bool, is_moderator: bool, role: string, shadow_banned: bool, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, user_id: string>, messages: table<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>, pending_messages: table<channel: record, message: record, metadata: record, user: record>, pinned_messages: table<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>, read: table<last_read: string, unread_messages: float, user: record>, watcher_count: float, watchers: table<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_id" $client_id "scalar") (serialize-qp "connection_id" $connection_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type: (encode-path-segment $type)} | format pattern "/channels/{type}/query") $qp)
  let req_body = {"client_id": $client_id, "connection_id": $connection_id, "data": $data, "members": $members, "messages": $messages, "presence": $presence, "state": $state, "watch": $watch, "watchers": $watchers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete channel
#
# DELETE /channels/{type}/{id}
# operationId: DeleteChannel
export def "channels delete" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hard-delete: string
]: nothing -> record<channel: record<auto_translation_enabled: bool, auto_translation_language: string, cid: string, config: record<automod: string, automod_behavior: string, automod_thresholds: record, blocklist: string, blocklist_behavior: string, commands: list, connect_events: bool, created_at: string, custom_events: bool, grants: record, max_message_length: float, message_retention: string, mutes: bool, name: string, push_notifications: bool, quotes: bool, reactions: bool, read_events: bool, reminders: bool, replies: bool, search: bool, typing_events: bool, updated_at: string, uploads: bool, url_enrichment: bool>, cooldown: float, created_at: string, created_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, deleted_at: string, disabled: bool, frozen: bool, hidden: bool, hide_messages_before: string, id: string, last_message_at: string, member_count: float, members: list<record>, mute_expires_at: string, muted: bool, own_capabilities: list<string>, team: string, truncated_at: string, truncated_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, type: string, updated_at: string>, duration: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hard_delete" $hard_delete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type: (encode-path-segment $type), id: (encode-path-segment $id)} | format pattern "/channels/{type}/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Partially update channel
#
# PATCH /channels/{type}/{id}
# operationId: UpdateChannelPartial
# --user shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
export def "channels update-partial" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  set: record
  unset: list<string>
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> record<channel: record<auto_translation_enabled: bool, auto_translation_language: string, cid: string, config: record<automod: string, automod_behavior: string, automod_thresholds: record, blocklist: string, blocklist_behavior: string, commands: list, connect_events: bool, created_at: string, custom_events: bool, grants: record, max_message_length: float, message_retention: string, mutes: bool, name: string, push_notifications: bool, quotes: bool, reactions: bool, read_events: bool, reminders: bool, replies: bool, search: bool, typing_events: bool, updated_at: string, uploads: bool, url_enrichment: bool>, cooldown: float, created_at: string, created_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, deleted_at: string, disabled: bool, frozen: bool, hidden: bool, hide_messages_before: string, id: string, last_message_at: string, member_count: float, members: list<record>, mute_expires_at: string, muted: bool, own_capabilities: list<string>, team: string, truncated_at: string, truncated_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, type: string, updated_at: string>, duration: string, members: table<ban_expires: string, banned: bool, channel_role: string, created_at: string, deleted_at: string, invite_accepted_at: string, invite_rejected_at: string, invited: bool, is_moderator: bool, role: string, shadow_banned: bool, updated_at: string, user: record, user_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type: (encode-path-segment $type), id: (encode-path-segment $id)} | format pattern "/channels/{type}/{id}"))
  let req_body = {"set": $set, "unset": $unset, "user": $user, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Update channel
#
# POST /channels/{type}/{id}
# operationId: UpdateChannel
# --add_members item shape: {ban_expires?: string, banned?: bool, channel_role?: string, created_at?: string, deleted_at?: string, invite_accepted_at?: string, invite_rejected_at?: string, invited?: bool, is_moderator?: bool, role?: "member"|"moderator"|"admin"|"owner", shadow_banned?: bool, updated_at?: string, user?: record, user_id?: string}
# --assign_roles item shape: {ban_expires?: string, banned?: bool, channel_role?: string, created_at?: string, deleted_at?: string, invite_accepted_at?: string, invite_rejected_at?: string, invited?: bool, is_moderator?: bool, role?: "member"|"moderator"|"admin"|"owner", shadow_banned?: bool, updated_at?: string, user?: record, user_id?: string}
# --data shape: {auto_translation_enabled?: bool, auto_translation_language?: string, config_overrides?: record, created_by?: record, disabled?: bool, frozen?: bool, members?: list, own_capabilities?: list<float>, team?: string, truncated_at?: list<float>, truncated_by?: list<float>, truncated_by_id?: string}
# --invites item shape: {ban_expires?: string, banned?: bool, channel_role?: string, created_at?: string, deleted_at?: string, invite_accepted_at?: string, invite_rejected_at?: string, invited?: bool, is_moderator?: bool, role?: "member"|"moderator"|"admin"|"owner", shadow_banned?: bool, updated_at?: string, user?: record, user_id?: string}
# --message shape: {attachments: list, cid?: list<float>, html?: string, id?: string, mentioned_users?: list<string>, mml?: string, parent?: list<float>, parent_id?: string, pin_expires?: string, pinned?: bool, pinned_at?: string, pinned_by?: list<float>, quoted_message_id?: string, reaction_scores?: list<float>, show_in_channel?: bool, silent?: bool, text?: string, user?: record, user_id?: string}
# --user shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
export def "channels update" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-invite: oneof<nothing, bool> # Set to `true` to accept the invite
  --add-members: list # List of user IDs to add to the channel — item shape: {ban_expires?: string, banned?: bool, channel_role?: string, created_at?: string, deleted_at?: string, invite_accepted_at?: string, invite_rejected_at?: string, invited?: bool, is_moderator?: bool, role?: "member"|"moderator"|"admin"|"owner", shadow_banned?: bool, updated_at?: string, user?: record, user_id?: string}
  add_moderators: list<string> # List of user IDs to make channel moderators
  --assign-roles: list # List of channel member role assignments. If any specified user is not part of the channel, the request will fail — item shape: {ban_expires?: string, banned?: bool, channel_role?: string, created_at?: string, deleted_at?: string, invite_accepted_at?: string, invite_rejected_at?: string, invited?: bool, is_moderator?: bool, role?: "member"|"moderator"|"admin"|"owner", shadow_banned?: bool, updated_at?: string, user?: record, user_id?: string}
  --cooldown: float # Sets cool down period for the channel in seconds
  --data: record # shape: {auto_translation_enabled?: bool, auto_translation_language?: string, config_overrides?: record, created_by?: record, disabled?: bool, frozen?: bool, members?: list, own_capabilities?: list<float>, team?: string, truncated_at?: list<float>, truncated_by?: list<float>, truncated_by_id?: string}
  demote_moderators: list<string> # List of user IDs to take away moderators status from
  --hide-history: oneof<nothing, bool> # Set to `true` to hide channel's history when adding new members
  --invites: list # List of user IDs to invite to the channel — item shape: {ban_expires?: string, banned?: bool, channel_role?: string, created_at?: string, deleted_at?: string, invite_accepted_at?: string, invite_rejected_at?: string, invited?: bool, is_moderator?: bool, role?: "member"|"moderator"|"admin"|"owner", shadow_banned?: bool, updated_at?: string, user?: record, user_id?: string}
  --message: record # Represents any chat message — shape: {attachments: list, cid?: list<float>, html?: string, id?: string, mentioned_users?: list<string>, mml?: string, parent?: list<float>, parent_id?: string, pin_expires?: string, pinned?: bool, pinned_at?: string, pinned_by?: list<float>, quoted_message_id?: string, reaction_scores?: list<float>, show_in_channel?: bool, silent?: bool, text?: string, user?: record, user_id?: string}
  --reject-invite: oneof<nothing, bool> # Set to `true` to reject the invite
  remove_members: list<string> # List of user IDs to remove from the channel
  --skip-push: oneof<nothing, bool> # When `message` is set disables all push notifications for it
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> record<channel: record<auto_translation_enabled: bool, auto_translation_language: string, cid: string, config: record<automod: string, automod_behavior: string, automod_thresholds: record, blocklist: string, blocklist_behavior: string, commands: list, connect_events: bool, created_at: string, custom_events: bool, grants: record, max_message_length: float, message_retention: string, mutes: bool, name: string, push_notifications: bool, quotes: bool, reactions: bool, read_events: bool, reminders: bool, replies: bool, search: bool, typing_events: bool, updated_at: string, uploads: bool, url_enrichment: bool>, cooldown: float, created_at: string, created_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, deleted_at: string, disabled: bool, frozen: bool, hidden: bool, hide_messages_before: string, id: string, last_message_at: string, member_count: float, members: list<record>, mute_expires_at: string, muted: bool, own_capabilities: list<string>, team: string, truncated_at: string, truncated_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, type: string, updated_at: string>, duration: string, members: table<ban_expires: string, banned: bool, channel_role: string, created_at: string, deleted_at: string, invite_accepted_at: string, invite_rejected_at: string, invited: bool, is_moderator: bool, role: string, shadow_banned: bool, updated_at: string, user: record, user_id: string>, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type: (encode-path-segment $type), id: (encode-path-segment $id)} | format pattern "/channels/{type}/{id}"))
  let req_body = {"accept_invite": $accept_invite, "add_members": $add_members, "add_moderators": $add_moderators, "assign_roles": $assign_roles, "cooldown": $cooldown, "data": $data, "demote_moderators": $demote_moderators, "hide_history": $hide_history, "invites": $invites, "message": $message, "reject_invite": $reject_invite, "remove_members": $remove_members, "skip_push": $skip_push, "user": $user, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Create a call
#
# POST /channels/{type}/{id}/call
# operationId: CreateCall
# --user shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
export def "channels-call create" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string
  --options: record
  --body-type: string@type-completer
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string # **Server-side only**. User ID which server acts upon
]: any -> record<agora_app_id: string, agora_uid: float, call: record<agora: record<channel: string>, hms: record<room_id: string, room_name: string>, id: string, provider: string, type: string>, duration: string, token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type: (encode-path-segment $type), id: (encode-path-segment $id)} | format pattern "/channels/{type}/{id}/call"))
  let req_body = {"id": $body_id, "options": $options, "type": $body_type, "user": $user, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Send event
#
# POST /channels/{type}/{id}/event
# operationId: SendEvent
# --event shape: {automoderation?: bool, automoderation_scores?: record, channel?: record, channel_id?: string, channel_type?: string, cid?: string, connection_id?: string, created_at?: string, created_by?: record, me?: record, member?: record, message?: record, parent_id?: string, reaction?: record, reason?: string, team?: string, type: string, user?: record, user_id?: string, watcher_count?: float}
export def "channels-event send" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  event: record # Represents an BaseEvent that happened in Stream Chat — shape: {automoderation?: bool, automoderation_scores?: record, channel?: record, channel_id?: string, channel_type?: string, cid?: string, connection_id?: string, created_at?: string, created_by?: record, me?: record, member?: record, message?: record, parent_id?: string, reaction?: record, reason?: string, team?: string, type: string, user?: record, user_id?: string, watcher_count?: float}
]: any -> record<duration: string, event: record<automoderation: bool, automoderation_scores: record<action: string, explicit: float, spam: float, toxic: float>, channel: record<auto_translation_enabled: bool, auto_translation_language: string, cid: string, config: record, cooldown: float, created_at: string, created_by: record, deleted_at: string, disabled: bool, frozen: bool, hidden: bool, hide_messages_before: string, id: string, last_message_at: string, member_count: float, members: list, mute_expires_at: string, muted: bool, own_capabilities: list, team: string, truncated_at: string, truncated_by: record, type: string, updated_at: string>, channel_id: string, channel_type: string, cid: string, connection_id: string, created_at: string, created_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, me: record<banned: bool, channel_mutes: list, created_at: string, deactivated_at: string, deleted_at: string, devices: list, id: string, invisible: bool, language: string, last_active: string, latest_hidden_channels: list, mutes: list, online: bool, push_notifications: record, role: string, teams: list, total_unread_count: float, unread_channels: float, unread_count: float, updated_at: string>, member: record<ban_expires: string, banned: bool, channel_role: string, created_at: string, deleted_at: string, invite_accepted_at: string, invite_rejected_at: string, invited: bool, is_moderator: bool, role: string, shadow_banned: bool, updated_at: string, user: record, user_id: string>, message: record<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>, parent_id: string, reaction: record<created_at: string, message_id: string, score: float, type: string, updated_at: string, user: record, user_id: string>, reason: string, team: string, type: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, user_id: string, watcher_count: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type: (encode-path-segment $type), id: (encode-path-segment $id)} | format pattern "/channels/{type}/{id}/event"))
  let req_body = {"event": $event} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete file
#
# DELETE /channels/{type}/{id}/file
# operationId: DeleteFile
export def "channels-file delete" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --url: string
]: nothing -> record<duration: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type: (encode-path-segment $type), id: (encode-path-segment $id)} | format pattern "/channels/{type}/{id}/file") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Upload file
#
# POST /channels/{type}/{id}/file
# operationId: UploadFile
# --user shape: {id: string}
export def "channels-file upload" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string # file field
  --user: record # shape: {id: string}
]: any -> record<duration: string, file: string, thumb_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type: (encode-path-segment $type), id: (encode-path-segment $id)} | format pattern "/channels/{type}/{id}/file"))
  let req_body = {"file": $file, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Hide channel
#
# POST /channels/{type}/{id}/hide
# operationId: HideChannel
# --user shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
export def "channels-hide create" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --clear-history: oneof<nothing, bool> # Whether to clear message history of the channel or not
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> record<duration: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type: (encode-path-segment $type), id: (encode-path-segment $id)} | format pattern "/channels/{type}/{id}/hide"))
  let req_body = {"clear_history": $clear_history, "user": $user, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete image
#
# DELETE /channels/{type}/{id}/image
# operationId: DeleteImage
export def "channels-image delete" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --url: string
]: nothing -> record<duration: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type: (encode-path-segment $type), id: (encode-path-segment $id)} | format pattern "/channels/{type}/{id}/image") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Upload image
#
# POST /channels/{type}/{id}/image
# operationId: UploadImage
# --upload_sizes item shape: {crop?: "top"|"bottom"|"left"|"right"|"center", height?: float, resize?: "clip"|"crop"|"scale"|"fill", width?: float}
# --user shape: {id: string}
export def "channels-image upload" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --file: string
  --upload-sizes: list # field with JSON-encoded array of image size configurations — item shape: {crop?: "top"|"bottom"|"left"|"right"|"center", height?: float, resize?: "clip"|"crop"|"scale"|"fill", width?: float}
  --user: record # shape: {id: string}
]: any -> record<duration: string, file: string, thumb_url: string, upload_sizes: table<crop: string, height: float, resize: string, width: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type: (encode-path-segment $type), id: (encode-path-segment $id)} | format pattern "/channels/{type}/{id}/image"))
  let req_body = {"file": $file, "upload_sizes": $upload_sizes, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = if ($req_body | describe | str starts-with "record") { $req_body } else { {} }
  let mp = (build-multipart-body $req_body [] $dry_run)
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full $mp.content_type $mp.body
}

# Send new message
#
# POST /channels/{type}/{id}/message
# operationId: SendMessage
# --message shape: {attachments: list, cid?: list<float>, html?: string, id?: string, mentioned_users?: list<string>, mml?: string, parent?: list<float>, parent_id?: string, pin_expires?: string, pinned?: bool, pinned_at?: string, pinned_by?: list<float>, quoted_message_id?: string, reaction_scores?: list<float>, show_in_channel?: bool, silent?: bool, text?: string, user?: record, user_id?: string}
export def "channels-message send" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --force-moderation: oneof<nothing, bool> # Enable moderation on server-side requests
  --is-pending-message: oneof<nothing, bool> # Make the message a pending message. This message will not be viewable to others until it is committed.
  message: record # Represents any chat message — shape: {attachments: list, cid?: list<float>, html?: string, id?: string, mentioned_users?: list<string>, mml?: string, parent?: list<float>, parent_id?: string, pin_expires?: string, pinned?: bool, pinned_at?: string, pinned_by?: list<float>, quoted_message_id?: string, reaction_scores?: list<float>, show_in_channel?: bool, silent?: bool, text?: string, user?: record, user_id?: string}
  --pending-message-metadata: record
  --skip-enrich-url: oneof<nothing, bool> # Do not try to enrich the links within message
  --skip-push: oneof<nothing, bool> # Disables all push notifications for this message
]: any -> record<duration: string, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>, pending_message_metadata: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type: (encode-path-segment $type), id: (encode-path-segment $id)} | format pattern "/channels/{type}/{id}/message"))
  let req_body = {"force_moderation": $force_moderation, "is_pending_message": $is_pending_message, "message": $message, "pending_message_metadata": $pending_message_metadata, "skip_enrich_url": $skip_enrich_url, "skip_push": $skip_push} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get many messages
#
# GET /channels/{type}/{id}/messages
# operationId: GetManyMessages
export def "channels-messages get-many" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --ids: string
]: nothing -> record<duration: string, messages: table<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "ids" $ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type: (encode-path-segment $type), id: (encode-path-segment $id)} | format pattern "/channels/{type}/{id}/messages") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get or create channel (type, id)
#
# POST /channels/{type}/{id}/query
# operationId: GetOrCreateChannel_type_id_0
# --data shape: {auto_translation_enabled?: bool, auto_translation_language?: string, config_overrides?: record, created_by?: record, disabled?: bool, frozen?: bool, members?: list, own_capabilities?: list<float>, team?: string, truncated_at?: list<float>, truncated_by?: list<float>, truncated_by_id?: string}
# --members shape: {id_gt?: float, id_gte?: float, id_lt?: float, id_lte?: float, limit?: float, offset?: float}
# --messages shape: {created_at_after?: string, created_at_after_or_equal?: string, created_at_around?: string, created_at_before?: string, created_at_before_or_equal?: string, id_around?: string, id_gt?: string, id_gte?: string, id_lt?: string, id_lte?: string, limit?: float, offset?: float}
# --watchers shape: {id_gt?: float, id_gte?: float, id_lt?: float, id_lte?: float, limit?: float, offset?: float}
export def "channels-query get-or-create-by-type-id" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string
  --connection-id: string
  --client-id: string
  --connection-id: string
  --data: record # shape: {auto_translation_enabled?: bool, auto_translation_language?: string, config_overrides?: record, created_by?: record, disabled?: bool, frozen?: bool, members?: list, own_capabilities?: list<float>, team?: string, truncated_at?: list<float>, truncated_by?: list<float>, truncated_by_id?: string}
  --members: record # shape: {id_gt?: float, id_gte?: float, id_lt?: float, id_lte?: float, limit?: float, offset?: float}
  --messages: record # shape: {created_at_after?: string, created_at_after_or_equal?: string, created_at_around?: string, created_at_before?: string, created_at_before_or_equal?: string, id_around?: string, id_gt?: string, id_gte?: string, id_lt?: string, id_lte?: string, limit?: float, offset?: float}
  --presence: oneof<nothing, bool> # Fetch user presence info
  --state: oneof<nothing, bool> # Refresh channel state
  --watch: oneof<nothing, bool> # Start watching the channel
  --watchers: record # shape: {id_gt?: float, id_gte?: float, id_lt?: float, id_lte?: float, limit?: float, offset?: float}
]: any -> record<channel: record<auto_translation_enabled: bool, auto_translation_language: string, cid: string, config: record<automod: string, automod_behavior: string, automod_thresholds: record, blocklist: string, blocklist_behavior: string, commands: list, connect_events: bool, created_at: string, custom_events: bool, grants: record, max_message_length: float, message_retention: string, mutes: bool, name: string, push_notifications: bool, quotes: bool, reactions: bool, read_events: bool, reminders: bool, replies: bool, search: bool, typing_events: bool, updated_at: string, uploads: bool, url_enrichment: bool>, cooldown: float, created_at: string, created_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, deleted_at: string, disabled: bool, frozen: bool, hidden: bool, hide_messages_before: string, id: string, last_message_at: string, member_count: float, members: list<record>, mute_expires_at: string, muted: bool, own_capabilities: list<string>, team: string, truncated_at: string, truncated_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, type: string, updated_at: string>, duration: string, hidden: bool, hide_messages_before: string, members: table<ban_expires: string, banned: bool, channel_role: string, created_at: string, deleted_at: string, invite_accepted_at: string, invite_rejected_at: string, invited: bool, is_moderator: bool, role: string, shadow_banned: bool, updated_at: string, user: record, user_id: string>, membership: record<ban_expires: string, banned: bool, channel_role: string, created_at: string, deleted_at: string, invite_accepted_at: string, invite_rejected_at: string, invited: bool, is_moderator: bool, role: string, shadow_banned: bool, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, user_id: string>, messages: table<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>, pending_messages: table<channel: record, message: record, metadata: record, user: record>, pinned_messages: table<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>, read: table<last_read: string, unread_messages: float, user: record>, watcher_count: float, watchers: table<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_id" $client_id "scalar") (serialize-qp "connection_id" $connection_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type: (encode-path-segment $type), id: (encode-path-segment $id)} | format pattern "/channels/{type}/{id}/query") $qp)
  let req_body = {"client_id": $client_id, "connection_id": $connection_id, "data": $data, "members": $members, "messages": $messages, "presence": $presence, "state": $state, "watch": $watch, "watchers": $watchers} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Mark read
#
# POST /channels/{type}/{id}/read
# operationId: MarkRead
# --user shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
export def "channels-read get-mark-by-type-id" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --message-id: string # ID of the message that is considered last read by client
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> record<duration: string, event: record<automoderation: bool, automoderation_scores: record<action: string, explicit: float, spam: float, toxic: float>, channel: record<auto_translation_enabled: bool, auto_translation_language: string, cid: string, config: record, cooldown: float, created_at: string, created_by: record, deleted_at: string, disabled: bool, frozen: bool, hidden: bool, hide_messages_before: string, id: string, last_message_at: string, member_count: float, members: list, mute_expires_at: string, muted: bool, own_capabilities: list, team: string, truncated_at: string, truncated_by: record, type: string, updated_at: string>, channel_id: string, channel_type: string, cid: string, connection_id: string, created_at: string, created_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, me: record<banned: bool, channel_mutes: list, created_at: string, deactivated_at: string, deleted_at: string, devices: list, id: string, invisible: bool, language: string, last_active: string, latest_hidden_channels: list, mutes: list, online: bool, push_notifications: record, role: string, teams: list, total_unread_count: float, unread_channels: float, unread_count: float, updated_at: string>, member: record<ban_expires: string, banned: bool, channel_role: string, created_at: string, deleted_at: string, invite_accepted_at: string, invite_rejected_at: string, invited: bool, is_moderator: bool, role: string, shadow_banned: bool, updated_at: string, user: record, user_id: string>, message: record<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>, parent_id: string, reaction: record<created_at: string, message_id: string, score: float, type: string, updated_at: string, user: record, user_id: string>, reason: string, team: string, type: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, user_id: string, watcher_count: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type: (encode-path-segment $type), id: (encode-path-segment $id)} | format pattern "/channels/{type}/{id}/read"))
  let req_body = {"message_id": $message_id, "user": $user, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Show channel
#
# POST /channels/{type}/{id}/show
# operationId: ShowChannel
# --user shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
export def "channels-show create" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> record<duration: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type: (encode-path-segment $type), id: (encode-path-segment $id)} | format pattern "/channels/{type}/{id}/show"))
  let req_body = {"user": $user, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Stop watching channel
#
# POST /channels/{type}/{id}/stop-watching
# operationId: StopWatchingChannel
export def "channels-stop-watching stop" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --client-id: string
  --connection-id: string
  --client-id: string
  --connection-id: string
]: any -> record<duration: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "client_id" $client_id "scalar") (serialize-qp "connection_id" $connection_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({type: (encode-path-segment $type), id: (encode-path-segment $id)} | format pattern "/channels/{type}/{id}/stop-watching") $qp)
  let req_body = {"client_id": $client_id, "connection_id": $connection_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Truncate channel
#
# POST /channels/{type}/{id}/truncate
# operationId: TruncateChannel
# --message shape: {attachments: list, cid?: list<float>, html?: string, id?: string, mentioned_users?: list<string>, mml?: string, parent?: list<float>, parent_id?: string, pin_expires?: string, pinned?: bool, pinned_at?: string, pinned_by?: list<float>, quoted_message_id?: string, reaction_scores?: list<float>, show_in_channel?: bool, silent?: bool, text?: string, user?: record, user_id?: string}
# --user shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
export def "channels-truncate create" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hard-delete: oneof<nothing, bool> # Permanently delete channel data (messages, reactions, etc.)
  --message: record # Represents any chat message — shape: {attachments: list, cid?: list<float>, html?: string, id?: string, mentioned_users?: list<string>, mml?: string, parent?: list<float>, parent_id?: string, pin_expires?: string, pinned?: bool, pinned_at?: string, pinned_by?: list<float>, quoted_message_id?: string, reaction_scores?: list<float>, show_in_channel?: bool, silent?: bool, text?: string, user?: record, user_id?: string}
  --skip-push: oneof<nothing, bool> # When `message` is set disables all push notifications for it
  --truncated-at: string # Truncate channel data up to `truncated_at`. The system message (if provided) creation time is always greater than `truncated_at` (format: date-time)
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> record<channel: record<auto_translation_enabled: bool, auto_translation_language: string, cid: string, config: record<automod: string, automod_behavior: string, automod_thresholds: record, blocklist: string, blocklist_behavior: string, commands: list, connect_events: bool, created_at: string, custom_events: bool, grants: record, max_message_length: float, message_retention: string, mutes: bool, name: string, push_notifications: bool, quotes: bool, reactions: bool, read_events: bool, reminders: bool, replies: bool, search: bool, typing_events: bool, updated_at: string, uploads: bool, url_enrichment: bool>, cooldown: float, created_at: string, created_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, deleted_at: string, disabled: bool, frozen: bool, hidden: bool, hide_messages_before: string, id: string, last_message_at: string, member_count: float, members: list<record>, mute_expires_at: string, muted: bool, own_capabilities: list<string>, team: string, truncated_at: string, truncated_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, type: string, updated_at: string>, duration: string, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type: (encode-path-segment $type), id: (encode-path-segment $id)} | format pattern "/channels/{type}/{id}/truncate"))
  let req_body = {"hard_delete": $hard_delete, "message": $message, "skip_push": $skip_push, "truncated_at": $truncated_at, "user": $user, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Mark unread
#
# POST /channels/{type}/{id}/unread
# operationId: MarkUnread
# --user shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
export def "channels-unread create-mark" [
  type: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  message_id: string # ID of the message from where the channel is marked unread
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> record<duration: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type: (encode-path-segment $type), id: (encode-path-segment $id)} | format pattern "/channels/{type}/{id}/unread"))
  let req_body = {"message_id": $message_id, "user": $user, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List channel types
#
# GET /channeltypes
# operationId: ListChannelTypes
export def "channeltypes list-channel-types" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<channel_types: record, duration: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/channeltypes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create channel type
#
# POST /channeltypes
# operationId: CreateChannelType
# --permissions item shape: {action?: "Deny"|"Allow", name: string, owner?: bool, priority: float, resources?: list<string>, roles?: list<string>}
export def "channeltypes create-channel-type" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  automod: string@automod-completer # Enables automatic message moderation
  --automod-behavior: string@automod-behavior-completer # Sets behavior of automatic moderation
  --blocklist: string # Name of the blocklist to use
  --blocklist-behavior: string@blocklist-behavior-completer # Sets behavior of blocklist
  --commands: list<string> # List of commands that channel supports
  --connect-events: oneof<nothing, bool> # Connect events support
  --custom-events: oneof<nothing, bool> # Enables custom events
  --grants: record
  --max-message-length: float # Number of maximum message characters
  --message-retention: string # Number of days to keep messages. 'infinite' disables retention
  --mutes: oneof<nothing, bool> # Enables mutes
  name: string # Channel type name
  --permissions: list # List of permissions for the channel type — item shape: {action?: "Deny"|"Allow", name: string, owner?: bool, priority: float, resources?: list<string>, roles?: list<string>}
  --push-notifications: oneof<nothing, bool> # Enables push notifications
  --reactions: oneof<nothing, bool> # Enables message reactions
  --read-events: oneof<nothing, bool> # Read events support
  --replies: oneof<nothing, bool> # Enables message replies (threads)
  --search: oneof<nothing, bool> # Enables message search
  --typing-events: oneof<nothing, bool> # Typing events support
  --uploads: oneof<nothing, bool> # Enables file uploads
  --url-enrichment: oneof<nothing, bool> # Enables URL enrichment
]: any -> record<automod: string, automod_behavior: string, automod_thresholds: record<explicit: record<block: float, flag: float>, spam: record<block: float, flag: float>, toxic: record<block: float, flag: float>>, blocklist: string, blocklist_behavior: string, commands: list<string>, connect_events: bool, created_at: string, custom_events: bool, duration: string, grants: record, max_message_length: float, message_retention: string, mutes: bool, name: string, permissions: table<action: string, name: string, owner: bool, priority: float, resources: list, roles: list>, push_notifications: bool, quotes: bool, reactions: bool, read_events: bool, reminders: bool, replies: bool, search: bool, typing_events: bool, updated_at: string, uploads: bool, url_enrichment: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/channeltypes")
  let req_body = {"automod": $automod, "automod_behavior": $automod_behavior, "blocklist": $blocklist, "blocklist_behavior": $blocklist_behavior, "commands": $commands, "connect_events": $connect_events, "custom_events": $custom_events, "grants": $grants, "max_message_length": $max_message_length, "message_retention": $message_retention, "mutes": $mutes, "name": $name, "permissions": $permissions, "push_notifications": $push_notifications, "reactions": $reactions, "read_events": $read_events, "replies": $replies, "search": $search, "typing_events": $typing_events, "uploads": $uploads, "url_enrichment": $url_enrichment} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete channel type
#
# DELETE /channeltypes/{name}
# operationId: DeleteChannelType
export def "channeltypes delete-channel-type" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<duration: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/channeltypes/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get channel type
#
# GET /channeltypes/{name}
# operationId: GetChannelType
export def "channeltypes get-channel-type" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<duration: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/channeltypes/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update channel type
#
# PUT /channeltypes/{name}
# operationId: UpdateChannelType
# --automod_thresholds shape: {explicit?: record, spam?: record, toxic?: record}
# --permissions item shape: {action?: "Deny"|"Allow", name: string, owner?: bool, priority: float, resources?: list<string>, roles?: list<string>}
export def "channeltypes update-channel-type" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --name-from-path: string
  automod: string@automod-completer
  --automod-behavior: string@automod-behavior-completer
  --automod-thresholds: record # Sets thresholds for AI moderation — shape: {explicit?: record, spam?: record, toxic?: record}
  --blocklist: string
  --blocklist-behavior: string@blocklist-behavior-completer
  --commands: list<string> # List of commands that channel supports
  --connect-events: oneof<nothing, bool>
  --custom-events: oneof<nothing, bool>
  --grants: record
  --max-message-length: float
  --message-retention: string
  --mutes: oneof<nothing, bool>
  --permissions: list # item shape: {action?: "Deny"|"Allow", name: string, owner?: bool, priority: float, resources?: list<string>, roles?: list<string>}
  --push-notifications: oneof<nothing, bool>
  --quotes: oneof<nothing, bool>
  --reactions: oneof<nothing, bool>
  --read-events: oneof<nothing, bool>
  --reminders: oneof<nothing, bool>
  --replies: oneof<nothing, bool>
  --search: oneof<nothing, bool>
  --typing-events: oneof<nothing, bool>
  --uploads: oneof<nothing, bool>
  --url-enrichment: oneof<nothing, bool>
]: any -> record<automod: string, automod_behavior: string, automod_thresholds: record<explicit: record<block: float, flag: float>, spam: record<block: float, flag: float>, toxic: record<block: float, flag: float>>, blocklist: string, blocklist_behavior: string, commands: list<string>, connect_events: bool, created_at: string, custom_events: bool, duration: string, grants: record, max_message_length: float, message_retention: string, mutes: bool, name: string, permissions: table<action: string, name: string, owner: bool, priority: float, resources: list, roles: list>, push_notifications: bool, quotes: bool, reactions: bool, read_events: bool, reminders: bool, replies: bool, search: bool, typing_events: bool, updated_at: string, uploads: bool, url_enrichment: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/channeltypes/{name}"))
  let req_body = {"NameFromPath": $name_from_path, "automod": $automod, "automod_behavior": $automod_behavior, "automod_thresholds": $automod_thresholds, "blocklist": $blocklist, "blocklist_behavior": $blocklist_behavior, "commands": $commands, "connect_events": $connect_events, "custom_events": $custom_events, "grants": $grants, "max_message_length": $max_message_length, "message_retention": $message_retention, "mutes": $mutes, "permissions": $permissions, "push_notifications": $push_notifications, "quotes": $quotes, "reactions": $reactions, "read_events": $read_events, "reminders": $reminders, "replies": $replies, "search": $search, "typing_events": $typing_events, "uploads": $uploads, "url_enrichment": $url_enrichment} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Check push
#
# POST /check_push
# operationId: CheckPush
# --user shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
export def "check-push check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --apn-template: string # Push message template for APN
  --firebase-data-template: string # Push message data template for Firebase
  --firebase-template: string # Push message template for Firebase
  --message-id: string # Message ID to send push notification for
  --push-provider-name: string # Name of push provider
  --push-provider-type: string@push-provider-type-completer # Push provider type
  --skip-devices: oneof<nothing, bool> # Don't require existing devices to render templates
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> record<device_errors: record, duration: string, general_errors: list<string>, rendered_apn_template: string, rendered_firebase_template: string, rendered_message: record, skip_devices: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/check_push")
  let req_body = {"apn_template": $apn_template, "firebase_data_template": $firebase_data_template, "firebase_template": $firebase_template, "message_id": $message_id, "push_provider_name": $push_provider_name, "push_provider_type": $push_provider_type, "skip_devices": $skip_devices, "user": $user, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Check SQS
#
# POST /check_sqs
# operationId: CheckSQS
export def "check-sqs check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --sqs-key: string # AWS SQS access key
  --sqs-secret: string # AWS SQS key secret
  --sqs-url: string # AWS SQS endpoint URL
]: any -> record<data: record, duration: string, error: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/check_sqs")
  let req_body = {"sqs_key": $sqs_key, "sqs_secret": $sqs_secret, "sqs_url": $sqs_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# List commands
#
# GET /commands
# operationId: ListCommands
export def "commands list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<commands: table<args: string, created_at: string, description: string, name: string, set: string, updated_at: string>, duration: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/commands")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create command
#
# POST /commands
# operationId: CreateCommand
export def "commands create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --args: string # Arguments help text, shown in commands auto-completion
  description: string # Description, shown in commands auto-completion
  name: string # Unique command name
  --set: string # Set name used for grouping commands
]: any -> record<command: record<args: string, created_at: string, description: string, name: string, set: string, updated_at: string>, duration: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/commands")
  let req_body = {"args": $args, "description": $description, "name": $name, "set": $set} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete command
#
# DELETE /commands/{name}
# operationId: DeleteCommand
export def "commands delete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<duration: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/commands/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get command
#
# GET /commands/{name}
# operationId: GetCommand
export def "commands get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<args: string, created_at: string, description: string, duration: string, name: string, set: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/commands/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update command
#
# PUT /commands/{name}
# operationId: UpdateCommand
export def "commands update" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-name: string
  --args: string # Arguments help text, shown in commands auto-completion
  description: string # Description, shown in commands auto-completion
  --set: string # Set name used for grouping commands
]: any -> record<command: record<args: string, created_at: string, description: string, name: string, set: string, updated_at: string>, duration: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/commands/{name}"))
  let req_body = {"Name": $body_name, "args": $args, "description": $description, "set": $set} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Connect (WebSocket)
#
# GET /connect
# operationId: Connect
export def "connect get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --json: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "json" $json "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/connect" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete device
#
# DELETE /devices
# operationId: DeleteDevice
export def "devices delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --user-id: string
]: nothing -> record<duration: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id" $id "scalar") (serialize-qp "user_id" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/devices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List devices
#
# GET /devices
# operationId: ListDevices
export def "devices list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string
]: nothing -> record<devices: table<created_at: string, disabled: bool, disabled_reason: string, id: string, push_provider: string, push_provider_name: string, user_id: string>, duration: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/devices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create device
#
# POST /devices
# operationId: CreateDevice
# --user shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
export def "devices create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id: string
  --push-provider: string@push-provider-completer
  --push-provider-name: string
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string # **Server-side only**. User ID which server acts upon
]: any -> record<duration: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/devices")
  let req_body = {"id": $id, "push_provider": $push_provider, "push_provider_name": $push_provider_name, "user": $user, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Export users
#
# POST /export/users
# operationId: ExportUser
export def "export-users export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  user_ids: list<string>
]: any -> record<duration: string, task_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/export/users")
  let req_body = {"user_ids": $user_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Export channels
#
# POST /export_channels
# operationId: ExportChannels
# --channels item shape: {cid?: string, id?: string, messages_since?: string, messages_until?: string, type?: string}
export def "export-channels export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --channels: list # Export options for channels — item shape: {cid?: string, id?: string, messages_since?: string, messages_until?: string, type?: string}
  --clear-deleted-message-text: oneof<nothing, bool> # Set if deleted message text should be cleared
  --export-users: oneof<nothing, bool>
  --include-truncated-messages: oneof<nothing, bool> # Set if you want to include truncated messages
  --version: string
]: any -> record<duration: string, task_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/export_channels")
  let req_body = {"channels": $channels, "clear_deleted_message_text": $clear_deleted_message_text, "export_users": $export_users, "include_truncated_messages": $include_truncated_messages, "version": $version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Export channels status
#
# GET /export_channels/{id}
# operationId: GetExportChannelsStatus
export def "export-channels get-status" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, duration: string, error: record<description: any, stacktrace: string, type: string, version: string>, result: record<path: string, s3_bucket_name: string, url: string>, status: string, task_id: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/export_channels/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create guest
#
# POST /guest
# operationId: CreateGuest
# --user shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
export def "guest create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
]: any -> record<access_token: string, duration: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record<disabled: bool, disabled_until: string>, revoke_tokens_issued_before: string, role: string, teams: list<string>, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/guest")
  let req_body = {"user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Create import URL
#
# POST /import_urls
# operationId: CreateImportURL
export def "import-urls create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --filename: string
]: any -> record<duration: string, path: string, upload_url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/import_urls")
  let req_body = {"filename": $filename} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get import
#
# GET /imports
# operationId: ListImports
export def "imports list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<duration: string, import_tasks: table<created_at: string, history: list, id: string, mode: string, path: string, result: any, size: float, state: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/imports")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create import
#
# POST /imports
# operationId: CreateImport
export def "imports create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mode: string@mode-completer
  path: string
]: any -> record<duration: string, import_task: record<created_at: string, history: list<record>, id: string, mode: string, path: string, result: any, size: float, state: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/imports")
  let req_body = {"mode": $mode, "path": $path} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get import
#
# GET /imports/{id}
# operationId: GetImport
export def "imports get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<duration: string, import_task: record<created_at: string, history: list<record>, id: string, mode: string, path: string, result: any, size: float, state: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/imports/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Long Poll (Transport)
#
# GET /longpoll
# operationId: LongPoll
export def "longpoll get-long-poll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --json: string
  --connection-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "json" $json "scalar") (serialize-qp "connection_id" $connection_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/longpoll" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Query members
#
# GET /members
# operationId: QueryMembers
export def "members list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payload: string
]: nothing -> record<duration: string, members: table<ban_expires: string, banned: bool, channel_role: string, created_at: string, deleted_at: string, invite_accepted_at: string, invite_rejected_at: string, invited: bool, is_moderator: bool, role: string, shadow_banned: bool, updated_at: string, user: record, user_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payload" $payload "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/members" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Delete message
#
# DELETE /messages/{id}
# operationId: DeleteMessage
export def "messages delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --hard: string
]: nothing -> record<duration: string, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "hard" $hard "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/messages/{id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get message
#
# GET /messages/{id}
# operationId: GetMessage
export def "messages get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<duration: string, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>, pending_message_metadata: record> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/messages/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update message
#
# POST /messages/{id}
# operationId: UpdateMessage
# --message shape: {attachments: list, cid?: list<float>, html?: string, id?: string, mentioned_users?: list<string>, mml?: string, parent?: list<float>, parent_id?: string, pin_expires?: string, pinned?: bool, pinned_at?: string, pinned_by?: list<float>, quoted_message_id?: string, reaction_scores?: list<float>, show_in_channel?: bool, silent?: bool, text?: string, user?: record, user_id?: string}
export def "messages update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  message: record # Represents any chat message — shape: {attachments: list, cid?: list<float>, html?: string, id?: string, mentioned_users?: list<string>, mml?: string, parent?: list<float>, parent_id?: string, pin_expires?: string, pinned?: bool, pinned_at?: string, pinned_by?: list<float>, quoted_message_id?: string, reaction_scores?: list<float>, show_in_channel?: bool, silent?: bool, text?: string, user?: record, user_id?: string}
  --pending-message-metadata: record
  --skip-enrich-url: oneof<nothing, bool> # Do not try to enrich the links within message
]: any -> record<duration: string, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/messages/{id}"))
  let req_body = {"message": $message, "pending_message_metadata": $pending_message_metadata, "skip_enrich_url": $skip_enrich_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Partially message update
#
# PUT /messages/{id}
# operationId: UpdateMessagePartial
# --user shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
export def "messages update-partial" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  set: record # Sets new field values
  --skip-enrich-url: oneof<nothing, bool> # Do not try to enrich the links within message
  unset: list<string> # Array of field names to unset
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> record<duration: string, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/messages/{id}"))
  let req_body = {"set": $set, "skip_enrich_url": $skip_enrich_url, "unset": $unset, "user": $user, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Run message command action
#
# POST /messages/{id}/action
# operationId: RunMessageAction
# --user shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
export def "messages-action create-run" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string
  form_data: record # Data to execute command with
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> record<duration: string, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/messages/{id}/action"))
  let req_body = {"ID": $body_id, "form_data": $form_data, "user": $user, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Commit message
#
# POST /messages/{id}/commit
# operationId: CommitMessage
export def "messages-commit commit" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<duration: string, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/messages/{id}/commit"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Send reaction
#
# POST /messages/{id}/reaction
# operationId: SendReaction
# --reaction shape: {message_id?: string, score?: float, type: string, user?: record, user_id?: string}
export def "messages-reaction send" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --body-id: string
  --enforce-unique: oneof<nothing, bool> # Whether to replace all existing user reactions
  --reaction: record # Represents user reaction to a message (nullable) — shape: {message_id?: string, score?: float, type: string, user?: record, user_id?: string}
  --skip-push: oneof<nothing, bool> # Skips any mobile push notifications
]: any -> record<duration: string, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>, reaction: record<created_at: string, message_id: string, score: float, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, user_id: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/messages/{id}/reaction"))
  let req_body = {"ID": $body_id, "enforce_unique": $enforce_unique, "reaction": $reaction, "skip_push": $skip_push} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete reaction
#
# DELETE /messages/{id}/reaction/{type}
# operationId: DeleteReaction
export def "messages-reaction delete" [
  id: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: string
]: nothing -> record<duration: string, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>, reaction: record<created_at: string, message_id: string, score: float, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, user_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "user_id" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id), type: (encode-path-segment $type)} | format pattern "/messages/{id}/reaction/{type}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get reactions
#
# GET /messages/{id}/reactions
# operationId: GetReactions
export def "messages-reactions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --limit: string
  --offset: string
]: nothing -> record<duration: string, reactions: table<created_at: string, message_id: string, score: float, type: string, updated_at: string, user: record, user_id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/messages/{id}/reactions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Translate message
#
# POST /messages/{id}/translate
# operationId: TranslateMessage
export def "messages-translate create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  language: string@language-completer # Language to translate message to
]: any -> record<duration: string, message: record<attachments: list<record>, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list<record>, mentioned_users: list<record>, mml: string, own_reactions: list<record>, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list<record>, type: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/messages/{id}/translate"))
  let req_body = {"language": $language} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get replies
#
# GET /messages/{parent_id}/replies
# operationId: GetReplies
export def "messages-replies get" [
  parent_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --id-gte: string
  --id-gt: string
  --id-lte: string
  --id-lt: string
  --created-at-after-or-equal: string
  --created-at-after: string
  --created-at-before-or-equal: string
  --created-at-before: string
  --id-around: string
  --created-at-around: string
]: nothing -> record<duration: string, messages: table<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "id_gte" $id_gte "scalar") (serialize-qp "id_gt" $id_gt "scalar") (serialize-qp "id_lte" $id_lte "scalar") (serialize-qp "id_lt" $id_lt "scalar") (serialize-qp "created_at_after_or_equal" $created_at_after_or_equal "scalar") (serialize-qp "created_at_after" $created_at_after "scalar") (serialize-qp "created_at_before_or_equal" $created_at_before_or_equal "scalar") (serialize-qp "created_at_before" $created_at_before "scalar") (serialize-qp "id_around" $id_around "scalar") (serialize-qp "created_at_around" $created_at_around "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent_id: (encode-path-segment $parent_id)} | format pattern "/messages/{parent_id}/replies") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Unban user
#
# DELETE /moderation/ban
# operationId: Unban
export def "moderation-ban delete-unban" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --target-user-id: string
  --type: string
  --id: string
]: nothing -> record<duration: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "target_user_id" $target_user_id "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "id" $id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/moderation/ban" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Ban user
#
# POST /moderation/ban
# operationId: Ban
# --banned_by shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
# --user shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
export def "moderation-ban create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --banned-by: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --banned-by-id: string # User ID who issued a ban
  --id: string # Channel ID to ban user in
  --ip-ban: oneof<nothing, bool> # Whether to perform IP ban or not
  --reason: string # Ban reason
  --shadow: oneof<nothing, bool> # Whether to perform shadow ban or not
  target_user_id: string # ID of user to ban
  --timeout: float # Timeout of ban in minutes. User will be unbanned after this period of time
  --type: string # Channel type to ban user in
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> record<duration: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/moderation/ban")
  let req_body = {"banned_by": $banned_by, "banned_by_id": $banned_by_id, "id": $id, "ip_ban": $ip_ban, "reason": $reason, "shadow": $shadow, "target_user_id": $target_user_id, "timeout": $timeout, "type": $type, "user": $user, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Flag
#
# POST /moderation/flag
# operationId: Flag
# --user shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
export def "moderation-flag create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --target-message-id: string # ID of the message when reporting a message
  --target-user-id: string # ID of the user when reporting a user
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> record<duration: string, flag: record<approved_at: string, created_at: string, created_by_automod: bool, details: record<automod: record>, rejected_at: string, reviewed_at: string, target_message: record<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>, target_message_id: string, target_user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/moderation/flag")
  let req_body = {"target_message_id": $target_message_id, "target_user_id": $target_user_id, "user": $user, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Query Message Flags
#
# GET /moderation/flags/message
# operationId: QueryMessageFlags
export def "moderation-flags-message list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payload: string
]: nothing -> record<duration: string, flags: table<approved_at: string, created_at: string, created_by_automod: bool, message: record, moderation_result: record, rejected_at: string, reviewed_at: string, reviewed_by: record, updated_at: string, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payload" $payload "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/moderation/flags/message" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Mute user
#
# POST /moderation/mute
# operationId: MuteUser
# --user shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
export def "moderation-mute create-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  target_ids: list<string> # User IDs to mute (if multiple users)
  --timeout: float # Duration of mute in minutes
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> record<duration: string, mute: record<created_at: string, expires: string, target: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>, mutes: table<created_at: string, expires: string, target: record, updated_at: string, user: record>, own_user: record<banned: bool, channel_mutes: list<record>, created_at: string, deactivated_at: string, deleted_at: string, devices: list<record>, id: string, invisible: bool, language: string, last_active: string, latest_hidden_channels: list<string>, mutes: list<record>, online: bool, push_notifications: record<disabled: bool, disabled_until: string>, role: string, teams: list<string>, total_unread_count: float, unread_channels: float, unread_count: float, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/moderation/mute")
  let req_body = {"target_ids": $target_ids, "timeout": $timeout, "user": $user, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Mute channel
#
# POST /moderation/mute/channel
# operationId: MuteChannel
# --user shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
export def "moderation-mute-channel create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  channel_cids: list<string> # Channel CIDs to mute (if multiple channels)
  --expiration: float # Duration of mute in milliseconds
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> record<channel_mute: record<channel: record<auto_translation_enabled: bool, auto_translation_language: string, cid: string, config: record, cooldown: float, created_at: string, created_by: record, deleted_at: string, disabled: bool, frozen: bool, hidden: bool, hide_messages_before: string, id: string, last_message_at: string, member_count: float, members: list, mute_expires_at: string, muted: bool, own_capabilities: list, team: string, truncated_at: string, truncated_by: record, type: string, updated_at: string>, created_at: string, expires: string, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>, channel_mutes: table<channel: record, created_at: string, expires: string, updated_at: string, user: record>, duration: string, own_user: record<banned: bool, channel_mutes: list<record>, created_at: string, deactivated_at: string, deleted_at: string, devices: list<record>, id: string, invisible: bool, language: string, last_active: string, latest_hidden_channels: list<string>, mutes: list<record>, online: bool, push_notifications: record<disabled: bool, disabled_until: string>, role: string, teams: list<string>, total_unread_count: float, unread_channels: float, unread_count: float, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/moderation/mute/channel")
  let req_body = {"channel_cids": $channel_cids, "expiration": $expiration, "user": $user, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Unflag
#
# POST /moderation/unflag
# operationId: Unflag
# --user shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
export def "moderation-unflag create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --target-message-id: string # ID of the message when reporting a message
  --target-user-id: string # ID of the user when reporting a user
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> record<duration: string, flag: record<approved_at: string, created_at: string, created_by_automod: bool, details: record<automod: record>, rejected_at: string, reviewed_at: string, target_message: record<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>, target_message_id: string, target_user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>, updated_at: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, teams: list, updated_at: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/moderation/unflag")
  let req_body = {"target_message_id": $target_message_id, "target_user_id": $target_user_id, "user": $user, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Unmute user
#
# POST /moderation/unmute
# operationId: UnmuteUser
# --user shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
export def "moderation-unmute create-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  target_id: string
  target_ids: list<string>
  --timeout: float
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> record<duration: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/moderation/unmute")
  let req_body = {"target_id": $target_id, "target_ids": $target_ids, "timeout": $timeout, "user": $user, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Unmute channel
#
# POST /moderation/unmute/channel
# operationId: UnmuteChannel
# --user shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
export def "moderation-unmute-channel create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  channel_cid: string
  channel_cids: list<string>
  --expiration: float
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
]: any -> record<duration: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/moderation/unmute/channel")
  let req_body = {"channel_cid": $channel_cid, "channel_cids": $channel_cids, "expiration": $expiration, "user": $user, "user_id": $user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get OG
#
# GET /og
# operationId: GetOG
export def "og get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --url: string
]: nothing -> record<actions: table<name: string, style: string, text: string, type: string, value: string>, asset_url: string, author_icon: string, author_link: string, author_name: string, color: string, duration: string, fallback: string, fields: table<short: bool, title: string, value: string>, footer: string, footer_icon: string, giphy: record<fixed_height: record<frames: string, height: string, size: string, url: string, width: string>, fixed_height_downsampled: record<frames: string, height: string, size: string, url: string, width: string>, fixed_height_still: record<frames: string, height: string, size: string, url: string, width: string>, fixed_width: record<frames: string, height: string, size: string, url: string, width: string>, fixed_width_downsampled: record<frames: string, height: string, size: string, url: string, width: string>, fixed_width_still: record<frames: string, height: string, size: string, url: string, width: string>, original: record<frames: string, height: string, size: string, url: string, width: string>>, image_url: string, og_scrape_url: string, original_height: float, original_width: float, pretext: string, text: string, thumb_url: string, title: string, title_link: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "url" $url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/og" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List permissions
#
# GET /permissions
# operationId: ListPermissions
export def "permissions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<duration: string, permissions: table<action: string, condition: record, custom: bool, description: string, id: string, level: string, name: string, owner: bool, same_team: bool, tags: list>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get permission
#
# GET /permissions/{id}
# operationId: GetPermission
export def "permissions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<duration: string, permission: record<action: string, condition: record, custom: bool, description: string, id: string, level: string, name: string, owner: bool, same_team: bool, tags: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/permissions/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List push providers
#
# GET /push_providers
# operationId: ListPushProviders
export def "push-providers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<duration: string, push_providers: table<apn_auth_key: string, apn_auth_type: string, apn_development: bool, apn_host: string, apn_key_id: string, apn_notification_template: string, apn_p12_cert: string, apn_team_id: string, apn_topic: string, created_at: string, description: string, disabled_at: string, disabled_reason: string, firebase_apn_template: string, firebase_credentials: string, firebase_data_template: string, firebase_notification_template: string, firebase_server_key: string, huawei_app_id: string, huawei_app_secret: string, name: string, type: float, updated_at: string, xiaomi_app_secret: string, xiaomi_package_name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/push_providers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Upsert a push provider
#
# POST /push_providers
# operationId: UpsertPushProvider
# --push_provider shape: {apn_auth_key?: string, apn_auth_type?: string, apn_development?: bool, apn_host?: string, apn_key_id?: string, apn_notification_template?: string, apn_p12_cert?: string, apn_team_id?: string, apn_topic?: string, created_at?: string, description?: string, disabled_at?: string, disabled_reason?: string, firebase_apn_template?: string, firebase_credentials?: string, firebase_data_template?: string, firebase_notification_template?: string, firebase_server_key?: string, huawei_app_id?: string, ... (6 more fields)}
export def "push-providers update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --push-provider: record # shape: {apn_auth_key?: string, apn_auth_type?: string, apn_development?: bool, apn_host?: string, apn_key_id?: string, apn_notification_template?: string, apn_p12_cert?: string, apn_team_id?: string, apn_topic?: string, created_at?: string, description?: string, disabled_at?: string, disabled_reason?: string, firebase_apn_template?: string, firebase_credentials?: string, firebase_data_template?: string, firebase_notification_template?: string, firebase_server_key?: string, huawei_app_id?: string, ... (6 more fields)}
]: any -> record<duration: string, push_provider: record<apn_auth_key: string, apn_auth_type: string, apn_development: bool, apn_host: string, apn_key_id: string, apn_notification_template: string, apn_p12_cert: string, apn_team_id: string, apn_topic: string, created_at: string, description: string, disabled_at: string, disabled_reason: string, firebase_apn_template: string, firebase_credentials: string, firebase_data_template: string, firebase_notification_template: string, firebase_server_key: string, huawei_app_id: string, huawei_app_secret: string, name: string, type: float, updated_at: string, xiaomi_app_secret: string, xiaomi_package_name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/push_providers")
  let req_body = {"push_provider": $push_provider} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete a push provider
#
# DELETE /push_providers/{type}/{name}
# operationId: DeletePushProvider
export def "push-providers delete" [
  type: string
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<duration: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({type: (encode-path-segment $type), name: (encode-path-segment $name)} | format pattern "/push_providers/{type}/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Query Banned Users
#
# GET /query_banned_users
# operationId: QueryBannedUsers
export def "query-banned-users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payload: string
]: nothing -> record<bans: table<banned_by: record, channel: record, created_at: string, expires: string, reason: string, shadow: bool, user: record>, duration: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payload" $payload "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/query_banned_users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get rate limits
#
# GET /rate_limits
# operationId: GetRateLimits
export def "rate-limits get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --server-side: string
  --android: string
  --ios: string
  --web: string
  --endpoints: string
]: nothing -> record<android: record, duration: string, ios: record, server_side: record, web: record> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "server_side" $server_side "scalar") (serialize-qp "android" $android "scalar") (serialize-qp "ios" $ios "scalar") (serialize-qp "web" $web "scalar") (serialize-qp "endpoints" $endpoints "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/rate_limits" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Query recipients
#
# GET /recipients
# operationId: QueryRecipients
export def "recipients list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payload: string
]: nothing -> record<campaigns: record, channels: record, duration: string, recipients: table<campaign_id: string, channel_cid: string, created_at: string, details: string, message_id: string, receiver_id: string, status: string, updated_at: string>, segments: record, users: record> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payload" $payload "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/recipients" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# List roles
#
# GET /roles
# operationId: ListRoles
export def "roles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<duration: string, roles: table<created_at: string, custom: bool, name: string, scopes: list, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create role
#
# POST /roles
# operationId: CreateRole
export def "roles create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # Role name
]: any -> record<duration: string, role: record<created_at: string, custom: bool, name: string, scopes: list<string>, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/roles")
  let req_body = {"name": $name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete role
#
# DELETE /roles/{name}
# operationId: DeleteRole
export def "roles delete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<duration: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/roles/{name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Search messages
#
# GET /search
# operationId: Search
export def "search list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payload: string
]: nothing -> record<duration: string, next: string, previous: string, results: table<message: record>, results_warning: record<channel_search_cids: list<string>, channel_search_count: float, warning_code: float, warning_description: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payload" $payload "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Query segments
#
# GET /segments
# operationId: QuerySegments
export def "segments list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payload: string
]: nothing -> record<duration: string, segments: table<created_at: string, description: string, filter: record, id: string, in_use: bool, name: string, size: float, status: string, type: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payload" $payload "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/segments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create segment
#
# POST /segments
# operationId: CreateSegment
# --segment shape: {description?: string, filter: record, name: string, type: "user"|"channel"}
export def "segments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  segment: record # shape: {description?: string, filter: record, name: string, type: "user"|"channel"}
]: any -> record<duration: string, segment: record<created_at: string, description: string, filter: record, id: string, in_use: bool, name: string, size: float, status: string, type: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/segments")
  let req_body = {"segment": $segment} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete segment
#
# DELETE /segments/{id}
# operationId: DeleteSegment
export def "segments delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<duration: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/segments/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update segment
#
# PUT /segments/{id}
# operationId: UpdateSegment
# --segment shape: {description?: string, filter?: record, name?: string, type?: "user"|"channel"}
export def "segments update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  segment: record # shape: {description?: string, filter?: record, name?: string, type?: "user"|"channel"}
]: any -> record<duration: string, segment: record<created_at: string, description: string, filter: record, id: string, in_use: bool, name: string, size: float, status: string, type: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/segments/{id}"))
  let req_body = {"segment": $segment} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Sync
#
# POST /sync
# operationId: Sync
# --user shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
export def "sync create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --with-inaccessible-cids: string
  --watch: string
  --client-id: string
  --connection-id: string
  --channel-cids: list<string> # List of channel CIDs to sync
  --client-id: string
  --connection-id: string
  last_sync_at: string # Date from which synchronization should happen (format: date-time)
  --user: record # Represents chat user — shape: {ban_expires?: string, banned?: bool, id: string, invisible?: bool, language?: string, push_notifications?: record, revoke_tokens_issued_before?: string, role?: string, teams?: list<string>}
  --user-id: string
  --watch: oneof<nothing, bool> # If set to true this will start watching requested and newly added channels that user has access to. If error occurred with this option enabled and it is not an input error - channels will still be watched.
  --with-inaccessible-cids: oneof<nothing, bool> # If set to true this will add 'inaccessible_cids' to response type
]: any -> record<duration: string, events: table<automoderation: bool, automoderation_scores: record, channel: record, channel_id: string, channel_type: string, cid: string, connection_id: string, created_at: string, created_by: record, me: record, member: record, message: record, parent_id: string, reaction: record, reason: string, team: string, type: string, user: record, user_id: string, watcher_count: float>, inaccessible_cids: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with_inaccessible_cids" $with_inaccessible_cids "scalar") (serialize-qp "watch" $watch "scalar") (serialize-qp "client_id" $client_id "scalar") (serialize-qp "connection_id" $connection_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/sync" $qp)
  let req_body = {"channel_cids": $channel_cids, "client_id": $client_id, "connection_id": $connection_id, "last_sync_at": $last_sync_at, "user": $user, "user_id": $user_id, "watch": $watch, "with_inaccessible_cids": $with_inaccessible_cids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get status of a task
#
# GET /tasks/{id}
# operationId: GetTask
export def "tasks get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<created_at: string, duration: string, error: record<description: any, stacktrace: string, type: string, version: string>, result: record, status: string, task_id: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/tasks/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Query users
#
# GET /users
# operationId: QueryUsers
export def "users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --payload: string
]: nothing -> record<duration: string, users: table<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record, revoke_tokens_issued_before: string, role: string, shadow_banned: bool, teams: list, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payload" $payload "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Partially update user
#
# PATCH /users
# operationId: UpdateUsersPartial
export def "users update-partial" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  id: string # User ID to update
  set: record
  unset: list<string>
]: any -> record<duration: string, users: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users")
  let req_body = {"id": $id, "set": $set, "unset": $unset} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Upsert users
#
# POST /users
# operationId: UpdateUsers
export def "users update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  users: record # Object containing users
]: any -> record<duration: string, users: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users")
  let req_body = {"users": $users} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Deactivate users
#
# POST /users/deactivate
# operationId: DeactivateUsers
export def "users-deactivate create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-by-id: string # ID of the user who deactivated the users
  --mark-messages-deleted: oneof<nothing, bool> # Makes messages appear to be deleted
  user_ids: list<string> # User IDs to deactivate
]: any -> record<duration: string, task_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/deactivate")
  let req_body = {"created_by_id": $created_by_id, "mark_messages_deleted": $mark_messages_deleted, "user_ids": $user_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete Users
#
# POST /users/delete
# operationId: DeleteUsers
export def "users-delete delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --conversations: string@conversations-completer # Conversation channels delete mode. Conversation channel is any channel which only has two members one of which is the user being deleted. * null or empty string - doesn't delete any conversation channels * soft - marks all conversation channels as deleted (same effect as Delete Channels with 'hard' option disabled) * hard - deletes channel and all its data completely including messages (same effect as Delete Channels with 'hard' option enabled)
  --messages: string@messages-completer # Message delete mode. * null or empty string - doesn't delete user messages * soft - marks all user messages as deleted without removing any related message data * pruning - marks all user messages as deleted, nullifies message information and removes some message data such as reactions and flags * hard - deletes messages completely with all related information
  --new-channel-owner-id: string
  --user: string@user-completer # User delete mode. * soft - marks user as deleted and retains all user data * pruning - marks user as deleted and nullifies user information * hard - deletes user completely. Requires 'hard' option for messages and conversations as well
  user_ids: list<string> # IDs of users to delete
]: any -> record<duration: string, task_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/delete")
  let req_body = {"conversations": $conversations, "messages": $messages, "new_channel_owner_id": $new_channel_owner_id, "user": $user, "user_ids": $user_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Reactivate users
#
# POST /users/reactivate
# operationId: ReactivateUsers
export def "users-reactivate create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-by-id: string # ID of the user who's reactivating the users
  --restore-messages: oneof<nothing, bool> # Restore previously deleted messages
  user_ids: list<string> # User IDs to reactivate
]: any -> record<duration: string, task_id: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/reactivate")
  let req_body = {"created_by_id": $created_by_id, "restore_messages": $restore_messages, "user_ids": $user_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Restore users
#
# POST /users/restore
# operationId: RestoreUsers
export def "users-restore create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  user_ids: list<string>
]: any -> record<duration: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/restore")
  let req_body = {"user_ids": $user_ids} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete user
#
# DELETE /users/{user_id}
# operationId: DeleteUser
export def "users delete" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --mark-messages-deleted: string
  --hard-delete: string
  --delete-conversation-channels: string
]: nothing -> record<duration: string, task_id: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record<disabled: bool, disabled_until: string>, revoke_tokens_issued_before: string, role: string, teams: list<string>, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "mark_messages_deleted" $mark_messages_deleted "scalar") (serialize-qp "hard_delete" $hard_delete "scalar") (serialize-qp "delete_conversation_channels" $delete_conversation_channels "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Deactivate user
#
# POST /users/{user_id}/deactivate
# operationId: DeactivateUser
export def "users-deactivate create-by-user_id" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-by-id: string # ID of the user who deactivated the user
  --mark-messages-deleted: oneof<nothing, bool> # Makes messages appear to be deleted
  --body-user-id: string
]: any -> record<duration: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record<disabled: bool, disabled_until: string>, revoke_tokens_issued_before: string, role: string, teams: list<string>, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/deactivate"))
  let req_body = {"created_by_id": $created_by_id, "mark_messages_deleted": $mark_messages_deleted, "user_id": $body_user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Send user event
#
# POST /users/{user_id}/event
# operationId: SendUserCustomEvent
# --event shape: {created_at?: string, type: string}
export def "users-event send-custom" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  event: record # shape: {created_at?: string, type: string}
]: any -> record<duration: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/event"))
  let req_body = {"event": $event} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Export user
#
# GET /users/{user_id}/export
export def "users-export get" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<duration: string, messages: table<attachments: list, before_message_send_failed: bool, cid: string, command: string, created_at: string, deleted_at: string, html: string, i18n: record, id: string, image_labels: record, latest_reactions: list, mentioned_users: list, mml: string, own_reactions: list, parent_id: string, pin_expires: string, pinned: bool, pinned_at: string, pinned_by: record, quoted_message: any, quoted_message_id: string, reaction_counts: record, reaction_scores: record, reply_count: float, shadowed: bool, show_in_channel: bool, silent: bool, text: string, thread_participants: list, type: string, updated_at: string, user: record>, reactions: table<created_at: string, message_id: string, score: float, type: string, updated_at: string, user: record, user_id: string>, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record<disabled: bool, disabled_until: string>, revoke_tokens_issued_before: string, role: string, teams: list<string>, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/export"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Reactivate user
#
# POST /users/{user_id}/reactivate
# operationId: ReactivateUser
export def "users-reactivate create-by-user_id" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --created-by-id: string # ID of the user who's reactivating the user
  --name: string # Set this field to put new name for the user
  --restore-messages: oneof<nothing, bool> # Restore previously deleted messages
  --body-user-id: string
]: any -> record<duration: string, user: record<ban_expires: string, banned: bool, created_at: string, deactivated_at: string, deleted_at: string, id: string, invisible: bool, language: string, last_active: string, online: bool, push_notifications: record<disabled: bool, disabled_until: string>, revoke_tokens_issued_before: string, role: string, teams: list<string>, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "jwt"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/users/{user_id}/reactivate"))
  let req_body = {"created_by_id": $created_by_id, "name": $name, "restore_messages": $restore_messages, "user_id": $body_user_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}
