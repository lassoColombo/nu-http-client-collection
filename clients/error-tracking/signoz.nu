# Auto-generated client for SigNoz v
# Source: https://raw.githubusercontent.com/SigNoz/signoz/main/docs/api/openapi.yml
# Auth: --token flag or $env.SIGNOZ_API_KEY

const BASE_URL = "https://localhost:8080"
const DEFAULT_AUTH = "signoz-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SIGNOZ_API_KEY | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "signoz-api-key" => { {headers: {SigNoz-Api-Key: $token_val}, query: ""} }
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
def base-url-completer [] { ["https://localhost:8080"] }
def auth-scheme-completer [] { ["signoz-api-key" "bearer"] }

# Completers for enum parameters
def format-completer [] { ["csv" "jsonl"] }
def requestType-completer [] { ["raw" "raw_stream" "scalar" "time_series" "trace"] }
def kind-completer [] { ["policy" "rule"] }
def fieldContext-completer [] { ["attribute" "resource"] }
def temporality-completer [] { ["cumulative" "delta" "unspecified"] }
def type-completer [] { ["exponentialhistogram" "gauge" "histogram" "sum" "summary"] }
def mode-completer [] { ["samples" "timeseries"] }
def alertType-completer [] { ["EXCEPTIONS_BASED_ALERT" "LOGS_BASED_ALERT" "METRIC_BASED_ALERT" "TRACES_BASED_ALERT"] }
def ruleType-completer [] { ["anomaly_rule" "promql_rule" "threshold_rule"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "alerts GetAlerts" } } | get name | first)
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

# Get alerts
#
# GET /api/v1/alerts
# operationId: GetAlerts
export def "alerts GetAlerts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<annotations: record, endsAt: string, fingerprint: string, generatorURL: string, labels: record, receivers: list, startsAt: string, status: record>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/alerts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check permissions
#
# POST /api/v1/authz/check
# operationId: AuthzCheck
export def "authz-check AuthzCheck" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<data: table<authorized: bool, object: record, relation: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/authz/check")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List notification channels
#
# GET /api/v1/channels
# operationId: ListChannels
export def "channels ListChannels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<createdAt: string, data: string, id: string, name: string, orgId: string, type: string, updatedAt: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/channels")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create notification channel
#
# POST /api/v1/channels
# operationId: CreateChannel
# --discord_configs item shape: {avatar_url?: string, content?: string, http_config?: record, message?: string, send_resolved?: bool, title?: string, username?: string, webhook_url?: record, webhook_url_file?: string}
# --email_configs item shape: {auth_identity?: string, auth_password?: string, auth_password_file?: string, auth_secret?: string, auth_secret_file?: string, auth_username?: string, force_implicit_tls?: bool, from?: string, headers?: record, hello?: string, html?: string, require_tls?: bool, send_resolved?: bool, smarthost?: record, text?: string, threading?: record, tls_config?: record, to?: string}
# --googlechat_configs item shape: {http_config?: record, send_resolved?: bool, text?: string, title?: string, webhook_url?: record}
# --incidentio_configs item shape: {alert_source_token?: string, alert_source_token_file?: string, http_config?: record, max_alerts?: int, send_resolved?: bool, timeout?: int, url?: record, url_file?: string}
# --jira_configs item shape: {api_type?: string, api_url?: record, custom_fields?: record, description?: record, http_config?: record, issue_type?: string, labels?: list, priority?: string, project?: string, reopen_duration?: int, reopen_transition?: string, resolve_transition?: string, send_resolved?: bool, summary?: record, wont_fix_resolution?: string}
# --mattermost_configs item shape: {attachments?: list, channel?: string, http_config?: record, icon_emoji?: string, icon_url?: string, priority?: record, props?: record, send_resolved?: bool, text?: string, type?: string, username?: string, webhook_url?: record, webhook_url_file?: string}
# --msteams_configs item shape: {http_config?: record, send_resolved?: bool, summary?: string, text?: string, title?: string, webhook_url?: record, webhook_url_file?: string}
# --msteamsv2_configs item shape: {http_config?: record, send_resolved?: bool, text?: string, title?: string, webhook_url?: record, webhook_url_file?: string}
# --opsgenie_configs item shape: {actions?: string, api_key?: string, api_key_file?: string, api_url?: record, description?: string, details?: record, entity?: string, http_config?: record, message?: string, note?: string, priority?: string, responders?: list, send_resolved?: bool, source?: string, tags?: string, update_alerts?: bool}
# --pagerduty_configs item shape: {class?: string, client?: string, client_url?: string, component?: string, description?: string, details?: record, group?: string, http_config?: record, images?: list, links?: list, routing_key?: string, routing_key_file?: string, send_resolved?: bool, service_key?: string, service_key_file?: string, severity?: string, source?: string, timeout?: int, url?: record}
# --pushover_configs item shape: {device?: string, expire?: string, html?: bool, http_config?: record, message?: string, monospace?: bool, priority?: string, retry?: string, send_resolved?: bool, sound?: string, title?: string, token?: string, token_file?: string, ttl?: string, url?: string, url_title?: string, user_key?: string, user_key_file?: string}
# --rocketchat_configs item shape: {actions?: list, api_url?: record, channel?: string, color?: string, emoji?: string, fields?: list, http_config?: record, icon_url?: string, image_url?: string, link_names?: bool, send_resolved?: bool, short_fields?: bool, text?: string, thumb_url?: string, title?: string, title_link?: string, token?: string, token_file?: string, token_id?: string, token_id_file?: string}
# --slack_configs item shape: {actions?: list, api_url?: record, api_url_file?: string, app_token?: string, app_token_file?: string, app_url?: record, callback_id?: string, channel?: string, color?: string, fallback?: string, fields?: list, footer?: string, http_config?: record, icon_emoji?: string, icon_url?: string, image_url?: string, link_names?: bool, message_text?: string, mrkdwn_in?: list, pretext?: string, send_resolved?: bool, short_fields?: bool, text?: string, thumb_url?: string, timeout?: int, title?: string, title_link?: string, username?: string}
# --sns_configs item shape: {api_url?: string, attributes?: record, http_config?: record, message?: string, phone_number?: string, send_resolved?: bool, sigv4?: record, subject?: string, target_arn?: string, topic_arn?: string}
# --telegram_configs item shape: {api_url?: record, chat?: int, chat_file?: string, disable_notifications?: bool, http_config?: record, message?: string, message_thread_id?: int, parse_mode?: string, send_resolved?: bool, token?: string, token_file?: string}
# --victorops_configs item shape: {api_key?: string, api_key_file?: string, api_url?: record, custom_fields?: record, entity_display_name?: string, http_config?: record, message_type?: string, monitoring_tool?: string, routing_key?: string, send_resolved?: bool, state_message?: string}
# --webex_configs item shape: {api_url?: record, http_config?: record, message?: string, room_id?: string, send_resolved?: bool}
# --webhook_configs item shape: {http_config?: record, max_alerts?: int, send_resolved?: bool, timeout?: int, url?: string, url_file?: string}
# --wechat_configs item shape: {agent_id?: string, api_secret?: string, api_secret_file?: string, api_url?: record, corp_id?: string, http_config?: record, message?: string, message_type?: string, send_resolved?: bool, to_party?: string, to_tag?: string, to_user?: string}
export def "channels CreateChannel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --discord-configs: list # item shape: {avatar_url?: string, content?: string, http_config?: record, message?: string, send_resolved?: bool, title?: string, username?: string, webhook_url?: record, webhook_url_file?: string}
  --email-configs: list # item shape: {auth_identity?: string, auth_password?: string, auth_password_file?: string, auth_secret?: string, auth_secret_file?: string, auth_username?: string, force_implicit_tls?: bool, from?: string, headers?: record, hello?: string, html?: string, require_tls?: bool, send_resolved?: bool, smarthost?: record, text?: string, threading?: record, tls_config?: record, to?: string}
  --googlechat-configs: list # item shape: {http_config?: record, send_resolved?: bool, text?: string, title?: string, webhook_url?: record}
  --incidentio-configs: list # item shape: {alert_source_token?: string, alert_source_token_file?: string, http_config?: record, max_alerts?: int, send_resolved?: bool, timeout?: int, url?: record, url_file?: string}
  --jira-configs: list # item shape: {api_type?: string, api_url?: record, custom_fields?: record, description?: record, http_config?: record, issue_type?: string, labels?: list, priority?: string, project?: string, reopen_duration?: int, reopen_transition?: string, resolve_transition?: string, send_resolved?: bool, summary?: record, wont_fix_resolution?: string}
  --mattermost-configs: list # item shape: {attachments?: list, channel?: string, http_config?: record, icon_emoji?: string, icon_url?: string, priority?: record, props?: record, send_resolved?: bool, text?: string, type?: string, username?: string, webhook_url?: record, webhook_url_file?: string}
  --msteams-configs: list # item shape: {http_config?: record, send_resolved?: bool, summary?: string, text?: string, title?: string, webhook_url?: record, webhook_url_file?: string}
  --msteamsv2-configs: list # item shape: {http_config?: record, send_resolved?: bool, text?: string, title?: string, webhook_url?: record, webhook_url_file?: string}
  name: string
  --opsgenie-configs: list # item shape: {actions?: string, api_key?: string, api_key_file?: string, api_url?: record, description?: string, details?: record, entity?: string, http_config?: record, message?: string, note?: string, priority?: string, responders?: list, send_resolved?: bool, source?: string, tags?: string, update_alerts?: bool}
  --pagerduty-configs: list # item shape: {class?: string, client?: string, client_url?: string, component?: string, description?: string, details?: record, group?: string, http_config?: record, images?: list, links?: list, routing_key?: string, routing_key_file?: string, send_resolved?: bool, service_key?: string, service_key_file?: string, severity?: string, source?: string, timeout?: int, url?: record}
  --pushover-configs: list # item shape: {device?: string, expire?: string, html?: bool, http_config?: record, message?: string, monospace?: bool, priority?: string, retry?: string, send_resolved?: bool, sound?: string, title?: string, token?: string, token_file?: string, ttl?: string, url?: string, url_title?: string, user_key?: string, user_key_file?: string}
  --rocketchat-configs: list # item shape: {actions?: list, api_url?: record, channel?: string, color?: string, emoji?: string, fields?: list, http_config?: record, icon_url?: string, image_url?: string, link_names?: bool, send_resolved?: bool, short_fields?: bool, text?: string, thumb_url?: string, title?: string, title_link?: string, token?: string, token_file?: string, token_id?: string, token_id_file?: string}
  --slack-configs: list # item shape: {actions?: list, api_url?: record, api_url_file?: string, app_token?: string, app_token_file?: string, app_url?: record, callback_id?: string, channel?: string, color?: string, fallback?: string, fields?: list, footer?: string, http_config?: record, icon_emoji?: string, icon_url?: string, image_url?: string, link_names?: bool, message_text?: string, mrkdwn_in?: list, pretext?: string, send_resolved?: bool, short_fields?: bool, text?: string, thumb_url?: string, timeout?: int, title?: string, title_link?: string, username?: string}
  --sns-configs: list # item shape: {api_url?: string, attributes?: record, http_config?: record, message?: string, phone_number?: string, send_resolved?: bool, sigv4?: record, subject?: string, target_arn?: string, topic_arn?: string}
  --telegram-configs: list # item shape: {api_url?: record, chat?: int, chat_file?: string, disable_notifications?: bool, http_config?: record, message?: string, message_thread_id?: int, parse_mode?: string, send_resolved?: bool, token?: string, token_file?: string}
  --victorops-configs: list # item shape: {api_key?: string, api_key_file?: string, api_url?: record, custom_fields?: record, entity_display_name?: string, http_config?: record, message_type?: string, monitoring_tool?: string, routing_key?: string, send_resolved?: bool, state_message?: string}
  --webex-configs: list # item shape: {api_url?: record, http_config?: record, message?: string, room_id?: string, send_resolved?: bool}
  --webhook-configs: list # item shape: {http_config?: record, max_alerts?: int, send_resolved?: bool, timeout?: int, url?: string, url_file?: string}
  --wechat-configs: list # item shape: {agent_id?: string, api_secret?: string, api_secret_file?: string, api_url?: record, corp_id?: string, http_config?: record, message?: string, message_type?: string, send_resolved?: bool, to_party?: string, to_tag?: string, to_user?: string}
]: any -> record<data: record<createdAt: string, data: string, id: string, name: string, orgId: string, type: string, updatedAt: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/channels")
  let body = {discord_configs: $discord_configs, email_configs: $email_configs, googlechat_configs: $googlechat_configs, incidentio_configs: $incidentio_configs, jira_configs: $jira_configs, mattermost_configs: $mattermost_configs, msteams_configs: $msteams_configs, msteamsv2_configs: $msteamsv2_configs, name: $name, opsgenie_configs: $opsgenie_configs, pagerduty_configs: $pagerduty_configs, pushover_configs: $pushover_configs, rocketchat_configs: $rocketchat_configs, slack_configs: $slack_configs, sns_configs: $sns_configs, telegram_configs: $telegram_configs, victorops_configs: $victorops_configs, webex_configs: $webex_configs, webhook_configs: $webhook_configs, wechat_configs: $wechat_configs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete notification channel
#
# DELETE /api/v1/channels/{id}
# operationId: DeleteChannelByID
export def "channels DeleteChannelByID" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/channels/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get notification channel by ID
#
# GET /api/v1/channels/{id}
# operationId: GetChannelByID
export def "channels GetChannelByID" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<createdAt: string, data: string, id: string, name: string, orgId: string, type: string, updatedAt: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/channels/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update notification channel
#
# PUT /api/v1/channels/{id}
# operationId: UpdateChannelByID
# --discord_configs item shape: {avatar_url?: string, content?: string, http_config?: record, message?: string, send_resolved?: bool, title?: string, username?: string, webhook_url?: record, webhook_url_file?: string}
# --email_configs item shape: {auth_identity?: string, auth_password?: string, auth_password_file?: string, auth_secret?: string, auth_secret_file?: string, auth_username?: string, force_implicit_tls?: bool, from?: string, headers?: record, hello?: string, html?: string, require_tls?: bool, send_resolved?: bool, smarthost?: record, text?: string, threading?: record, tls_config?: record, to?: string}
# --googlechat_configs item shape: {http_config?: record, send_resolved?: bool, text?: string, title?: string, webhook_url?: record}
# --incidentio_configs item shape: {alert_source_token?: string, alert_source_token_file?: string, http_config?: record, max_alerts?: int, send_resolved?: bool, timeout?: int, url?: record, url_file?: string}
# --jira_configs item shape: {api_type?: string, api_url?: record, custom_fields?: record, description?: record, http_config?: record, issue_type?: string, labels?: list, priority?: string, project?: string, reopen_duration?: int, reopen_transition?: string, resolve_transition?: string, send_resolved?: bool, summary?: record, wont_fix_resolution?: string}
# --mattermost_configs item shape: {attachments?: list, channel?: string, http_config?: record, icon_emoji?: string, icon_url?: string, priority?: record, props?: record, send_resolved?: bool, text?: string, type?: string, username?: string, webhook_url?: record, webhook_url_file?: string}
# --msteams_configs item shape: {http_config?: record, send_resolved?: bool, summary?: string, text?: string, title?: string, webhook_url?: record, webhook_url_file?: string}
# --msteamsv2_configs item shape: {http_config?: record, send_resolved?: bool, text?: string, title?: string, webhook_url?: record, webhook_url_file?: string}
# --opsgenie_configs item shape: {actions?: string, api_key?: string, api_key_file?: string, api_url?: record, description?: string, details?: record, entity?: string, http_config?: record, message?: string, note?: string, priority?: string, responders?: list, send_resolved?: bool, source?: string, tags?: string, update_alerts?: bool}
# --pagerduty_configs item shape: {class?: string, client?: string, client_url?: string, component?: string, description?: string, details?: record, group?: string, http_config?: record, images?: list, links?: list, routing_key?: string, routing_key_file?: string, send_resolved?: bool, service_key?: string, service_key_file?: string, severity?: string, source?: string, timeout?: int, url?: record}
# --pushover_configs item shape: {device?: string, expire?: string, html?: bool, http_config?: record, message?: string, monospace?: bool, priority?: string, retry?: string, send_resolved?: bool, sound?: string, title?: string, token?: string, token_file?: string, ttl?: string, url?: string, url_title?: string, user_key?: string, user_key_file?: string}
# --rocketchat_configs item shape: {actions?: list, api_url?: record, channel?: string, color?: string, emoji?: string, fields?: list, http_config?: record, icon_url?: string, image_url?: string, link_names?: bool, send_resolved?: bool, short_fields?: bool, text?: string, thumb_url?: string, title?: string, title_link?: string, token?: string, token_file?: string, token_id?: string, token_id_file?: string}
# --slack_configs item shape: {actions?: list, api_url?: record, api_url_file?: string, app_token?: string, app_token_file?: string, app_url?: record, callback_id?: string, channel?: string, color?: string, fallback?: string, fields?: list, footer?: string, http_config?: record, icon_emoji?: string, icon_url?: string, image_url?: string, link_names?: bool, message_text?: string, mrkdwn_in?: list, pretext?: string, send_resolved?: bool, short_fields?: bool, text?: string, thumb_url?: string, timeout?: int, title?: string, title_link?: string, username?: string}
# --sns_configs item shape: {api_url?: string, attributes?: record, http_config?: record, message?: string, phone_number?: string, send_resolved?: bool, sigv4?: record, subject?: string, target_arn?: string, topic_arn?: string}
# --telegram_configs item shape: {api_url?: record, chat?: int, chat_file?: string, disable_notifications?: bool, http_config?: record, message?: string, message_thread_id?: int, parse_mode?: string, send_resolved?: bool, token?: string, token_file?: string}
# --victorops_configs item shape: {api_key?: string, api_key_file?: string, api_url?: record, custom_fields?: record, entity_display_name?: string, http_config?: record, message_type?: string, monitoring_tool?: string, routing_key?: string, send_resolved?: bool, state_message?: string}
# --webex_configs item shape: {api_url?: record, http_config?: record, message?: string, room_id?: string, send_resolved?: bool}
# --webhook_configs item shape: {http_config?: record, max_alerts?: int, send_resolved?: bool, timeout?: int, url?: string, url_file?: string}
# --wechat_configs item shape: {agent_id?: string, api_secret?: string, api_secret_file?: string, api_url?: record, corp_id?: string, http_config?: record, message?: string, message_type?: string, send_resolved?: bool, to_party?: string, to_tag?: string, to_user?: string}
export def "channels UpdateChannelByID" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --discord-configs: list # item shape: {avatar_url?: string, content?: string, http_config?: record, message?: string, send_resolved?: bool, title?: string, username?: string, webhook_url?: record, webhook_url_file?: string}
  --email-configs: list # item shape: {auth_identity?: string, auth_password?: string, auth_password_file?: string, auth_secret?: string, auth_secret_file?: string, auth_username?: string, force_implicit_tls?: bool, from?: string, headers?: record, hello?: string, html?: string, require_tls?: bool, send_resolved?: bool, smarthost?: record, text?: string, threading?: record, tls_config?: record, to?: string}
  --googlechat-configs: list # item shape: {http_config?: record, send_resolved?: bool, text?: string, title?: string, webhook_url?: record}
  --incidentio-configs: list # item shape: {alert_source_token?: string, alert_source_token_file?: string, http_config?: record, max_alerts?: int, send_resolved?: bool, timeout?: int, url?: record, url_file?: string}
  --jira-configs: list # item shape: {api_type?: string, api_url?: record, custom_fields?: record, description?: record, http_config?: record, issue_type?: string, labels?: list, priority?: string, project?: string, reopen_duration?: int, reopen_transition?: string, resolve_transition?: string, send_resolved?: bool, summary?: record, wont_fix_resolution?: string}
  --mattermost-configs: list # item shape: {attachments?: list, channel?: string, http_config?: record, icon_emoji?: string, icon_url?: string, priority?: record, props?: record, send_resolved?: bool, text?: string, type?: string, username?: string, webhook_url?: record, webhook_url_file?: string}
  --msteams-configs: list # item shape: {http_config?: record, send_resolved?: bool, summary?: string, text?: string, title?: string, webhook_url?: record, webhook_url_file?: string}
  --msteamsv2-configs: list # item shape: {http_config?: record, send_resolved?: bool, text?: string, title?: string, webhook_url?: record, webhook_url_file?: string}
  --name: string
  --opsgenie-configs: list # item shape: {actions?: string, api_key?: string, api_key_file?: string, api_url?: record, description?: string, details?: record, entity?: string, http_config?: record, message?: string, note?: string, priority?: string, responders?: list, send_resolved?: bool, source?: string, tags?: string, update_alerts?: bool}
  --pagerduty-configs: list # item shape: {class?: string, client?: string, client_url?: string, component?: string, description?: string, details?: record, group?: string, http_config?: record, images?: list, links?: list, routing_key?: string, routing_key_file?: string, send_resolved?: bool, service_key?: string, service_key_file?: string, severity?: string, source?: string, timeout?: int, url?: record}
  --pushover-configs: list # item shape: {device?: string, expire?: string, html?: bool, http_config?: record, message?: string, monospace?: bool, priority?: string, retry?: string, send_resolved?: bool, sound?: string, title?: string, token?: string, token_file?: string, ttl?: string, url?: string, url_title?: string, user_key?: string, user_key_file?: string}
  --rocketchat-configs: list # item shape: {actions?: list, api_url?: record, channel?: string, color?: string, emoji?: string, fields?: list, http_config?: record, icon_url?: string, image_url?: string, link_names?: bool, send_resolved?: bool, short_fields?: bool, text?: string, thumb_url?: string, title?: string, title_link?: string, token?: string, token_file?: string, token_id?: string, token_id_file?: string}
  --slack-configs: list # item shape: {actions?: list, api_url?: record, api_url_file?: string, app_token?: string, app_token_file?: string, app_url?: record, callback_id?: string, channel?: string, color?: string, fallback?: string, fields?: list, footer?: string, http_config?: record, icon_emoji?: string, icon_url?: string, image_url?: string, link_names?: bool, message_text?: string, mrkdwn_in?: list, pretext?: string, send_resolved?: bool, short_fields?: bool, text?: string, thumb_url?: string, timeout?: int, title?: string, title_link?: string, username?: string}
  --sns-configs: list # item shape: {api_url?: string, attributes?: record, http_config?: record, message?: string, phone_number?: string, send_resolved?: bool, sigv4?: record, subject?: string, target_arn?: string, topic_arn?: string}
  --telegram-configs: list # item shape: {api_url?: record, chat?: int, chat_file?: string, disable_notifications?: bool, http_config?: record, message?: string, message_thread_id?: int, parse_mode?: string, send_resolved?: bool, token?: string, token_file?: string}
  --victorops-configs: list # item shape: {api_key?: string, api_key_file?: string, api_url?: record, custom_fields?: record, entity_display_name?: string, http_config?: record, message_type?: string, monitoring_tool?: string, routing_key?: string, send_resolved?: bool, state_message?: string}
  --webex-configs: list # item shape: {api_url?: record, http_config?: record, message?: string, room_id?: string, send_resolved?: bool}
  --webhook-configs: list # item shape: {http_config?: record, max_alerts?: int, send_resolved?: bool, timeout?: int, url?: string, url_file?: string}
  --wechat-configs: list # item shape: {agent_id?: string, api_secret?: string, api_secret_file?: string, api_url?: record, corp_id?: string, http_config?: record, message?: string, message_type?: string, send_resolved?: bool, to_party?: string, to_tag?: string, to_user?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/channels/($id)")
  let body = {discord_configs: $discord_configs, email_configs: $email_configs, googlechat_configs: $googlechat_configs, incidentio_configs: $incidentio_configs, jira_configs: $jira_configs, mattermost_configs: $mattermost_configs, msteams_configs: $msteams_configs, msteamsv2_configs: $msteamsv2_configs, name: $name, opsgenie_configs: $opsgenie_configs, pagerduty_configs: $pagerduty_configs, pushover_configs: $pushover_configs, rocketchat_configs: $rocketchat_configs, slack_configs: $slack_configs, sns_configs: $sns_configs, telegram_configs: $telegram_configs, victorops_configs: $victorops_configs, webex_configs: $webex_configs, webhook_configs: $webhook_configs, wechat_configs: $wechat_configs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Test notification channel
#
# POST /api/v1/channels/test
# operationId: TestChannel
# --discord_configs item shape: {avatar_url?: string, content?: string, http_config?: record, message?: string, send_resolved?: bool, title?: string, username?: string, webhook_url?: record, webhook_url_file?: string}
# --email_configs item shape: {auth_identity?: string, auth_password?: string, auth_password_file?: string, auth_secret?: string, auth_secret_file?: string, auth_username?: string, force_implicit_tls?: bool, from?: string, headers?: record, hello?: string, html?: string, require_tls?: bool, send_resolved?: bool, smarthost?: record, text?: string, threading?: record, tls_config?: record, to?: string}
# --googlechat_configs item shape: {http_config?: record, send_resolved?: bool, text?: string, title?: string, webhook_url?: record}
# --incidentio_configs item shape: {alert_source_token?: string, alert_source_token_file?: string, http_config?: record, max_alerts?: int, send_resolved?: bool, timeout?: int, url?: record, url_file?: string}
# --jira_configs item shape: {api_type?: string, api_url?: record, custom_fields?: record, description?: record, http_config?: record, issue_type?: string, labels?: list, priority?: string, project?: string, reopen_duration?: int, reopen_transition?: string, resolve_transition?: string, send_resolved?: bool, summary?: record, wont_fix_resolution?: string}
# --mattermost_configs item shape: {attachments?: list, channel?: string, http_config?: record, icon_emoji?: string, icon_url?: string, priority?: record, props?: record, send_resolved?: bool, text?: string, type?: string, username?: string, webhook_url?: record, webhook_url_file?: string}
# --msteams_configs item shape: {http_config?: record, send_resolved?: bool, summary?: string, text?: string, title?: string, webhook_url?: record, webhook_url_file?: string}
# --msteamsv2_configs item shape: {http_config?: record, send_resolved?: bool, text?: string, title?: string, webhook_url?: record, webhook_url_file?: string}
# --opsgenie_configs item shape: {actions?: string, api_key?: string, api_key_file?: string, api_url?: record, description?: string, details?: record, entity?: string, http_config?: record, message?: string, note?: string, priority?: string, responders?: list, send_resolved?: bool, source?: string, tags?: string, update_alerts?: bool}
# --pagerduty_configs item shape: {class?: string, client?: string, client_url?: string, component?: string, description?: string, details?: record, group?: string, http_config?: record, images?: list, links?: list, routing_key?: string, routing_key_file?: string, send_resolved?: bool, service_key?: string, service_key_file?: string, severity?: string, source?: string, timeout?: int, url?: record}
# --pushover_configs item shape: {device?: string, expire?: string, html?: bool, http_config?: record, message?: string, monospace?: bool, priority?: string, retry?: string, send_resolved?: bool, sound?: string, title?: string, token?: string, token_file?: string, ttl?: string, url?: string, url_title?: string, user_key?: string, user_key_file?: string}
# --rocketchat_configs item shape: {actions?: list, api_url?: record, channel?: string, color?: string, emoji?: string, fields?: list, http_config?: record, icon_url?: string, image_url?: string, link_names?: bool, send_resolved?: bool, short_fields?: bool, text?: string, thumb_url?: string, title?: string, title_link?: string, token?: string, token_file?: string, token_id?: string, token_id_file?: string}
# --slack_configs item shape: {actions?: list, api_url?: record, api_url_file?: string, app_token?: string, app_token_file?: string, app_url?: record, callback_id?: string, channel?: string, color?: string, fallback?: string, fields?: list, footer?: string, http_config?: record, icon_emoji?: string, icon_url?: string, image_url?: string, link_names?: bool, message_text?: string, mrkdwn_in?: list, pretext?: string, send_resolved?: bool, short_fields?: bool, text?: string, thumb_url?: string, timeout?: int, title?: string, title_link?: string, username?: string}
# --sns_configs item shape: {api_url?: string, attributes?: record, http_config?: record, message?: string, phone_number?: string, send_resolved?: bool, sigv4?: record, subject?: string, target_arn?: string, topic_arn?: string}
# --telegram_configs item shape: {api_url?: record, chat?: int, chat_file?: string, disable_notifications?: bool, http_config?: record, message?: string, message_thread_id?: int, parse_mode?: string, send_resolved?: bool, token?: string, token_file?: string}
# --victorops_configs item shape: {api_key?: string, api_key_file?: string, api_url?: record, custom_fields?: record, entity_display_name?: string, http_config?: record, message_type?: string, monitoring_tool?: string, routing_key?: string, send_resolved?: bool, state_message?: string}
# --webex_configs item shape: {api_url?: record, http_config?: record, message?: string, room_id?: string, send_resolved?: bool}
# --webhook_configs item shape: {http_config?: record, max_alerts?: int, send_resolved?: bool, timeout?: int, url?: string, url_file?: string}
# --wechat_configs item shape: {agent_id?: string, api_secret?: string, api_secret_file?: string, api_url?: record, corp_id?: string, http_config?: record, message?: string, message_type?: string, send_resolved?: bool, to_party?: string, to_tag?: string, to_user?: string}
export def "channels-test TestChannel" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --discord-configs: list # item shape: {avatar_url?: string, content?: string, http_config?: record, message?: string, send_resolved?: bool, title?: string, username?: string, webhook_url?: record, webhook_url_file?: string}
  --email-configs: list # item shape: {auth_identity?: string, auth_password?: string, auth_password_file?: string, auth_secret?: string, auth_secret_file?: string, auth_username?: string, force_implicit_tls?: bool, from?: string, headers?: record, hello?: string, html?: string, require_tls?: bool, send_resolved?: bool, smarthost?: record, text?: string, threading?: record, tls_config?: record, to?: string}
  --googlechat-configs: list # item shape: {http_config?: record, send_resolved?: bool, text?: string, title?: string, webhook_url?: record}
  --incidentio-configs: list # item shape: {alert_source_token?: string, alert_source_token_file?: string, http_config?: record, max_alerts?: int, send_resolved?: bool, timeout?: int, url?: record, url_file?: string}
  --jira-configs: list # item shape: {api_type?: string, api_url?: record, custom_fields?: record, description?: record, http_config?: record, issue_type?: string, labels?: list, priority?: string, project?: string, reopen_duration?: int, reopen_transition?: string, resolve_transition?: string, send_resolved?: bool, summary?: record, wont_fix_resolution?: string}
  --mattermost-configs: list # item shape: {attachments?: list, channel?: string, http_config?: record, icon_emoji?: string, icon_url?: string, priority?: record, props?: record, send_resolved?: bool, text?: string, type?: string, username?: string, webhook_url?: record, webhook_url_file?: string}
  --msteams-configs: list # item shape: {http_config?: record, send_resolved?: bool, summary?: string, text?: string, title?: string, webhook_url?: record, webhook_url_file?: string}
  --msteamsv2-configs: list # item shape: {http_config?: record, send_resolved?: bool, text?: string, title?: string, webhook_url?: record, webhook_url_file?: string}
  --name: string
  --opsgenie-configs: list # item shape: {actions?: string, api_key?: string, api_key_file?: string, api_url?: record, description?: string, details?: record, entity?: string, http_config?: record, message?: string, note?: string, priority?: string, responders?: list, send_resolved?: bool, source?: string, tags?: string, update_alerts?: bool}
  --pagerduty-configs: list # item shape: {class?: string, client?: string, client_url?: string, component?: string, description?: string, details?: record, group?: string, http_config?: record, images?: list, links?: list, routing_key?: string, routing_key_file?: string, send_resolved?: bool, service_key?: string, service_key_file?: string, severity?: string, source?: string, timeout?: int, url?: record}
  --pushover-configs: list # item shape: {device?: string, expire?: string, html?: bool, http_config?: record, message?: string, monospace?: bool, priority?: string, retry?: string, send_resolved?: bool, sound?: string, title?: string, token?: string, token_file?: string, ttl?: string, url?: string, url_title?: string, user_key?: string, user_key_file?: string}
  --rocketchat-configs: list # item shape: {actions?: list, api_url?: record, channel?: string, color?: string, emoji?: string, fields?: list, http_config?: record, icon_url?: string, image_url?: string, link_names?: bool, send_resolved?: bool, short_fields?: bool, text?: string, thumb_url?: string, title?: string, title_link?: string, token?: string, token_file?: string, token_id?: string, token_id_file?: string}
  --slack-configs: list # item shape: {actions?: list, api_url?: record, api_url_file?: string, app_token?: string, app_token_file?: string, app_url?: record, callback_id?: string, channel?: string, color?: string, fallback?: string, fields?: list, footer?: string, http_config?: record, icon_emoji?: string, icon_url?: string, image_url?: string, link_names?: bool, message_text?: string, mrkdwn_in?: list, pretext?: string, send_resolved?: bool, short_fields?: bool, text?: string, thumb_url?: string, timeout?: int, title?: string, title_link?: string, username?: string}
  --sns-configs: list # item shape: {api_url?: string, attributes?: record, http_config?: record, message?: string, phone_number?: string, send_resolved?: bool, sigv4?: record, subject?: string, target_arn?: string, topic_arn?: string}
  --telegram-configs: list # item shape: {api_url?: record, chat?: int, chat_file?: string, disable_notifications?: bool, http_config?: record, message?: string, message_thread_id?: int, parse_mode?: string, send_resolved?: bool, token?: string, token_file?: string}
  --victorops-configs: list # item shape: {api_key?: string, api_key_file?: string, api_url?: record, custom_fields?: record, entity_display_name?: string, http_config?: record, message_type?: string, monitoring_tool?: string, routing_key?: string, send_resolved?: bool, state_message?: string}
  --webex-configs: list # item shape: {api_url?: record, http_config?: record, message?: string, room_id?: string, send_resolved?: bool}
  --webhook-configs: list # item shape: {http_config?: record, max_alerts?: int, send_resolved?: bool, timeout?: int, url?: string, url_file?: string}
  --wechat-configs: list # item shape: {agent_id?: string, api_secret?: string, api_secret_file?: string, api_url?: record, corp_id?: string, http_config?: record, message?: string, message_type?: string, send_resolved?: bool, to_party?: string, to_tag?: string, to_user?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/channels/test")
  let body = {discord_configs: $discord_configs, email_configs: $email_configs, googlechat_configs: $googlechat_configs, incidentio_configs: $incidentio_configs, jira_configs: $jira_configs, mattermost_configs: $mattermost_configs, msteams_configs: $msteams_configs, msteamsv2_configs: $msteamsv2_configs, name: $name, opsgenie_configs: $opsgenie_configs, pagerduty_configs: $pagerduty_configs, pushover_configs: $pushover_configs, rocketchat_configs: $rocketchat_configs, slack_configs: $slack_configs, sns_configs: $sns_configs, telegram_configs: $telegram_configs, victorops_configs: $victorops_configs, webex_configs: $webex_configs, webhook_configs: $webhook_configs, wechat_configs: $wechat_configs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Agent check-in
#
# POST /api/v1/cloud-integrations/{cloud_provider}/agent-check-in
# DEPRECATED
# operationId: AgentCheckInDeprecated
@deprecated
export def "cloud-integrations-agent-check-in AgentCheckInDeprecated" [
  cloud_provider: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --account-id: string
  --cloud-account-id: string
  --cloudIntegrationId: string
  --data: record # nullable
  --providerAccountId: string
]: any -> record<data: record<account_id: string, cloud_account_id: string, cloudIntegrationId: string, integration_config: record<enabled_regions: list, telemetry: record>, integrationConfig: record<aws: record, azure: record>, providerAccountId: string, removed_at: string, removedAt: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/cloud-integrations/($cloud_provider)/agent-check-in")
  let body = {account_id: $account_id, cloud_account_id: $cloud_account_id, cloudIntegrationId: $cloudIntegrationId, data: $data, providerAccountId: $providerAccountId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List accounts
#
# GET /api/v1/cloud_integrations/{cloud_provider}/accounts
# operationId: ListAccounts
export def "cloud-integrations-accounts ListAccounts" [
  cloud_provider: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<accounts: list<record>>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/cloud_integrations/($cloud_provider)/accounts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create account
#
# POST /api/v1/cloud_integrations/{cloud_provider}/accounts
# operationId: CreateAccount
# --config shape: {aws?: record, azure?: record}
# --credentials shape: {ingestionKey: string, ingestionUrl: string, sigNozApiKey: string, sigNozApiUrl: string}
export def "cloud-integrations-accounts CreateAccount" [
  cloud_provider: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  config: record # shape: {aws?: record, azure?: record}
  credentials: record # shape: {ingestionKey: string, ingestionUrl: string, sigNozApiKey: string, sigNozApiUrl: string}
]: any -> record<data: record<connectionArtifact: record<aws: record, azure: record>, id: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/cloud_integrations/($cloud_provider)/accounts")
  let body = {config: $config, credentials: $credentials} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Disconnect account
#
# DELETE /api/v1/cloud_integrations/{cloud_provider}/accounts/{id}
# operationId: DisconnectAccount
export def "cloud-integrations-accounts DisconnectAccount" [
  cloud_provider: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/cloud_integrations/($cloud_provider)/accounts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get account
#
# GET /api/v1/cloud_integrations/{cloud_provider}/accounts/{id}
# operationId: GetAccount
export def "cloud-integrations-accounts GetAccount" [
  cloud_provider: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<agentReport: record<data: record, timestampMillis: int>, config: record<aws: record, azure: record>, createdAt: string, id: string, orgId: string, provider: string, providerAccountId: string, removedAt: string, updatedAt: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/cloud_integrations/($cloud_provider)/accounts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update account
#
# PUT /api/v1/cloud_integrations/{cloud_provider}/accounts/{id}
# operationId: UpdateAccount
# --config shape: {aws?: record, azure?: record}
export def "cloud-integrations-accounts UpdateAccount" [
  cloud_provider: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  config: record # shape: {aws?: record, azure?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/cloud_integrations/($cloud_provider)/accounts/($id)")
  let body = {config: $config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List account services metadata
#
# GET /api/v1/cloud_integrations/{cloud_provider}/accounts/{id}/services
# operationId: ListAccountServicesMetadata
export def "cloud-integrations-accounts-services ListAccountServicesMetadata" [
  cloud_provider: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<services: list<record>>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/cloud_integrations/($cloud_provider)/accounts/($id)/services")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get service for account
#
# GET /api/v1/cloud_integrations/{cloud_provider}/accounts/{id}/services/{service_id}
# operationId: GetAccountService
export def "cloud-integrations-accounts-services GetAccountService" [
  cloud_provider: string
  id: string
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<assets: record<dashboards: list>, cloudIntegrationService: record<cloudIntegrationId: string, config: record, createdAt: string, id: string, type: string, updatedAt: string>, dataCollected: record<logs: list, metrics: list>, icon: string, id: string, overview: string, supportedSignals: record<logs: bool, metrics: bool>, title: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/cloud_integrations/($cloud_provider)/accounts/($id)/services/($service_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update service
#
# PUT /api/v1/cloud_integrations/{cloud_provider}/accounts/{id}/services/{service_id}
# operationId: UpdateService
# --config shape: {aws?: record, azure?: record}
export def "cloud-integrations-accounts-services UpdateService" [
  cloud_provider: string
  id: string
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  config: record # shape: {aws?: record, azure?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/cloud_integrations/($cloud_provider)/accounts/($id)/services/($service_id)")
  let body = {config: $config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Agent check-in
#
# POST /api/v1/cloud_integrations/{cloud_provider}/accounts/check_in
# operationId: AgentCheckIn
export def "cloud-integrations-accounts-check-in AgentCheckIn" [
  cloud_provider: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --account-id: string
  --cloud-account-id: string
  --cloudIntegrationId: string
  --data: record # nullable
  --providerAccountId: string
]: any -> record<data: record<account_id: string, cloud_account_id: string, cloudIntegrationId: string, integration_config: record<enabled_regions: list, telemetry: record>, integrationConfig: record<aws: record, azure: record>, providerAccountId: string, removed_at: string, removedAt: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/cloud_integrations/($cloud_provider)/accounts/check_in")
  let body = {account_id: $account_id, cloud_account_id: $cloud_account_id, cloudIntegrationId: $cloudIntegrationId, data: $data, providerAccountId: $providerAccountId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get connection credentials
#
# GET /api/v1/cloud_integrations/{cloud_provider}/credentials
# operationId: GetConnectionCredentials
export def "cloud-integrations-credentials GetConnectionCredentials" [
  cloud_provider: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<ingestionKey: string, ingestionUrl: string, sigNozApiKey: string, sigNozApiUrl: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/cloud_integrations/($cloud_provider)/credentials")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List services metadata
#
# GET /api/v1/cloud_integrations/{cloud_provider}/services
# operationId: ListServicesMetadata
export def "cloud-integrations-services ListServicesMetadata" [
  cloud_provider: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cloud-integration-id: string
]: nothing -> record<data: record<services: list<record>>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cloud_integration_id" $cloud_integration_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/cloud_integrations/($cloud_provider)/services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get service
#
# GET /api/v1/cloud_integrations/{cloud_provider}/services/{service_id}
# operationId: GetService
export def "cloud-integrations-services GetService" [
  cloud_provider: string
  service_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --cloud-integration-id: string
]: nothing -> record<data: record<assets: record<dashboards: list>, cloudIntegrationService: record<cloudIntegrationId: string, config: record, createdAt: string, id: string, type: string, updatedAt: string>, dataCollected: record<logs: list, metrics: list>, icon: string, id: string, overview: string, supportedSignals: record<logs: bool, metrics: bool>, title: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "cloud_integration_id" $cloud_integration_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/cloud_integrations/($cloud_provider)/services/($service_id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create session by google callback
#
# GET /api/v1/complete/google
# operationId: CreateSessionByGoogleCallback
export def "complete-google CreateSessionByGoogleCallback" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/complete/google")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create session by oidc callback
#
# GET /api/v1/complete/oidc
# operationId: CreateSessionByOIDCCallback
export def "complete-oidc CreateSessionByOIDCCallback" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/complete/oidc")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create session by saml callback
#
# POST /api/v1/complete/saml
# operationId: CreateSessionBySAMLCallback
export def "complete-saml CreateSessionBySAMLCallback" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --RelayState: string
  --SAMLResponse: string
  --RelayState: string
  --SAMLResponse: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "RelayState" $RelayState "scalar") (serialize-qp "SAMLResponse" $SAMLResponse "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/complete/saml" $qp)
  let body = {RelayState: $RelayState, SAMLResponse: $SAMLResponse} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete public dashboard
#
# DELETE /api/v1/dashboards/{id}/public
# operationId: DeletePublicDashboard
export def "dashboards-public DeletePublicDashboard" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/dashboards/($id)/public")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get public dashboard
#
# GET /api/v1/dashboards/{id}/public
# operationId: GetPublicDashboard
export def "dashboards-public GetPublicDashboard" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<defaultTimeRange: string, publicPath: string, timeRangeEnabled: bool>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/dashboards/($id)/public")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create public dashboard
#
# POST /api/v1/dashboards/{id}/public
# operationId: CreatePublicDashboard
export def "dashboards-public CreatePublicDashboard" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --defaultTimeRange: string
  --timeRangeEnabled: string@bool-completer
]: any -> record<data: record<id: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/dashboards/($id)/public")
  let body = {defaultTimeRange: $defaultTimeRange, timeRangeEnabled: $timeRangeEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update public dashboard
#
# PUT /api/v1/dashboards/{id}/public
# operationId: UpdatePublicDashboard
export def "dashboards-public UpdatePublicDashboard" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --defaultTimeRange: string
  --timeRangeEnabled: string@bool-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/dashboards/($id)/public")
  let body = {defaultTimeRange: $defaultTimeRange, timeRangeEnabled: $timeRangeEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all auth domains
#
# GET /api/v1/domains
# operationId: ListAuthDomains
export def "domains ListAuthDomains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<authNProviderInfo: record, config: record, createdAt: string, id: string, name: string, orgId: string, updatedAt: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/domains")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create auth domain
#
# POST /api/v1/domains
# operationId: CreateAuthDomain
# --config shape: {googleAuthConfig?: record, oidcConfig?: record, roleMapping?: record, samlConfig?: record, ssoEnabled?: bool, ssoType?: "google_auth"|"saml"|"email_password"|"oidc", attributeMapping?: record, insecureSkipAuthNRequestsSigned?: bool, samlCert?: string, samlEntity?: string, samlIdp?: string, allowedGroups?: list, clientId?: string, clientSecret?: string, domainToAdminEmail?: record, fetchGroups?: bool, fetchTransitiveGroupMembership?: bool, insecureSkipEmailVerified?: bool, redirectURI?: string, serviceAccountJson?: string, claimMapping?: record, getUserInfo?: bool, issuer?: string, issuerAlias?: string}
export def "domains CreateAuthDomain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --config: record # shape: {googleAuthConfig?: record, oidcConfig?: record, roleMapping?: record, samlConfig?: record, ssoEnabled?: bool, ssoType?: "google_auth"|"saml"|"email_password"|"oidc", attributeMapping?: record, insecureSkipAuthNRequestsSigned?: bool, samlCert?: string, samlEntity?: string, samlIdp?: string, allowedGroups?: list, clientId?: string, clientSecret?: string, domainToAdminEmail?: record, fetchGroups?: bool, fetchTransitiveGroupMembership?: bool, insecureSkipEmailVerified?: bool, redirectURI?: string, serviceAccountJson?: string, claimMapping?: record, getUserInfo?: bool, issuer?: string, issuerAlias?: string}
  --name: string
]: any -> record<data: record<id: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/domains")
  let body = {config: $config, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete auth domain
#
# DELETE /api/v1/domains/{id}
# operationId: DeleteAuthDomain
export def "domains DeleteAuthDomain" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/domains/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get auth domain by ID
#
# GET /api/v1/domains/{id}
# operationId: GetAuthDomain
export def "domains GetAuthDomain" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<authNProviderInfo: record<relayStatePath: string>, config: record<googleAuthConfig: record, oidcConfig: record, roleMapping: record, samlConfig: record, ssoEnabled: bool, ssoType: string>, createdAt: string, id: string, name: string, orgId: string, updatedAt: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/domains/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update auth domain
#
# PUT /api/v1/domains/{id}
# operationId: UpdateAuthDomain
# --config shape: {googleAuthConfig?: record, oidcConfig?: record, roleMapping?: record, samlConfig?: record, ssoEnabled?: bool, ssoType?: "google_auth"|"saml"|"email_password"|"oidc", attributeMapping?: record, insecureSkipAuthNRequestsSigned?: bool, samlCert?: string, samlEntity?: string, samlIdp?: string, allowedGroups?: list, clientId?: string, clientSecret?: string, domainToAdminEmail?: record, fetchGroups?: bool, fetchTransitiveGroupMembership?: bool, insecureSkipEmailVerified?: bool, redirectURI?: string, serviceAccountJson?: string, claimMapping?: record, getUserInfo?: bool, issuer?: string, issuerAlias?: string}
export def "domains UpdateAuthDomain" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --config: record # shape: {googleAuthConfig?: record, oidcConfig?: record, roleMapping?: record, samlConfig?: record, ssoEnabled?: bool, ssoType?: "google_auth"|"saml"|"email_password"|"oidc", attributeMapping?: record, insecureSkipAuthNRequestsSigned?: bool, samlCert?: string, samlEntity?: string, samlIdp?: string, allowedGroups?: list, clientId?: string, clientSecret?: string, domainToAdminEmail?: record, fetchGroups?: bool, fetchTransitiveGroupMembership?: bool, insecureSkipEmailVerified?: bool, redirectURI?: string, serviceAccountJson?: string, claimMapping?: record, getUserInfo?: bool, issuer?: string, issuerAlias?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/domains/($id)")
  let body = {config: $config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List downtime schedules
#
# GET /api/v1/downtime_schedules
# operationId: ListDowntimeSchedules
export def "downtime-schedules ListDowntimeSchedules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string@bool-completer # nullable
  --recurring: string@bool-completer # nullable
]: nothing -> record<data: table<alertIds: list, createdAt: string, createdBy: string, description: string, id: string, kind: string, name: string, schedule: record, scope: string, status: string, updatedAt: string, updatedBy: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "active" $active "scalar") (serialize-qp "recurring" $recurring "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/downtime_schedules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create downtime schedule
#
# POST /api/v1/downtime_schedules
# operationId: CreateDowntimeSchedule
# --schedule shape: {endTime?: string, recurrence?: record, startTime?: string, timezone: string}
export def "downtime-schedules CreateDowntimeSchedule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alertIds: list # nullable
  --description: string
  name: string
  schedule: record # shape: {endTime?: string, recurrence?: record, startTime?: string, timezone: string}
  --scope: string
]: any -> record<data: record<alertIds: list<string>, createdAt: string, createdBy: string, description: string, id: string, kind: string, name: string, schedule: record<endTime: string, recurrence: record, startTime: string, timezone: string>, scope: string, status: string, updatedAt: string, updatedBy: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/downtime_schedules")
  let body = {alertIds: $alertIds, description: $description, name: $name, schedule: $schedule, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete downtime schedule
#
# DELETE /api/v1/downtime_schedules/{id}
# operationId: DeleteDowntimeScheduleByID
export def "downtime-schedules DeleteDowntimeScheduleByID" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/downtime_schedules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get downtime schedule by ID
#
# GET /api/v1/downtime_schedules/{id}
# operationId: GetDowntimeScheduleByID
export def "downtime-schedules GetDowntimeScheduleByID" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<alertIds: list<string>, createdAt: string, createdBy: string, description: string, id: string, kind: string, name: string, schedule: record<endTime: string, recurrence: record, startTime: string, timezone: string>, scope: string, status: string, updatedAt: string, updatedBy: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/downtime_schedules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update downtime schedule
#
# PUT /api/v1/downtime_schedules/{id}
# operationId: UpdateDowntimeScheduleByID
# --schedule shape: {endTime?: string, recurrence?: record, startTime?: string, timezone: string}
export def "downtime-schedules UpdateDowntimeScheduleByID" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alertIds: list # nullable
  --description: string
  name: string
  schedule: record # shape: {endTime?: string, recurrence?: record, startTime?: string, timezone: string}
  --scope: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/downtime_schedules/($id)")
  let body = {alertIds: $alertIds, description: $description, name: $name, schedule: $schedule, scope: $scope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Export raw data
#
# POST /api/v1/export_raw_data
# operationId: HandleExportRawDataPOST
# --compositeQuery shape: {queries?: list}
# --formatOptions shape: {fillGaps?: bool, formatTableResultForUI?: bool}
export def "export-raw-data HandleExportRawDataPOST" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --format: string@format-completer # The output format for the export. (default: csv)
  --compositeQuery: record # Composite query containing one or more query envelopes. Each query envelope specifies its type and corresponding spec. — shape: {queries?: list}
  --end: int
  --formatOptions: record # shape: {fillGaps?: bool, formatTableResultForUI?: bool}
  --noCache: string@bool-completer
  --requestType: string@requestType-completer
  --schemaVersion: string
  --start: int
  --body-variables: record
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/export_raw_data" $qp)
  let body = {compositeQuery: $compositeQuery, end: $end, formatOptions: $formatOptions, noCache: $noCache, requestType: $requestType, schemaVersion: $schemaVersion, start: $start, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get field keys
#
# GET /api/v1/fields/keys
# operationId: GetFieldsKeys
export def "fields-keys GetFieldsKeys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --signal: string
  --qp-source: string
  --limit: int
  --startUnixMilli: int # format: int64
  --endUnixMilli: int # format: int64
  --fieldContext: string
  --fieldDataType: string
  --metricName: string
  --metricNamespace: string
  --searchText: string
]: nothing -> record<data: record<complete: bool, keys: record>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "signal" $signal "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "startUnixMilli" $startUnixMilli "scalar") (serialize-qp "endUnixMilli" $endUnixMilli "scalar") (serialize-qp "fieldContext" $fieldContext "scalar") (serialize-qp "fieldDataType" $fieldDataType "scalar") (serialize-qp "metricName" $metricName "scalar") (serialize-qp "metricNamespace" $metricNamespace "scalar") (serialize-qp "searchText" $searchText "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/fields/keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get field values
#
# GET /api/v1/fields/values
# operationId: GetFieldsValues
export def "fields-values GetFieldsValues" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --signal: string
  --qp-source: string
  --limit: int
  --startUnixMilli: int # format: int64
  --endUnixMilli: int # format: int64
  --fieldContext: string
  --fieldDataType: string
  --metricName: string
  --metricNamespace: string
  --searchText: string
  --name: string
  --existingQuery: string
]: nothing -> record<data: record<complete: bool, values: record<boolValues: list, numberValues: list, relatedValues: list, stringValues: list>>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "signal" $signal "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "startUnixMilli" $startUnixMilli "scalar") (serialize-qp "endUnixMilli" $endUnixMilli "scalar") (serialize-qp "fieldContext" $fieldContext "scalar") (serialize-qp "fieldDataType" $fieldDataType "scalar") (serialize-qp "metricName" $metricName "scalar") (serialize-qp "metricNamespace" $metricNamespace "scalar") (serialize-qp "searchText" $searchText "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "existingQuery" $existingQuery "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/fields/values" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get reset password token
#
# GET /api/v1/getResetPasswordToken/{id}
# DEPRECATED
# operationId: GetResetPasswordTokenDeprecated
@deprecated
export def "get-reset-password-token GetResetPasswordTokenDeprecated" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<expiresAt: string, id: string, passwordId: string, token: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/getResetPasswordToken/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get global config
#
# GET /api/v1/global/config
# operationId: GetGlobalConfig
export def "global-config GetGlobalConfig" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<ai_assistant_url: string, external_url: string, identN: record<apikey: record, impersonation: record, tokenizer: record>, ingestion_url: string, mcp_url: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/global/config")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create invite
#
# POST /api/v1/invite
# operationId: CreateInvite
export def "invite CreateInvite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string
  --frontendBaseUrl: string
  --name: string
  --role: string
]: any -> record<data: record<createdAt: string, email: string, id: string, inviteLink: string, name: string, orgId: string, role: string, token: string, updatedAt: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/invite")
  let body = {email: $email, frontendBaseUrl: $frontendBaseUrl, name: $name, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create bulk invite
#
# POST /api/v1/invite/bulk
# operationId: CreateBulkInvite
# --invites item shape: {email?: string, frontendBaseUrl?: string, name?: string, role?: string}
export def "invite-bulk CreateBulkInvite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  invites: list # item shape: {email?: string, frontendBaseUrl?: string, name?: string, role?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/invite/bulk")
  let body = {invites: $invites} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List pricing rules
#
# GET /api/v1/llm_pricing_rules
# operationId: ListLLMPricingRules
export def "llm-pricing-rules ListLLMPricingRules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --offset: int
  --limit: int
]: nothing -> record<data: record<items: list<record>, limit: int, offset: int, total: int>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/llm_pricing_rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or update pricing rules
#
# PUT /api/v1/llm_pricing_rules
# operationId: CreateOrUpdateLLMPricingRules
# --rules item shape: {enabled: bool, id?: string, isOverride?: bool, modelName: string, modelPattern: list, pricing: record, provider: string, sourceId?: string, unit: "per_million_tokens"}
export def "llm-pricing-rules CreateOrUpdateLLMPricingRules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --rules: list # nullable — item shape: {enabled: bool, id?: string, isOverride?: bool, modelName: string, modelPattern: list, pricing: record, provider: string, sourceId?: string, unit: "per_million_tokens"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/llm_pricing_rules")
  let body = {rules: $rules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a pricing rule
#
# DELETE /api/v1/llm_pricing_rules/{id}
# operationId: DeleteLLMPricingRule
export def "llm-pricing-rules DeleteLLMPricingRule" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/llm_pricing_rules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a pricing rule
#
# GET /api/v1/llm_pricing_rules/{id}
# operationId: GetLLMPricingRule
export def "llm-pricing-rules GetLLMPricingRule" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<createdAt: string, createdBy: string, enabled: bool, id: string, isOverride: bool, modelName: string, modelPattern: list<string>, orgId: string, pricing: record<cache: record, input: float, output: float>, provider: string, sourceId: string, syncedAt: string, unit: string, updatedAt: string, updatedBy: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/llm_pricing_rules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Promote and index paths
#
# GET /api/v1/logs/promote_paths
# operationId: ListPromotedAndIndexedPaths
export def "logs-promote-paths ListPromotedAndIndexedPaths" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<indexes: list, path: string, promote: bool>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/logs/promote_paths")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Promote and index paths
#
# POST /api/v1/logs/promote_paths
# operationId: HandlePromoteAndIndexPaths
export def "logs-promote-paths HandlePromoteAndIndexPaths" [
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
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/logs/promote_paths")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List org preferences
#
# GET /api/v1/org/preferences
# operationId: ListOrgPreferences
export def "org-preferences ListOrgPreferences" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<allowedScopes: list, allowedValues: list, defaultValue: record, description: string, name: string, value: record, valueType: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/org/preferences")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get org preference
#
# GET /api/v1/org/preferences/{name}
# operationId: GetOrgPreference
export def "org-preferences GetOrgPreference" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<allowedScopes: list<string>, allowedValues: list<string>, defaultValue: record, description: string, name: string, value: record, valueType: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/org/preferences/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update org preference
#
# PUT /api/v1/org/preferences/{name}
# operationId: UpdateOrgPreference
export def "org-preferences UpdateOrgPreference" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --value: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/org/preferences/($name)")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get public dashboard data
#
# GET /api/v1/public/dashboards/{id}
# operationId: GetPublicDashboardData
export def "public-dashboards GetPublicDashboardData" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<dashboard: record<createdAt: string, createdBy: string, data: record, id: string, locked: bool, org_id: string, source: record, updatedAt: string, updatedBy: string>, publicDashboard: record<defaultTimeRange: string, publicPath: string, timeRangeEnabled: bool>>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/public/dashboards/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get query range result
#
# GET /api/v1/public/dashboards/{id}/widgets/{idx}/query_range
# operationId: GetPublicDashboardWidgetQueryRange
export def "public-dashboards-widgets-query-range GetPublicDashboardWidgetQueryRange" [
  id: string
  idx: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<data: record<results: list>, meta: record<bytesScanned: int, durationMs: int, rowsScanned: int, stepIntervals: record>, type: string, warning: record<message: string, url: string, warnings: list>>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/public/dashboards/($id)/widgets/($idx)/query_range")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Reset password
#
# POST /api/v1/resetPassword
# operationId: ResetPassword
export def "reset-password ResetPassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --password: string
  --body-token: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/resetPassword")
  let body = {password: $password, token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List roles
#
# GET /api/v1/roles
# operationId: ListRoles
export def "roles ListRoles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<createdAt: string, description: string, id: string, name: string, orgId: string, type: string, updatedAt: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create role
#
# POST /api/v1/roles
# operationId: CreateRole
export def "roles CreateRole" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --description: string
  name: string
]: any -> record<data: record<id: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/roles")
  let body = {description: $description, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete role
#
# DELETE /api/v1/roles/{id}
# operationId: DeleteRole
export def "roles DeleteRole" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/roles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get role
#
# GET /api/v1/roles/{id}
# operationId: GetRole
export def "roles GetRole" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<createdAt: string, description: string, id: string, name: string, orgId: string, type: string, updatedAt: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/roles/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch role
#
# PATCH /api/v1/roles/{id}
# operationId: PatchRole
export def "roles PatchRole" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  description: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/roles/($id)")
  let body = {description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get objects for a role by relation
#
# GET /api/v1/roles/{id}/relations/{relation}/objects
# operationId: GetObjects
export def "roles-relations-objects GetObjects" [
  id: string
  relation: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<resource: record, selectors: list>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/roles/($id)/relations/($relation)/objects")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch objects for a role by relation
#
# PATCH /api/v1/roles/{id}/relations/{relation}/objects
# operationId: PatchObjects
# --additions item shape: {resource: record, selectors: list}
# --deletions item shape: {resource: record, selectors: list}
export def "roles-relations-objects PatchObjects" [
  id: string
  relation: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --additions: list # nullable — item shape: {resource: record, selectors: list}
  --deletions: list # nullable — item shape: {resource: record, selectors: list}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/roles/($id)/relations/($relation)/objects")
  let body = {additions: $additions, deletions: $deletions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List route policies
#
# GET /api/v1/route_policies
# operationId: GetAllRoutePolicies
export def "route-policies GetAllRoutePolicies" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<channels: list, createdAt: string, createdBy: string, description: string, expression: string, id: string, kind: string, name: string, tags: list, updatedAt: string, updatedBy: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/route_policies")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create route policy
#
# POST /api/v1/route_policies
# operationId: CreateRoutePolicy
export def "route-policies CreateRoutePolicy" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --channels: list # nullable
  --description: string
  expression: string
  --kind: string@kind-completer
  name: string
  --tags: list # nullable
]: any -> record<data: record<channels: list<string>, createdAt: string, createdBy: string, description: string, expression: string, id: string, kind: string, name: string, tags: list<string>, updatedAt: string, updatedBy: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/route_policies")
  let body = {channels: $channels, description: $description, expression: $expression, kind: $kind, name: $name, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete route policy
#
# DELETE /api/v1/route_policies/{id}
# operationId: DeleteRoutePolicyByID
export def "route-policies DeleteRoutePolicyByID" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/route_policies/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get route policy by ID
#
# GET /api/v1/route_policies/{id}
# operationId: GetRoutePolicyByID
export def "route-policies GetRoutePolicyByID" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<channels: list<string>, createdAt: string, createdBy: string, description: string, expression: string, id: string, kind: string, name: string, tags: list<string>, updatedAt: string, updatedBy: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/route_policies/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update route policy
#
# PUT /api/v1/route_policies/{id}
# operationId: UpdateRoutePolicy
export def "route-policies UpdateRoutePolicy" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --channels: list # nullable
  --description: string
  expression: string
  --kind: string@kind-completer
  name: string
  --tags: list # nullable
]: any -> record<data: record<channels: list<string>, createdAt: string, createdBy: string, description: string, expression: string, id: string, kind: string, name: string, tags: list<string>, updatedAt: string, updatedBy: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/route_policies/($id)")
  let body = {channels: $channels, description: $description, expression: $expression, kind: $kind, name: $name, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List service accounts
#
# GET /api/v1/service_accounts
# operationId: ListServiceAccounts
export def "service-accounts ListServiceAccounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<createdAt: string, email: string, id: string, name: string, orgId: string, status: string, updatedAt: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/service_accounts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create service account
#
# POST /api/v1/service_accounts
# operationId: CreateServiceAccount
export def "service-accounts CreateServiceAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
]: any -> record<data: record<id: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/service_accounts")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a service account
#
# DELETE /api/v1/service_accounts/{id}
# operationId: DeleteServiceAccount
export def "service-accounts DeleteServiceAccount" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/service_accounts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets a service account
#
# GET /api/v1/service_accounts/{id}
# operationId: GetServiceAccount
export def "service-accounts GetServiceAccount" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<createdAt: string, email: string, id: string, name: string, orgId: string, serviceAccountRoles: list<record>, status: string, updatedAt: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/service_accounts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a service account
#
# PUT /api/v1/service_accounts/{id}
# operationId: UpdateServiceAccount
export def "service-accounts UpdateServiceAccount" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/service_accounts/($id)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List service account keys
#
# GET /api/v1/service_accounts/{id}/keys
# operationId: ListServiceAccountKeys
export def "service-accounts-keys ListServiceAccountKeys" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<createdAt: string, expiresAt: int, id: string, lastObservedAt: string, name: string, serviceAccountId: string, updatedAt: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/service_accounts/($id)/keys")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a service account key
#
# POST /api/v1/service_accounts/{id}/keys
# operationId: CreateServiceAccountKey
export def "service-accounts-keys CreateServiceAccountKey" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  expiresAt: int
  name: string
]: any -> record<data: record<id: string, key: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/service_accounts/($id)/keys")
  let body = {expiresAt: $expiresAt, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Revoke a service account key
#
# DELETE /api/v1/service_accounts/{id}/keys/{fid}
# operationId: RevokeServiceAccountKey
export def "service-accounts-keys RevokeServiceAccountKey" [
  id: string
  fid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/service_accounts/($id)/keys/($fid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates a service account key
#
# PUT /api/v1/service_accounts/{id}/keys/{fid}
# operationId: UpdateServiceAccountKey
export def "service-accounts-keys UpdateServiceAccountKey" [
  id: string
  fid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  expiresAt: int
  name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/service_accounts/($id)/keys/($fid)")
  let body = {expiresAt: $expiresAt, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Gets service account roles
#
# GET /api/v1/service_accounts/{id}/roles
# operationId: GetServiceAccountRoles
export def "service-accounts-roles GetServiceAccountRoles" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<createdAt: string, description: string, id: string, name: string, orgId: string, type: string, updatedAt: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/service_accounts/($id)/roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create service account role
#
# POST /api/v1/service_accounts/{id}/roles
# operationId: CreateServiceAccountRole
export def "service-accounts-roles CreateServiceAccountRole" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-id: string
]: any -> record<data: record<id: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/service_accounts/($id)/roles")
  let body = {id: $body_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete service account role
#
# DELETE /api/v1/service_accounts/{id}/roles/{rid}
# operationId: DeleteServiceAccountRole
export def "service-accounts-roles DeleteServiceAccountRole" [
  id: string
  rid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/service_accounts/($id)/roles/($rid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets my service account
#
# GET /api/v1/service_accounts/me
# operationId: GetMyServiceAccount
export def "service-accounts-me GetMyServiceAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<createdAt: string, email: string, id: string, name: string, orgId: string, serviceAccountRoles: list<record>, status: string, updatedAt: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/service_accounts/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates my service account
#
# PUT /api/v1/service_accounts/me
# operationId: UpdateMyServiceAccount
export def "service-accounts-me UpdateMyServiceAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/service_accounts/me")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List span attribute mapping groups
#
# GET /api/v1/span_mapper_groups
# operationId: ListSpanMapperGroups
export def "span-mapper-groups ListSpanMapperGroups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --enabled: string@bool-completer # nullable
]: nothing -> record<data: record<items: list<record>>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "enabled" $enabled "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v1/span_mapper_groups" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a span attribute mapping group
#
# POST /api/v1/span_mapper_groups
# operationId: CreateSpanMapperGroup
# --condition shape: {attributes: list, resource: list}
export def "span-mapper-groups CreateSpanMapperGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --condition: record # nullable — shape: {attributes: list, resource: list}
  --enabled: string@bool-completer
  name: string
]: any -> record<data: record<condition: record<attributes: list, resource: list>, createdAt: string, createdBy: string, enabled: bool, id: string, name: string, orgId: string, updatedAt: string, updatedBy: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/span_mapper_groups")
  let body = {condition: $condition, enabled: $enabled, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a span attribute mapping group
#
# DELETE /api/v1/span_mapper_groups/{groupId}
# operationId: DeleteSpanMapperGroup
export def "span-mapper-groups DeleteSpanMapperGroup" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/span_mapper_groups/($groupId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a span attribute mapping group
#
# PATCH /api/v1/span_mapper_groups/{groupId}
# operationId: UpdateSpanMapperGroup
# --condition shape: {attributes: list, resource: list}
export def "span-mapper-groups UpdateSpanMapperGroup" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --condition: record # nullable — shape: {attributes: list, resource: list}
  --enabled: string@bool-completer # nullable
  --name: string # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/span_mapper_groups/($groupId)")
  let body = {condition: $condition, enabled: $enabled, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List span mappers for a group
#
# GET /api/v1/span_mapper_groups/{groupId}/span_mappers
# operationId: ListSpanMappers
export def "span-mapper-groups-span-mappers ListSpanMappers" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<items: list<record>>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/span_mapper_groups/($groupId)/span_mappers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a span mapper
#
# POST /api/v1/span_mapper_groups/{groupId}/span_mappers
# operationId: CreateSpanMapper
# --config shape: {sources: list}
export def "span-mapper-groups-span-mappers CreateSpanMapper" [
  groupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  config: record # shape: {sources: list}
  --enabled: string@bool-completer
  fieldContext: string@fieldContext-completer
  name: string
]: any -> record<data: record<config: record<sources: list>, createdAt: string, createdBy: string, enabled: bool, fieldContext: string, group_id: string, id: string, name: string, updatedAt: string, updatedBy: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/span_mapper_groups/($groupId)/span_mappers")
  let body = {config: $config, enabled: $enabled, fieldContext: $fieldContext, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a span mapper
#
# DELETE /api/v1/span_mapper_groups/{groupId}/span_mappers/{mapperId}
# operationId: DeleteSpanMapper
export def "span-mapper-groups-span-mappers DeleteSpanMapper" [
  groupId: string
  mapperId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/span_mapper_groups/($groupId)/span_mappers/($mapperId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a span mapper
#
# PATCH /api/v1/span_mapper_groups/{groupId}/span_mappers/{mapperId}
# operationId: UpdateSpanMapper
# --config shape: {sources: list}
export def "span-mapper-groups-span-mappers UpdateSpanMapper" [
  groupId: string
  mapperId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --config: record # shape: {sources: list}
  --enabled: string@bool-completer # nullable
  --fieldContext: string@fieldContext-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/span_mapper_groups/($groupId)/span_mappers/($mapperId)")
  let body = {config: $config, enabled: $enabled, fieldContext: $fieldContext} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Test notification channel (deprecated)
#
# POST /api/v1/testChannel
# DEPRECATED
# operationId: TestChannelDeprecated
# --discord_configs item shape: {avatar_url?: string, content?: string, http_config?: record, message?: string, send_resolved?: bool, title?: string, username?: string, webhook_url?: record, webhook_url_file?: string}
# --email_configs item shape: {auth_identity?: string, auth_password?: string, auth_password_file?: string, auth_secret?: string, auth_secret_file?: string, auth_username?: string, force_implicit_tls?: bool, from?: string, headers?: record, hello?: string, html?: string, require_tls?: bool, send_resolved?: bool, smarthost?: record, text?: string, threading?: record, tls_config?: record, to?: string}
# --googlechat_configs item shape: {http_config?: record, send_resolved?: bool, text?: string, title?: string, webhook_url?: record}
# --incidentio_configs item shape: {alert_source_token?: string, alert_source_token_file?: string, http_config?: record, max_alerts?: int, send_resolved?: bool, timeout?: int, url?: record, url_file?: string}
# --jira_configs item shape: {api_type?: string, api_url?: record, custom_fields?: record, description?: record, http_config?: record, issue_type?: string, labels?: list, priority?: string, project?: string, reopen_duration?: int, reopen_transition?: string, resolve_transition?: string, send_resolved?: bool, summary?: record, wont_fix_resolution?: string}
# --mattermost_configs item shape: {attachments?: list, channel?: string, http_config?: record, icon_emoji?: string, icon_url?: string, priority?: record, props?: record, send_resolved?: bool, text?: string, type?: string, username?: string, webhook_url?: record, webhook_url_file?: string}
# --msteams_configs item shape: {http_config?: record, send_resolved?: bool, summary?: string, text?: string, title?: string, webhook_url?: record, webhook_url_file?: string}
# --msteamsv2_configs item shape: {http_config?: record, send_resolved?: bool, text?: string, title?: string, webhook_url?: record, webhook_url_file?: string}
# --opsgenie_configs item shape: {actions?: string, api_key?: string, api_key_file?: string, api_url?: record, description?: string, details?: record, entity?: string, http_config?: record, message?: string, note?: string, priority?: string, responders?: list, send_resolved?: bool, source?: string, tags?: string, update_alerts?: bool}
# --pagerduty_configs item shape: {class?: string, client?: string, client_url?: string, component?: string, description?: string, details?: record, group?: string, http_config?: record, images?: list, links?: list, routing_key?: string, routing_key_file?: string, send_resolved?: bool, service_key?: string, service_key_file?: string, severity?: string, source?: string, timeout?: int, url?: record}
# --pushover_configs item shape: {device?: string, expire?: string, html?: bool, http_config?: record, message?: string, monospace?: bool, priority?: string, retry?: string, send_resolved?: bool, sound?: string, title?: string, token?: string, token_file?: string, ttl?: string, url?: string, url_title?: string, user_key?: string, user_key_file?: string}
# --rocketchat_configs item shape: {actions?: list, api_url?: record, channel?: string, color?: string, emoji?: string, fields?: list, http_config?: record, icon_url?: string, image_url?: string, link_names?: bool, send_resolved?: bool, short_fields?: bool, text?: string, thumb_url?: string, title?: string, title_link?: string, token?: string, token_file?: string, token_id?: string, token_id_file?: string}
# --slack_configs item shape: {actions?: list, api_url?: record, api_url_file?: string, app_token?: string, app_token_file?: string, app_url?: record, callback_id?: string, channel?: string, color?: string, fallback?: string, fields?: list, footer?: string, http_config?: record, icon_emoji?: string, icon_url?: string, image_url?: string, link_names?: bool, message_text?: string, mrkdwn_in?: list, pretext?: string, send_resolved?: bool, short_fields?: bool, text?: string, thumb_url?: string, timeout?: int, title?: string, title_link?: string, username?: string}
# --sns_configs item shape: {api_url?: string, attributes?: record, http_config?: record, message?: string, phone_number?: string, send_resolved?: bool, sigv4?: record, subject?: string, target_arn?: string, topic_arn?: string}
# --telegram_configs item shape: {api_url?: record, chat?: int, chat_file?: string, disable_notifications?: bool, http_config?: record, message?: string, message_thread_id?: int, parse_mode?: string, send_resolved?: bool, token?: string, token_file?: string}
# --victorops_configs item shape: {api_key?: string, api_key_file?: string, api_url?: record, custom_fields?: record, entity_display_name?: string, http_config?: record, message_type?: string, monitoring_tool?: string, routing_key?: string, send_resolved?: bool, state_message?: string}
# --webex_configs item shape: {api_url?: record, http_config?: record, message?: string, room_id?: string, send_resolved?: bool}
# --webhook_configs item shape: {http_config?: record, max_alerts?: int, send_resolved?: bool, timeout?: int, url?: string, url_file?: string}
# --wechat_configs item shape: {agent_id?: string, api_secret?: string, api_secret_file?: string, api_url?: record, corp_id?: string, http_config?: record, message?: string, message_type?: string, send_resolved?: bool, to_party?: string, to_tag?: string, to_user?: string}
@deprecated
export def "test-channel TestChannelDeprecated" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --discord-configs: list # item shape: {avatar_url?: string, content?: string, http_config?: record, message?: string, send_resolved?: bool, title?: string, username?: string, webhook_url?: record, webhook_url_file?: string}
  --email-configs: list # item shape: {auth_identity?: string, auth_password?: string, auth_password_file?: string, auth_secret?: string, auth_secret_file?: string, auth_username?: string, force_implicit_tls?: bool, from?: string, headers?: record, hello?: string, html?: string, require_tls?: bool, send_resolved?: bool, smarthost?: record, text?: string, threading?: record, tls_config?: record, to?: string}
  --googlechat-configs: list # item shape: {http_config?: record, send_resolved?: bool, text?: string, title?: string, webhook_url?: record}
  --incidentio-configs: list # item shape: {alert_source_token?: string, alert_source_token_file?: string, http_config?: record, max_alerts?: int, send_resolved?: bool, timeout?: int, url?: record, url_file?: string}
  --jira-configs: list # item shape: {api_type?: string, api_url?: record, custom_fields?: record, description?: record, http_config?: record, issue_type?: string, labels?: list, priority?: string, project?: string, reopen_duration?: int, reopen_transition?: string, resolve_transition?: string, send_resolved?: bool, summary?: record, wont_fix_resolution?: string}
  --mattermost-configs: list # item shape: {attachments?: list, channel?: string, http_config?: record, icon_emoji?: string, icon_url?: string, priority?: record, props?: record, send_resolved?: bool, text?: string, type?: string, username?: string, webhook_url?: record, webhook_url_file?: string}
  --msteams-configs: list # item shape: {http_config?: record, send_resolved?: bool, summary?: string, text?: string, title?: string, webhook_url?: record, webhook_url_file?: string}
  --msteamsv2-configs: list # item shape: {http_config?: record, send_resolved?: bool, text?: string, title?: string, webhook_url?: record, webhook_url_file?: string}
  --name: string
  --opsgenie-configs: list # item shape: {actions?: string, api_key?: string, api_key_file?: string, api_url?: record, description?: string, details?: record, entity?: string, http_config?: record, message?: string, note?: string, priority?: string, responders?: list, send_resolved?: bool, source?: string, tags?: string, update_alerts?: bool}
  --pagerduty-configs: list # item shape: {class?: string, client?: string, client_url?: string, component?: string, description?: string, details?: record, group?: string, http_config?: record, images?: list, links?: list, routing_key?: string, routing_key_file?: string, send_resolved?: bool, service_key?: string, service_key_file?: string, severity?: string, source?: string, timeout?: int, url?: record}
  --pushover-configs: list # item shape: {device?: string, expire?: string, html?: bool, http_config?: record, message?: string, monospace?: bool, priority?: string, retry?: string, send_resolved?: bool, sound?: string, title?: string, token?: string, token_file?: string, ttl?: string, url?: string, url_title?: string, user_key?: string, user_key_file?: string}
  --rocketchat-configs: list # item shape: {actions?: list, api_url?: record, channel?: string, color?: string, emoji?: string, fields?: list, http_config?: record, icon_url?: string, image_url?: string, link_names?: bool, send_resolved?: bool, short_fields?: bool, text?: string, thumb_url?: string, title?: string, title_link?: string, token?: string, token_file?: string, token_id?: string, token_id_file?: string}
  --slack-configs: list # item shape: {actions?: list, api_url?: record, api_url_file?: string, app_token?: string, app_token_file?: string, app_url?: record, callback_id?: string, channel?: string, color?: string, fallback?: string, fields?: list, footer?: string, http_config?: record, icon_emoji?: string, icon_url?: string, image_url?: string, link_names?: bool, message_text?: string, mrkdwn_in?: list, pretext?: string, send_resolved?: bool, short_fields?: bool, text?: string, thumb_url?: string, timeout?: int, title?: string, title_link?: string, username?: string}
  --sns-configs: list # item shape: {api_url?: string, attributes?: record, http_config?: record, message?: string, phone_number?: string, send_resolved?: bool, sigv4?: record, subject?: string, target_arn?: string, topic_arn?: string}
  --telegram-configs: list # item shape: {api_url?: record, chat?: int, chat_file?: string, disable_notifications?: bool, http_config?: record, message?: string, message_thread_id?: int, parse_mode?: string, send_resolved?: bool, token?: string, token_file?: string}
  --victorops-configs: list # item shape: {api_key?: string, api_key_file?: string, api_url?: record, custom_fields?: record, entity_display_name?: string, http_config?: record, message_type?: string, monitoring_tool?: string, routing_key?: string, send_resolved?: bool, state_message?: string}
  --webex-configs: list # item shape: {api_url?: record, http_config?: record, message?: string, room_id?: string, send_resolved?: bool}
  --webhook-configs: list # item shape: {http_config?: record, max_alerts?: int, send_resolved?: bool, timeout?: int, url?: string, url_file?: string}
  --wechat-configs: list # item shape: {agent_id?: string, api_secret?: string, api_secret_file?: string, api_url?: record, corp_id?: string, http_config?: record, message?: string, message_type?: string, send_resolved?: bool, to_party?: string, to_tag?: string, to_user?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/testChannel")
  let body = {discord_configs: $discord_configs, email_configs: $email_configs, googlechat_configs: $googlechat_configs, incidentio_configs: $incidentio_configs, jira_configs: $jira_configs, mattermost_configs: $mattermost_configs, msteams_configs: $msteams_configs, msteamsv2_configs: $msteamsv2_configs, name: $name, opsgenie_configs: $opsgenie_configs, pagerduty_configs: $pagerduty_configs, pushover_configs: $pushover_configs, rocketchat_configs: $rocketchat_configs, slack_configs: $slack_configs, sns_configs: $sns_configs, telegram_configs: $telegram_configs, victorops_configs: $victorops_configs, webex_configs: $webex_configs, webhook_configs: $webhook_configs, wechat_configs: $wechat_configs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get aggregations for a trace
#
# POST /api/v1/traces/{traceID}/aggregations
# operationId: GetTraceAggregations
# --aggregations item shape: {aggregation: "span_count"|"execution_time_percentage"|"duration", field: record}
export def "traces-aggregations GetTraceAggregations" [
  traceID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  aggregations: list # item shape: {aggregation: "span_count"|"execution_time_percentage"|"duration", field: record}
]: any -> record<data: record<aggregations: list<record>>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/traces/($traceID)/aggregations")
  let body = {aggregations: $aggregations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List users
#
# GET /api/v1/user
# operationId: ListUsersDeprecated
export def "user ListUsersDeprecated" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<createdAt: string, displayName: string, email: string, id: string, isRoot: bool, orgId: string, role: string, status: string, updatedAt: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/user")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete user
#
# DELETE /api/v1/user/{id}
# operationId: DeleteUser
export def "user DeleteUser" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/user/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user
#
# GET /api/v1/user/{id}
# operationId: GetUserDeprecated
export def "user GetUserDeprecated" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<createdAt: string, displayName: string, email: string, id: string, isRoot: bool, orgId: string, role: string, status: string, updatedAt: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/user/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update user
#
# PUT /api/v1/user/{id}
# operationId: UpdateUserDeprecated
export def "user UpdateUserDeprecated" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --createdAt: string # format: date-time
  --displayName: string
  --email: string
  --body-id: string
  --isRoot: string@bool-completer
  --orgId: string
  --role: string
  --status: string
  --updatedAt: string # format: date-time
]: any -> record<data: record<createdAt: string, displayName: string, email: string, id: string, isRoot: bool, orgId: string, role: string, status: string, updatedAt: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/user/($id)")
  let body = {createdAt: $createdAt, displayName: $displayName, email: $email, id: $body_id, isRoot: $isRoot, orgId: $orgId, role: $role, status: $status, updatedAt: $updatedAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get my user
#
# GET /api/v1/user/me
# operationId: GetMyUserDeprecated
export def "user-me GetMyUserDeprecated" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<createdAt: string, displayName: string, email: string, id: string, isRoot: bool, orgId: string, role: string, status: string, updatedAt: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/user/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List user preferences
#
# GET /api/v1/user/preferences
# operationId: ListUserPreferences
export def "user-preferences ListUserPreferences" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<allowedScopes: list, allowedValues: list, defaultValue: record, description: string, name: string, value: record, valueType: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/user/preferences")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user preference
#
# GET /api/v1/user/preferences/{name}
# operationId: GetUserPreference
export def "user-preferences GetUserPreference" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<allowedScopes: list<string>, allowedValues: list<string>, defaultValue: record, description: string, name: string, value: record, valueType: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/user/preferences/($name)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update user preference
#
# PUT /api/v1/user/preferences/{name}
# operationId: UpdateUserPreference
export def "user-preferences UpdateUserPreference" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --value: any
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/user/preferences/($name)")
  let body = {value: $value} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List dashboards (v2)
#
# GET /api/v2/dashboards
# operationId: ListDashboardsV2
export def "dashboards ListDashboardsV2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string
  --qp-sort: string
  --order: string
  --limit: int
  --offset: int
]: nothing -> record<data: record<dashboards: list<record>, tags: list<record>, total: int>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/dashboards" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create dashboard (v2)
#
# POST /api/v2/dashboards
# operationId: CreateDashboardV2
# --spec shape: {datasources?: record, display: record, duration?: string, layouts: list, links?: list, panels: record, refreshInterval?: string, variables: list}
# --tags item shape: {key: string, value: string}
export def "dashboards CreateDashboardV2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --generateName: string@bool-completer
  --image: string
  --name: string
  schemaVersion: string
  spec: record # shape: {datasources?: record, display: record, duration?: string, layouts: list, links?: list, panels: record, refreshInterval?: string, variables: list}
  --tags: list # nullable — item shape: {key: string, value: string}
]: any -> record<data: record<createdAt: string, createdBy: string, id: string, image: string, locked: bool, name: string, orgId: string, schemaVersion: string, source: record, spec: record<datasources: record, display: record, duration: string, layouts: list, links: list, panels: record, refreshInterval: string, variables: list>, tags: list<record>, updatedAt: string, updatedBy: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/dashboards")
  let body = {generateName: $generateName, image: $image, name: $name, schemaVersion: $schemaVersion, spec: $spec, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete dashboard (v2)
#
# DELETE /api/v2/dashboards/{id}
# operationId: DeleteDashboardV2
export def "dashboards DeleteDashboardV2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/dashboards/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get dashboard (v2)
#
# GET /api/v2/dashboards/{id}
# operationId: GetDashboardV2
export def "dashboards GetDashboardV2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<createdAt: string, createdBy: string, id: string, image: string, locked: bool, name: string, orgId: string, schemaVersion: string, source: record, spec: record<datasources: record, display: record, duration: string, layouts: list, links: list, panels: record, refreshInterval: string, variables: list>, tags: list<record>, updatedAt: string, updatedBy: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/dashboards/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch dashboard (v2)
#
# PATCH /api/v2/dashboards/{id}
# operationId: PatchDashboardV2
export def "dashboards PatchDashboardV2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> record<data: record<createdAt: string, createdBy: string, id: string, image: string, locked: bool, name: string, orgId: string, schemaVersion: string, source: record, spec: record<datasources: record, display: record, duration: string, layouts: list, links: list, panels: record, refreshInterval: string, variables: list>, tags: list<record>, updatedAt: string, updatedBy: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/dashboards/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update dashboard (v2)
#
# PUT /api/v2/dashboards/{id}
# operationId: UpdateDashboardV2
# --spec shape: {datasources?: record, display: record, duration?: string, layouts: list, links?: list, panels: record, refreshInterval?: string, variables: list}
# --tags item shape: {key: string, value: string}
export def "dashboards UpdateDashboardV2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --image: string
  name: string
  schemaVersion: string
  spec: record # shape: {datasources?: record, display: record, duration?: string, layouts: list, links?: list, panels: record, refreshInterval?: string, variables: list}
  --tags: list # nullable — item shape: {key: string, value: string}
]: any -> record<data: record<createdAt: string, createdBy: string, id: string, image: string, locked: bool, name: string, orgId: string, schemaVersion: string, source: record, spec: record<datasources: record, display: record, duration: string, layouts: list, links: list, panels: record, refreshInterval: string, variables: list>, tags: list<record>, updatedAt: string, updatedBy: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/dashboards/($id)")
  let body = {image: $image, name: $name, schemaVersion: $schemaVersion, spec: $spec, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unlock dashboard (v2)
#
# DELETE /api/v2/dashboards/{id}/lock
# operationId: UnlockDashboardV2
export def "dashboards-lock UnlockDashboardV2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/dashboards/($id)/lock")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lock dashboard (v2)
#
# PUT /api/v2/dashboards/{id}/lock
# operationId: LockDashboardV2
export def "dashboards-lock LockDashboardV2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/dashboards/($id)/lock")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Forgot password
#
# POST /api/v2/factor_password/forgot
# operationId: ForgotPassword
export def "factor-password-forgot ForgotPassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string
  --frontendBaseURL: string
  orgId: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/factor_password/forgot")
  let body = {email: $email, frontendBaseURL: $frontendBaseURL, orgId: $orgId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get features
#
# GET /api/v2/features
# operationId: GetFeatures
export def "features GetFeatures" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<defaultVariant: string, description: string, kind: string, name: string, resolvedValue: any, stage: string, variants: record>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/features")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get ingestion keys for workspace
#
# GET /api/v2/gateway/ingestion_keys
# operationId: GetIngestionKeys
export def "gateway-ingestion-keys GetIngestionKeys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int
  --per-page: int
]: nothing -> record<data: record<_pagination: record<page: int, pages: int, per_page: int, total: int>, keys: list<record>>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/gateway/ingestion_keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create ingestion key for workspace
#
# POST /api/v2/gateway/ingestion_keys
# operationId: CreateIngestionKey
export def "gateway-ingestion-keys CreateIngestionKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expires-at: string # format: date-time
  name: string
  --tags: list # nullable
]: any -> record<data: record<id: string, value: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/gateway/ingestion_keys")
  let body = {expires_at: $expires_at, name: $name, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete ingestion key for workspace
#
# DELETE /api/v2/gateway/ingestion_keys/{keyId}
# operationId: DeleteIngestionKey
export def "gateway-ingestion-keys DeleteIngestionKey" [
  keyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/gateway/ingestion_keys/($keyId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update ingestion key for workspace
#
# PATCH /api/v2/gateway/ingestion_keys/{keyId}
# operationId: UpdateIngestionKey
export def "gateway-ingestion-keys UpdateIngestionKey" [
  keyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --expires-at: string # format: date-time
  name: string
  --tags: list # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/gateway/ingestion_keys/($keyId)")
  let body = {expires_at: $expires_at, name: $name, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create limit for the ingestion key
#
# POST /api/v2/gateway/ingestion_keys/{keyId}/limits
# operationId: CreateIngestionKeyLimit
# --config shape: {day?: record, second?: record}
export def "gateway-ingestion-keys-limits CreateIngestionKeyLimit" [
  keyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --config: record # shape: {day?: record, second?: record}
  --signal: string
  --tags: list # nullable
]: any -> record<data: record<id: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/gateway/ingestion_keys/($keyId)/limits")
  let body = {config: $config, signal: $signal, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete limit for the ingestion key
#
# DELETE /api/v2/gateway/ingestion_keys/limits/{limitId}
# operationId: DeleteIngestionKeyLimit
export def "gateway-ingestion-keys-limits DeleteIngestionKeyLimit" [
  limitId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/gateway/ingestion_keys/limits/($limitId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update limit for the ingestion key
#
# PATCH /api/v2/gateway/ingestion_keys/limits/{limitId}
# operationId: UpdateIngestionKeyLimit
# --config shape: {day?: record, second?: record}
export def "gateway-ingestion-keys-limits UpdateIngestionKeyLimit" [
  limitId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  config: record # shape: {day?: record, second?: record}
  --tags: list # nullable
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/gateway/ingestion_keys/limits/($limitId)")
  let body = {config: $config, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search ingestion keys for workspace
#
# GET /api/v2/gateway/ingestion_keys/search
# operationId: SearchIngestionKeys
export def "gateway-ingestion-keys-search SearchIngestionKeys" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --page: int
  --per-page: int
]: nothing -> record<data: record<_pagination: record<page: int, pages: int, per_page: int, total: int>, keys: list<record>>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "name" $name "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/gateway/ingestion_keys/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Health check
#
# GET /api/v2/healthz
# operationId: Healthz
export def "healthz Healthz" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<healthy: bool, services: record>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/healthz")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Clusters for Infra Monitoring
#
# POST /api/v2/infra_monitoring/clusters
# operationId: ListClusters
# --filter shape: {expression?: string}
# --groupBy item shape: {description?: string, fieldContext?: "metric"|"log"|"span"|"resource"|"attribute"|"body", fieldDataType?: "string"|"bool"|"float64"|"int64"|"number", name: string, signal?: "traces"|"logs"|"metrics", unit?: string}
# --orderBy shape: {direction?: "asc"|"desc", key?: record}
export def "infra-monitoring-clusters ListClusters" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  end: int # format: int64
  --filter: record # shape: {expression?: string}
  --groupBy: list # nullable — item shape: {description?: string, fieldContext?: "metric"|"log"|"span"|"resource"|"attribute"|"body", fieldDataType?: "string"|"bool"|"float64"|"int64"|"number", name: string, signal?: "traces"|"logs"|"metrics", unit?: string}
  limit: int
  --offset: int
  --orderBy: record # shape: {direction?: "asc"|"desc", key?: record}
  start: int # format: int64
]: any -> record<data: record<endTimeBeforeRetention: bool, records: list<record>, requiredMetricsCheck: record<missingMetrics: list>, total: int, type: string, warning: record<message: string, url: string, warnings: list>>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/infra_monitoring/clusters")
  let body = {end: $end, filter: $filter, groupBy: $groupBy, limit: $limit, offset: $offset, orderBy: $orderBy, start: $start} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List DaemonSets for Infra Monitoring
#
# POST /api/v2/infra_monitoring/daemonsets
# operationId: ListDaemonSets
# --filter shape: {expression?: string}
# --groupBy item shape: {description?: string, fieldContext?: "metric"|"log"|"span"|"resource"|"attribute"|"body", fieldDataType?: "string"|"bool"|"float64"|"int64"|"number", name: string, signal?: "traces"|"logs"|"metrics", unit?: string}
# --orderBy shape: {direction?: "asc"|"desc", key?: record}
export def "infra-monitoring-daemonsets ListDaemonSets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  end: int # format: int64
  --filter: record # shape: {expression?: string}
  --groupBy: list # nullable — item shape: {description?: string, fieldContext?: "metric"|"log"|"span"|"resource"|"attribute"|"body", fieldDataType?: "string"|"bool"|"float64"|"int64"|"number", name: string, signal?: "traces"|"logs"|"metrics", unit?: string}
  limit: int
  --offset: int
  --orderBy: record # shape: {direction?: "asc"|"desc", key?: record}
  start: int # format: int64
]: any -> record<data: record<endTimeBeforeRetention: bool, records: list<record>, requiredMetricsCheck: record<missingMetrics: list>, total: int, type: string, warning: record<message: string, url: string, warnings: list>>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/infra_monitoring/daemonsets")
  let body = {end: $end, filter: $filter, groupBy: $groupBy, limit: $limit, offset: $offset, orderBy: $orderBy, start: $start} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Deployments for Infra Monitoring
#
# POST /api/v2/infra_monitoring/deployments
# operationId: ListDeployments
# --filter shape: {expression?: string}
# --groupBy item shape: {description?: string, fieldContext?: "metric"|"log"|"span"|"resource"|"attribute"|"body", fieldDataType?: "string"|"bool"|"float64"|"int64"|"number", name: string, signal?: "traces"|"logs"|"metrics", unit?: string}
# --orderBy shape: {direction?: "asc"|"desc", key?: record}
export def "infra-monitoring-deployments ListDeployments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  end: int # format: int64
  --filter: record # shape: {expression?: string}
  --groupBy: list # nullable — item shape: {description?: string, fieldContext?: "metric"|"log"|"span"|"resource"|"attribute"|"body", fieldDataType?: "string"|"bool"|"float64"|"int64"|"number", name: string, signal?: "traces"|"logs"|"metrics", unit?: string}
  limit: int
  --offset: int
  --orderBy: record # shape: {direction?: "asc"|"desc", key?: record}
  start: int # format: int64
]: any -> record<data: record<endTimeBeforeRetention: bool, records: list<record>, requiredMetricsCheck: record<missingMetrics: list>, total: int, type: string, warning: record<message: string, url: string, warnings: list>>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/infra_monitoring/deployments")
  let body = {end: $end, filter: $filter, groupBy: $groupBy, limit: $limit, offset: $offset, orderBy: $orderBy, start: $start} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Hosts for Infra Monitoring
#
# POST /api/v2/infra_monitoring/hosts
# operationId: ListHosts
# --filter shape: {expression?: string, filterByStatus?: "active"|"inactive"|""}
# --groupBy item shape: {description?: string, fieldContext?: "metric"|"log"|"span"|"resource"|"attribute"|"body", fieldDataType?: "string"|"bool"|"float64"|"int64"|"number", name: string, signal?: "traces"|"logs"|"metrics", unit?: string}
# --orderBy shape: {direction?: "asc"|"desc", key?: record}
export def "infra-monitoring-hosts ListHosts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  end: int # format: int64
  --filter: record # shape: {expression?: string, filterByStatus?: "active"|"inactive"|""}
  --groupBy: list # nullable — item shape: {description?: string, fieldContext?: "metric"|"log"|"span"|"resource"|"attribute"|"body", fieldDataType?: "string"|"bool"|"float64"|"int64"|"number", name: string, signal?: "traces"|"logs"|"metrics", unit?: string}
  limit: int
  --offset: int
  --orderBy: record # shape: {direction?: "asc"|"desc", key?: record}
  start: int # format: int64
]: any -> record<data: record<endTimeBeforeRetention: bool, records: list<record>, requiredMetricsCheck: record<missingMetrics: list>, total: int, type: string, warning: record<message: string, url: string, warnings: list>>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/infra_monitoring/hosts")
  let body = {end: $end, filter: $filter, groupBy: $groupBy, limit: $limit, offset: $offset, orderBy: $orderBy, start: $start} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Jobs for Infra Monitoring
#
# POST /api/v2/infra_monitoring/jobs
# operationId: ListJobs
# --filter shape: {expression?: string}
# --groupBy item shape: {description?: string, fieldContext?: "metric"|"log"|"span"|"resource"|"attribute"|"body", fieldDataType?: "string"|"bool"|"float64"|"int64"|"number", name: string, signal?: "traces"|"logs"|"metrics", unit?: string}
# --orderBy shape: {direction?: "asc"|"desc", key?: record}
export def "infra-monitoring-jobs ListJobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  end: int # format: int64
  --filter: record # shape: {expression?: string}
  --groupBy: list # nullable — item shape: {description?: string, fieldContext?: "metric"|"log"|"span"|"resource"|"attribute"|"body", fieldDataType?: "string"|"bool"|"float64"|"int64"|"number", name: string, signal?: "traces"|"logs"|"metrics", unit?: string}
  limit: int
  --offset: int
  --orderBy: record # shape: {direction?: "asc"|"desc", key?: record}
  start: int # format: int64
]: any -> record<data: record<endTimeBeforeRetention: bool, records: list<record>, requiredMetricsCheck: record<missingMetrics: list>, total: int, type: string, warning: record<message: string, url: string, warnings: list>>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/infra_monitoring/jobs")
  let body = {end: $end, filter: $filter, groupBy: $groupBy, limit: $limit, offset: $offset, orderBy: $orderBy, start: $start} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Namespaces for Infra Monitoring
#
# POST /api/v2/infra_monitoring/namespaces
# operationId: ListNamespaces
# --filter shape: {expression?: string}
# --groupBy item shape: {description?: string, fieldContext?: "metric"|"log"|"span"|"resource"|"attribute"|"body", fieldDataType?: "string"|"bool"|"float64"|"int64"|"number", name: string, signal?: "traces"|"logs"|"metrics", unit?: string}
# --orderBy shape: {direction?: "asc"|"desc", key?: record}
export def "infra-monitoring-namespaces ListNamespaces" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  end: int # format: int64
  --filter: record # shape: {expression?: string}
  --groupBy: list # nullable — item shape: {description?: string, fieldContext?: "metric"|"log"|"span"|"resource"|"attribute"|"body", fieldDataType?: "string"|"bool"|"float64"|"int64"|"number", name: string, signal?: "traces"|"logs"|"metrics", unit?: string}
  limit: int
  --offset: int
  --orderBy: record # shape: {direction?: "asc"|"desc", key?: record}
  start: int # format: int64
]: any -> record<data: record<endTimeBeforeRetention: bool, records: list<record>, requiredMetricsCheck: record<missingMetrics: list>, total: int, type: string, warning: record<message: string, url: string, warnings: list>>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/infra_monitoring/namespaces")
  let body = {end: $end, filter: $filter, groupBy: $groupBy, limit: $limit, offset: $offset, orderBy: $orderBy, start: $start} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Nodes for Infra Monitoring
#
# POST /api/v2/infra_monitoring/nodes
# operationId: ListNodes
# --filter shape: {expression?: string}
# --groupBy item shape: {description?: string, fieldContext?: "metric"|"log"|"span"|"resource"|"attribute"|"body", fieldDataType?: "string"|"bool"|"float64"|"int64"|"number", name: string, signal?: "traces"|"logs"|"metrics", unit?: string}
# --orderBy shape: {direction?: "asc"|"desc", key?: record}
export def "infra-monitoring-nodes ListNodes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  end: int # format: int64
  --filter: record # shape: {expression?: string}
  --groupBy: list # nullable — item shape: {description?: string, fieldContext?: "metric"|"log"|"span"|"resource"|"attribute"|"body", fieldDataType?: "string"|"bool"|"float64"|"int64"|"number", name: string, signal?: "traces"|"logs"|"metrics", unit?: string}
  limit: int
  --offset: int
  --orderBy: record # shape: {direction?: "asc"|"desc", key?: record}
  start: int # format: int64
]: any -> record<data: record<endTimeBeforeRetention: bool, records: list<record>, requiredMetricsCheck: record<missingMetrics: list>, total: int, type: string, warning: record<message: string, url: string, warnings: list>>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/infra_monitoring/nodes")
  let body = {end: $end, filter: $filter, groupBy: $groupBy, limit: $limit, offset: $offset, orderBy: $orderBy, start: $start} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Pods for Infra Monitoring
#
# POST /api/v2/infra_monitoring/pods
# operationId: ListPods
# --filter shape: {expression?: string}
# --groupBy item shape: {description?: string, fieldContext?: "metric"|"log"|"span"|"resource"|"attribute"|"body", fieldDataType?: "string"|"bool"|"float64"|"int64"|"number", name: string, signal?: "traces"|"logs"|"metrics", unit?: string}
# --orderBy shape: {direction?: "asc"|"desc", key?: record}
export def "infra-monitoring-pods ListPods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  end: int # format: int64
  --filter: record # shape: {expression?: string}
  --groupBy: list # nullable — item shape: {description?: string, fieldContext?: "metric"|"log"|"span"|"resource"|"attribute"|"body", fieldDataType?: "string"|"bool"|"float64"|"int64"|"number", name: string, signal?: "traces"|"logs"|"metrics", unit?: string}
  limit: int
  --offset: int
  --orderBy: record # shape: {direction?: "asc"|"desc", key?: record}
  start: int # format: int64
]: any -> record<data: record<endTimeBeforeRetention: bool, records: list<record>, requiredMetricsCheck: record<missingMetrics: list>, total: int, type: string, warning: record<message: string, url: string, warnings: list>>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/infra_monitoring/pods")
  let body = {end: $end, filter: $filter, groupBy: $groupBy, limit: $limit, offset: $offset, orderBy: $orderBy, start: $start} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Volumes for Infra Monitoring
#
# POST /api/v2/infra_monitoring/pvcs
# operationId: ListVolumes
# --filter shape: {expression?: string}
# --groupBy item shape: {description?: string, fieldContext?: "metric"|"log"|"span"|"resource"|"attribute"|"body", fieldDataType?: "string"|"bool"|"float64"|"int64"|"number", name: string, signal?: "traces"|"logs"|"metrics", unit?: string}
# --orderBy shape: {direction?: "asc"|"desc", key?: record}
export def "infra-monitoring-pvcs ListVolumes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  end: int # format: int64
  --filter: record # shape: {expression?: string}
  --groupBy: list # nullable — item shape: {description?: string, fieldContext?: "metric"|"log"|"span"|"resource"|"attribute"|"body", fieldDataType?: "string"|"bool"|"float64"|"int64"|"number", name: string, signal?: "traces"|"logs"|"metrics", unit?: string}
  limit: int
  --offset: int
  --orderBy: record # shape: {direction?: "asc"|"desc", key?: record}
  start: int # format: int64
]: any -> record<data: record<endTimeBeforeRetention: bool, records: list<record>, requiredMetricsCheck: record<missingMetrics: list>, total: int, type: string, warning: record<message: string, url: string, warnings: list>>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/infra_monitoring/pvcs")
  let body = {end: $end, filter: $filter, groupBy: $groupBy, limit: $limit, offset: $offset, orderBy: $orderBy, start: $start} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List StatefulSets for Infra Monitoring
#
# POST /api/v2/infra_monitoring/statefulsets
# operationId: ListStatefulSets
# --filter shape: {expression?: string}
# --groupBy item shape: {description?: string, fieldContext?: "metric"|"log"|"span"|"resource"|"attribute"|"body", fieldDataType?: "string"|"bool"|"float64"|"int64"|"number", name: string, signal?: "traces"|"logs"|"metrics", unit?: string}
# --orderBy shape: {direction?: "asc"|"desc", key?: record}
export def "infra-monitoring-statefulsets ListStatefulSets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  end: int # format: int64
  --filter: record # shape: {expression?: string}
  --groupBy: list # nullable — item shape: {description?: string, fieldContext?: "metric"|"log"|"span"|"resource"|"attribute"|"body", fieldDataType?: "string"|"bool"|"float64"|"int64"|"number", name: string, signal?: "traces"|"logs"|"metrics", unit?: string}
  limit: int
  --offset: int
  --orderBy: record # shape: {direction?: "asc"|"desc", key?: record}
  start: int # format: int64
]: any -> record<data: record<endTimeBeforeRetention: bool, records: list<record>, requiredMetricsCheck: record<missingMetrics: list>, total: int, type: string, warning: record<message: string, url: string, warnings: list>>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/infra_monitoring/statefulsets")
  let body = {end: $end, filter: $filter, groupBy: $groupBy, limit: $limit, offset: $offset, orderBy: $orderBy, start: $start} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Liveness check
#
# GET /api/v2/livez
# operationId: Livez
export def "livez Livez" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<healthy: bool, services: record>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/livez")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List metric names
#
# GET /api/v2/metrics
# operationId: ListMetrics
export def "metrics ListMetrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # nullable
  --end: int # nullable
  --limit: int
  --searchText: string
  --qp-source: string
]: nothing -> record<data: record<metrics: list<record>>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "searchText" $searchText "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/metrics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get metric alerts
#
# GET /api/v2/metrics/{metric_name}/alerts
# operationId: GetMetricAlerts
export def "metrics-alerts GetMetricAlerts" [
  metric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<alerts: list<record>>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/metrics/($metric_name)/alerts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get metric attributes
#
# GET /api/v2/metrics/{metric_name}/attributes
# operationId: GetMetricAttributes
export def "metrics-attributes GetMetricAttributes" [
  metric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # nullable
  --end: int # nullable
]: nothing -> record<data: record<attributes: list<record>, totalKeys: int>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/metrics/($metric_name)/attributes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get metric dashboards
#
# GET /api/v2/metrics/{metric_name}/dashboards
# operationId: GetMetricDashboards
export def "metrics-dashboards GetMetricDashboards" [
  metric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<dashboards: list<record>>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/metrics/($metric_name)/dashboards")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get metric highlights
#
# GET /api/v2/metrics/{metric_name}/highlights
# operationId: GetMetricHighlights
export def "metrics-highlights GetMetricHighlights" [
  metric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<activeTimeSeries: int, dataPoints: int, lastReceived: int, totalTimeSeries: int>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/metrics/($metric_name)/highlights")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get metric metadata
#
# GET /api/v2/metrics/{metric_name}/metadata
# operationId: GetMetricMetadata
export def "metrics-metadata GetMetricMetadata" [
  metric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<description: string, isMonotonic: bool, temporality: string, type: string, unit: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/metrics/($metric_name)/metadata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update metric metadata
#
# POST /api/v2/metrics/{metric_name}/metadata
# operationId: UpdateMetricMetadata
export def "metrics-metadata UpdateMetricMetadata" [
  metric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  description: string
  --isMonotonic: string@bool-completer
  metricName: string
  temporality: string@temporality-completer
  type: string@type-completer
  unit: string
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/metrics/($metric_name)/metadata")
  let body = {description: $description, isMonotonic: $isMonotonic, metricName: $metricName, temporality: $temporality, type: $type, unit: $unit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Inspect raw metric data points
#
# POST /api/v2/metrics/inspect
# operationId: InspectMetrics
# --filter shape: {expression?: string}
export def "metrics-inspect InspectMetrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  end: int # format: int64
  --filter: record # shape: {expression?: string}
  metricName: string
  start: int # format: int64
]: any -> record<data: record<series: list<record>>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/metrics/inspect")
  let body = {end: $end, filter: $filter, metricName: $metricName, start: $start} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Check if non-SigNoz metrics have been received
#
# GET /api/v2/metrics/onboarding
# operationId: GetMetricsOnboardingStatus
export def "metrics-onboarding GetMetricsOnboardingStatus" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<hasMetrics: bool>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/metrics/onboarding")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get metrics statistics
#
# POST /api/v2/metrics/stats
# operationId: GetMetricsStats
# --filter shape: {expression?: string}
# --orderBy shape: {direction?: "asc"|"desc", key?: record}
export def "metrics-stats GetMetricsStats" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  end: int # format: int64
  --filter: record # shape: {expression?: string}
  limit: int
  --offset: int
  --orderBy: record # shape: {direction?: "asc"|"desc", key?: record}
  start: int # format: int64
]: any -> record<data: record<metrics: list<record>, total: int>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/metrics/stats")
  let body = {end: $end, filter: $filter, limit: $limit, offset: $offset, orderBy: $orderBy, start: $start} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get metrics treemap
#
# POST /api/v2/metrics/treemap
# operationId: GetMetricsTreemap
# --filter shape: {expression?: string}
export def "metrics-treemap GetMetricsTreemap" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  end: int # format: int64
  --filter: record # shape: {expression?: string}
  limit: int
  mode: string@mode-completer
  start: int # format: int64
]: any -> record<data: record<samples: list<record>, timeseries: list<record>>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/metrics/treemap")
  let body = {end: $end, filter: $filter, limit: $limit, mode: $mode, start: $start} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get my organization
#
# GET /api/v2/orgs/me
# operationId: GetMyOrganization
export def "orgs-me GetMyOrganization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<alias: string, createdAt: string, displayName: string, id: string, key: int, name: string, updatedAt: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/orgs/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update my organization
#
# PUT /api/v2/orgs/me
# operationId: UpdateMyOrganization
export def "orgs-me UpdateMyOrganization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --alias: string
  --createdAt: string # format: date-time
  --displayName: string
  id: string
  --key: int
  --name: string
  --updatedAt: string # format: date-time
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/orgs/me")
  let body = {alias: $alias, createdAt: $createdAt, displayName: $displayName, id: $id, key: $key, name: $name, updatedAt: $updatedAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Readiness check
#
# GET /api/v2/readyz
# operationId: Readyz
export def "readyz Readyz" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<healthy: bool, services: record>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/readyz")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verify a reset password token
#
# POST /api/v2/reset_password_tokens/verify
# operationId: VerifyResetPasswordToken
export def "reset-password-tokens-verify VerifyResetPasswordToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-token: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/reset_password_tokens/verify")
  let body = {token: $body_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get users by role id
#
# GET /api/v2/roles/{id}/users
# operationId: GetUsersByRoleID
export def "roles-users GetUsersByRoleID" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<createdAt: string, displayName: string, email: string, id: string, isRoot: bool, orgId: string, status: string, updatedAt: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/roles/($id)/users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List alert rules
#
# GET /api/v2/rules
# operationId: ListRules
export def "rules ListRules" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<alert: string, alertType: string, annotations: record, condition: record, createdAt: string, createdBy: string, description: string, disabled: bool, evalWindow: string, evaluation: record, frequency: string, id: string, labels: record, notificationSettings: record, preferredChannels: list, ruleType: string, schemaVersion: string, source: string, state: string, updatedAt: string, updatedBy: string, version: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/rules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create alert rule
#
# POST /api/v2/rules
# operationId: CreateRule
# --condition shape: {absentFor?: int, alertOnAbsent?: bool, algorithm?: string, compositeQuery: record, matchType?: "at_least_once"|"all_the_times"|"on_average"|"in_total"|"last", op?: "above"|"below"|"equal"|"not_equal"|"outside_bounds", requireMinPoints?: bool, requiredNumPoints?: int, seasonality?: "hourly"|"daily"|"weekly", selectedQueryName?: string, target?: float, targetUnit?: string, thresholds?: record}
# --evaluation shape: {kind: "cumulative"|"rolling", spec?: record}
# --notificationSettings shape: {groupBy?: list, newGroupEvalDelay?: string, renotify?: record, usePolicy?: bool}
export def "rules CreateRule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  alert: string
  alertType: string@alertType-completer
  --annotations: record
  condition: record # shape: {absentFor?: int, alertOnAbsent?: bool, algorithm?: string, compositeQuery: record, matchType?: "at_least_once"|"all_the_times"|"on_average"|"in_total"|"last", op?: "above"|"below"|"equal"|"not_equal"|"outside_bounds", requireMinPoints?: bool, requiredNumPoints?: int, seasonality?: "hourly"|"daily"|"weekly", selectedQueryName?: string, target?: float, targetUnit?: string, thresholds?: record}
  --description: string
  --disabled: string@bool-completer
  --evalWindow: string
  --evaluation: record # shape: {kind: "cumulative"|"rolling", spec?: record}
  --frequency: string
  --labels: record
  --notificationSettings: record # shape: {groupBy?: list, newGroupEvalDelay?: string, renotify?: record, usePolicy?: bool}
  --preferredChannels: list
  ruleType: string@ruleType-completer
  --schemaVersion: string
  --body-source: string
  --version: string
]: any -> record<data: record<alert: string, alertType: string, annotations: record, condition: record<absentFor: int, alertOnAbsent: bool, algorithm: string, compositeQuery: record, matchType: string, op: string, requireMinPoints: bool, requiredNumPoints: int, seasonality: string, selectedQueryName: string, target: float, targetUnit: string, thresholds: record>, createdAt: string, createdBy: string, description: string, disabled: bool, evalWindow: string, evaluation: record, frequency: string, id: string, labels: record, notificationSettings: record<groupBy: list, newGroupEvalDelay: string, renotify: record, usePolicy: bool>, preferredChannels: list<string>, ruleType: string, schemaVersion: string, source: string, state: string, updatedAt: string, updatedBy: string, version: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/rules")
  let body = {alert: $alert, alertType: $alertType, annotations: $annotations, condition: $condition, description: $description, disabled: $disabled, evalWindow: $evalWindow, evaluation: $evaluation, frequency: $frequency, labels: $labels, notificationSettings: $notificationSettings, preferredChannels: $preferredChannels, ruleType: $ruleType, schemaVersion: $schemaVersion, source: $body_source, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete alert rule
#
# DELETE /api/v2/rules/{id}
# operationId: DeleteRuleByID
export def "rules DeleteRuleByID" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/rules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get alert rule by ID
#
# GET /api/v2/rules/{id}
# operationId: GetRuleByID
export def "rules GetRuleByID" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<alert: string, alertType: string, annotations: record, condition: record<absentFor: int, alertOnAbsent: bool, algorithm: string, compositeQuery: record, matchType: string, op: string, requireMinPoints: bool, requiredNumPoints: int, seasonality: string, selectedQueryName: string, target: float, targetUnit: string, thresholds: record>, createdAt: string, createdBy: string, description: string, disabled: bool, evalWindow: string, evaluation: record, frequency: string, id: string, labels: record, notificationSettings: record<groupBy: list, newGroupEvalDelay: string, renotify: record, usePolicy: bool>, preferredChannels: list<string>, ruleType: string, schemaVersion: string, source: string, state: string, updatedAt: string, updatedBy: string, version: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/rules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Patch alert rule
#
# PATCH /api/v2/rules/{id}
# operationId: PatchRuleByID
# --condition shape: {absentFor?: int, alertOnAbsent?: bool, algorithm?: string, compositeQuery: record, matchType?: "at_least_once"|"all_the_times"|"on_average"|"in_total"|"last", op?: "above"|"below"|"equal"|"not_equal"|"outside_bounds", requireMinPoints?: bool, requiredNumPoints?: int, seasonality?: "hourly"|"daily"|"weekly", selectedQueryName?: string, target?: float, targetUnit?: string, thresholds?: record}
# --evaluation shape: {kind: "cumulative"|"rolling", spec?: record}
# --notificationSettings shape: {groupBy?: list, newGroupEvalDelay?: string, renotify?: record, usePolicy?: bool}
export def "rules PatchRuleByID" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  alert: string
  alertType: string@alertType-completer
  --annotations: record
  condition: record # shape: {absentFor?: int, alertOnAbsent?: bool, algorithm?: string, compositeQuery: record, matchType?: "at_least_once"|"all_the_times"|"on_average"|"in_total"|"last", op?: "above"|"below"|"equal"|"not_equal"|"outside_bounds", requireMinPoints?: bool, requiredNumPoints?: int, seasonality?: "hourly"|"daily"|"weekly", selectedQueryName?: string, target?: float, targetUnit?: string, thresholds?: record}
  --description: string
  --disabled: string@bool-completer
  --evalWindow: string
  --evaluation: record # shape: {kind: "cumulative"|"rolling", spec?: record}
  --frequency: string
  --labels: record
  --notificationSettings: record # shape: {groupBy?: list, newGroupEvalDelay?: string, renotify?: record, usePolicy?: bool}
  --preferredChannels: list
  ruleType: string@ruleType-completer
  --schemaVersion: string
  --body-source: string
  --version: string
]: any -> record<data: record<alert: string, alertType: string, annotations: record, condition: record<absentFor: int, alertOnAbsent: bool, algorithm: string, compositeQuery: record, matchType: string, op: string, requireMinPoints: bool, requiredNumPoints: int, seasonality: string, selectedQueryName: string, target: float, targetUnit: string, thresholds: record>, createdAt: string, createdBy: string, description: string, disabled: bool, evalWindow: string, evaluation: record, frequency: string, id: string, labels: record, notificationSettings: record<groupBy: list, newGroupEvalDelay: string, renotify: record, usePolicy: bool>, preferredChannels: list<string>, ruleType: string, schemaVersion: string, source: string, state: string, updatedAt: string, updatedBy: string, version: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/rules/($id)")
  let body = {alert: $alert, alertType: $alertType, annotations: $annotations, condition: $condition, description: $description, disabled: $disabled, evalWindow: $evalWindow, evaluation: $evaluation, frequency: $frequency, labels: $labels, notificationSettings: $notificationSettings, preferredChannels: $preferredChannels, ruleType: $ruleType, schemaVersion: $schemaVersion, source: $body_source, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update alert rule
#
# PUT /api/v2/rules/{id}
# operationId: UpdateRuleByID
# --condition shape: {absentFor?: int, alertOnAbsent?: bool, algorithm?: string, compositeQuery: record, matchType?: "at_least_once"|"all_the_times"|"on_average"|"in_total"|"last", op?: "above"|"below"|"equal"|"not_equal"|"outside_bounds", requireMinPoints?: bool, requiredNumPoints?: int, seasonality?: "hourly"|"daily"|"weekly", selectedQueryName?: string, target?: float, targetUnit?: string, thresholds?: record}
# --evaluation shape: {kind: "cumulative"|"rolling", spec?: record}
# --notificationSettings shape: {groupBy?: list, newGroupEvalDelay?: string, renotify?: record, usePolicy?: bool}
export def "rules UpdateRuleByID" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  alert: string
  alertType: string@alertType-completer
  --annotations: record
  condition: record # shape: {absentFor?: int, alertOnAbsent?: bool, algorithm?: string, compositeQuery: record, matchType?: "at_least_once"|"all_the_times"|"on_average"|"in_total"|"last", op?: "above"|"below"|"equal"|"not_equal"|"outside_bounds", requireMinPoints?: bool, requiredNumPoints?: int, seasonality?: "hourly"|"daily"|"weekly", selectedQueryName?: string, target?: float, targetUnit?: string, thresholds?: record}
  --description: string
  --disabled: string@bool-completer
  --evalWindow: string
  --evaluation: record # shape: {kind: "cumulative"|"rolling", spec?: record}
  --frequency: string
  --labels: record
  --notificationSettings: record # shape: {groupBy?: list, newGroupEvalDelay?: string, renotify?: record, usePolicy?: bool}
  --preferredChannels: list
  ruleType: string@ruleType-completer
  --schemaVersion: string
  --body-source: string
  --version: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/rules/($id)")
  let body = {alert: $alert, alertType: $alertType, annotations: $annotations, condition: $condition, description: $description, disabled: $disabled, evalWindow: $evalWindow, evaluation: $evaluation, frequency: $frequency, labels: $labels, notificationSettings: $notificationSettings, preferredChannels: $preferredChannels, ruleType: $ruleType, schemaVersion: $schemaVersion, source: $body_source, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get rule history filter keys
#
# GET /api/v2/rules/{id}/history/filter_keys
# operationId: GetRuleHistoryFilterKeys
export def "rules-history-filter-keys GetRuleHistoryFilterKeys" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --signal: string
  --qp-source: string
  --limit: int
  --startUnixMilli: int # format: int64
  --endUnixMilli: int # format: int64
  --fieldContext: string
  --fieldDataType: string
  --metricName: string
  --metricNamespace: string
  --searchText: string
]: nothing -> record<data: record<complete: bool, keys: record>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "signal" $signal "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "startUnixMilli" $startUnixMilli "scalar") (serialize-qp "endUnixMilli" $endUnixMilli "scalar") (serialize-qp "fieldContext" $fieldContext "scalar") (serialize-qp "fieldDataType" $fieldDataType "scalar") (serialize-qp "metricName" $metricName "scalar") (serialize-qp "metricNamespace" $metricNamespace "scalar") (serialize-qp "searchText" $searchText "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/rules/($id)/history/filter_keys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get rule history filter values
#
# GET /api/v2/rules/{id}/history/filter_values
# operationId: GetRuleHistoryFilterValues
export def "rules-history-filter-values GetRuleHistoryFilterValues" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --signal: string
  --qp-source: string
  --limit: int
  --startUnixMilli: int # format: int64
  --endUnixMilli: int # format: int64
  --fieldContext: string
  --fieldDataType: string
  --metricName: string
  --metricNamespace: string
  --searchText: string
  --name: string
  --existingQuery: string
]: nothing -> record<data: record<complete: bool, values: record<boolValues: list, numberValues: list, relatedValues: list, stringValues: list>>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "signal" $signal "scalar") (serialize-qp "source" $qp_source "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "startUnixMilli" $startUnixMilli "scalar") (serialize-qp "endUnixMilli" $endUnixMilli "scalar") (serialize-qp "fieldContext" $fieldContext "scalar") (serialize-qp "fieldDataType" $fieldDataType "scalar") (serialize-qp "metricName" $metricName "scalar") (serialize-qp "metricNamespace" $metricNamespace "scalar") (serialize-qp "searchText" $searchText "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "existingQuery" $existingQuery "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/rules/($id)/history/filter_values" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get rule overall status timeline
#
# GET /api/v2/rules/{id}/history/overall_status
# operationId: GetRuleHistoryOverallStatus
export def "rules-history-overall-status GetRuleHistoryOverallStatus" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # format: int64
  --end: int # format: int64
]: nothing -> record<data: table<end: int, start: int, state: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/rules/($id)/history/overall_status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get rule history stats
#
# GET /api/v2/rules/{id}/history/stats
# operationId: GetRuleHistoryStats
export def "rules-history-stats GetRuleHistoryStats" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # format: int64
  --end: int # format: int64
]: nothing -> record<data: record<currentAvgResolutionTime: float, currentAvgResolutionTimeSeries: record<labels: list, values: list>, currentTriggersSeries: record<labels: list, values: list>, pastAvgResolutionTime: float, pastAvgResolutionTimeSeries: record<labels: list, values: list>, pastTriggersSeries: record<labels: list, values: list>, totalCurrentTriggers: int, totalPastTriggers: int>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/rules/($id)/history/stats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get rule history timeline
#
# GET /api/v2/rules/{id}/history/timeline
# operationId: GetRuleHistoryTimeline
export def "rules-history-timeline GetRuleHistoryTimeline" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # format: int64
  --end: int # format: int64
  --state: string
  --filterExpression: string
  --limit: int # format: int64
  --order: string
  --cursor: string
]: nothing -> record<data: record<items: list<record>, nextCursor: string, total: int>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar") (serialize-qp "state" $state "scalar") (serialize-qp "filterExpression" $filterExpression "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "cursor" $cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/rules/($id)/history/timeline" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get top contributors to rule firing
#
# GET /api/v2/rules/{id}/history/top_contributors
# operationId: GetRuleHistoryTopContributors
export def "rules-history-top-contributors GetRuleHistoryTopContributors" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start: int # format: int64
  --end: int # format: int64
]: nothing -> record<data: table<count: int, fingerprint: int, labels: list, relatedLogsLink: string, relatedTracesLink: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start" $start "scalar") (serialize-qp "end" $end "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/rules/($id)/history/top_contributors" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Test alert rule
#
# POST /api/v2/rules/test
# operationId: TestRule
# --condition shape: {absentFor?: int, alertOnAbsent?: bool, algorithm?: string, compositeQuery: record, matchType?: "at_least_once"|"all_the_times"|"on_average"|"in_total"|"last", op?: "above"|"below"|"equal"|"not_equal"|"outside_bounds", requireMinPoints?: bool, requiredNumPoints?: int, seasonality?: "hourly"|"daily"|"weekly", selectedQueryName?: string, target?: float, targetUnit?: string, thresholds?: record}
# --evaluation shape: {kind: "cumulative"|"rolling", spec?: record}
# --notificationSettings shape: {groupBy?: list, newGroupEvalDelay?: string, renotify?: record, usePolicy?: bool}
export def "rules-test TestRule" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  alert: string
  alertType: string@alertType-completer
  --annotations: record
  condition: record # shape: {absentFor?: int, alertOnAbsent?: bool, algorithm?: string, compositeQuery: record, matchType?: "at_least_once"|"all_the_times"|"on_average"|"in_total"|"last", op?: "above"|"below"|"equal"|"not_equal"|"outside_bounds", requireMinPoints?: bool, requiredNumPoints?: int, seasonality?: "hourly"|"daily"|"weekly", selectedQueryName?: string, target?: float, targetUnit?: string, thresholds?: record}
  --description: string
  --disabled: string@bool-completer
  --evalWindow: string
  --evaluation: record # shape: {kind: "cumulative"|"rolling", spec?: record}
  --frequency: string
  --labels: record
  --notificationSettings: record # shape: {groupBy?: list, newGroupEvalDelay?: string, renotify?: record, usePolicy?: bool}
  --preferredChannels: list
  ruleType: string@ruleType-completer
  --schemaVersion: string
  --body-source: string
  --version: string
]: any -> record<data: record<alertCount: int, message: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/rules/test")
  let body = {alert: $alert, alertType: $alertType, annotations: $annotations, condition: $condition, description: $description, disabled: $disabled, evalWindow: $evalWindow, evaluation: $evaluation, frequency: $frequency, labels: $labels, notificationSettings: $notificationSettings, preferredChannels: $preferredChannels, ruleType: $ruleType, schemaVersion: $schemaVersion, source: $body_source, version: $version} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete session
#
# DELETE /api/v2/sessions
# operationId: DeleteSession
export def "sessions DeleteSession" [
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
  let full_url = (build-url $base "/api/v2/sessions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get session context
#
# GET /api/v2/sessions/context
# operationId: GetSessionContext
export def "sessions-context GetSessionContext" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<exists: bool, orgs: list<record>>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/sessions/context")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create session by email and password
#
# POST /api/v2/sessions/email_password
# operationId: CreateSessionByEmailPassword
export def "sessions-email-password CreateSessionByEmailPassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string
  --orgId: string
  --password: string
]: any -> record<data: record<accessToken: string, expiresIn: int, refreshToken: string, tokenType: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/sessions/email_password")
  let body = {email: $email, orgId: $orgId, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Rotate session
#
# POST /api/v2/sessions/rotate
# operationId: RotateSession
export def "sessions-rotate RotateSession" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --refreshToken: string
]: any -> record<data: record<accessToken: string, expiresIn: int, refreshToken: string, tokenType: string>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/sessions/rotate")
  let body = {refreshToken: $refreshToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List users v2
#
# GET /api/v2/users
# operationId: ListUsers
export def "users ListUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<createdAt: string, displayName: string, email: string, id: string, isRoot: bool, orgId: string, status: string, updatedAt: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user by user id
#
# GET /api/v2/users/{id}
# operationId: GetUser
export def "users GetUser" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<createdAt: string, displayName: string, email: string, id: string, isRoot: bool, orgId: string, status: string, updatedAt: string, userRoles: list<record>>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update user v2
#
# PUT /api/v2/users/{id}
# operationId: UpdateUser
export def "users UpdateUser" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  displayName: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($id)")
  let body = {displayName: $displayName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get reset password token for a user
#
# GET /api/v2/users/{id}/reset_password_tokens
# operationId: GetResetPasswordToken
export def "users-reset-password-tokens GetResetPasswordToken" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<expiresAt: string, id: string, passwordId: string, token: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($id)/reset_password_tokens")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create or regenerate reset password token for a user
#
# PUT /api/v2/users/{id}/reset_password_tokens
# operationId: CreateResetPasswordToken
export def "users-reset-password-tokens CreateResetPasswordToken" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<expiresAt: string, id: string, passwordId: string, token: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($id)/reset_password_tokens")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get user roles
#
# GET /api/v2/users/{id}/roles
# operationId: GetRolesByUserID
export def "users-roles GetRolesByUserID" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<createdAt: string, description: string, id: string, name: string, orgId: string, type: string, updatedAt: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($id)/roles")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Set user roles
#
# POST /api/v2/users/{id}/roles
# operationId: SetRoleByUserID
export def "users-roles SetRoleByUserID" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($id)/roles")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a role from user
#
# DELETE /api/v2/users/{id}/roles/{roleId}
# operationId: RemoveUserRoleByUserIDAndRoleID
export def "users-roles RemoveUserRoleByUserIDAndRoleID" [
  id: string
  roleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/($id)/roles/($roleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get my user v2
#
# GET /api/v2/users/me
# operationId: GetMyUser
export def "users-me GetMyUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<createdAt: string, displayName: string, email: string, id: string, isRoot: bool, orgId: string, status: string, updatedAt: string, userRoles: list<record>>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/users/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update my user v2
#
# PUT /api/v2/users/me
# operationId: UpdateMyUserV2
export def "users-me UpdateMyUserV2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  displayName: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/users/me")
  let body = {displayName: $displayName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List dashboards for the current user (v2)
#
# GET /api/v2/users/me/dashboards
# operationId: ListDashboardsForUserV2
export def "users-me-dashboards ListDashboardsForUserV2" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-query: string
  --qp-sort: string
  --order: string
  --limit: int
  --offset: int
]: nothing -> record<data: record<dashboards: list<record>, tags: list<record>, total: int>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "order" $order "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/v2/users/me/dashboards" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unpin a dashboard for the current user (v2)
#
# DELETE /api/v2/users/me/dashboards/{id}/pins
# operationId: UnpinDashboardV2
export def "users-me-dashboards-pins UnpinDashboardV2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/me/dashboards/($id)/pins")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Pin a dashboard for the current user (v2)
#
# PUT /api/v2/users/me/dashboards/{id}/pins
# operationId: PinDashboardV2
export def "users-me-dashboards-pins PinDashboardV2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v2/users/me/dashboards/($id)/pins")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Updates my password
#
# PUT /api/v2/users/me/factor_password
# operationId: UpdateMyPassword
export def "users-me-factor-password UpdateMyPassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --newPassword: string
  --oldPassword: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/users/me/factor_password")
  let body = {newPassword: $newPassword, oldPassword: $oldPassword} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get host info from Zeus.
#
# GET /api/v2/zeus/hosts
# operationId: GetHosts
export def "zeus-hosts GetHosts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<hosts: list<record>, name: string, state: string, tier: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/zeus/hosts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Put host in Zeus for a deployment.
#
# PUT /api/v2/zeus/hosts
# operationId: PutHost
export def "zeus-hosts PutHost" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/zeus/hosts")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Put profile in Zeus for a deployment.
#
# PUT /api/v2/zeus/profiles
# operationId: PutProfile
export def "zeus-profiles PutProfile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  existing_observability_tool: string
  --has-existing-observability-tool: string@bool-completer
  logs_scale_per_day_in_gb: int # format: int64
  number_of_hosts: int # format: int64
  number_of_services: int # format: int64
  --reasons-for-interest-in-signoz: list # nullable
  timeline_for_migrating_to_signoz: string
  --uses-otel: string@bool-completer
  where_did_you_discover_signoz: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v2/zeus/profiles")
  let body = {existing_observability_tool: $existing_observability_tool, has_existing_observability_tool: $has_existing_observability_tool, logs_scale_per_day_in_gb: $logs_scale_per_day_in_gb, number_of_hosts: $number_of_hosts, number_of_services: $number_of_services, reasons_for_interest_in_signoz: $reasons_for_interest_in_signoz, timeline_for_migrating_to_signoz: $timeline_for_migrating_to_signoz, uses_otel: $uses_otel, where_did_you_discover_signoz: $where_did_you_discover_signoz} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get flamegraph view for a trace
#
# POST /api/v3/traces/{traceID}/flamegraph
# operationId: GetFlamegraph
# --selectFields item shape: {description?: string, fieldContext?: "metric"|"log"|"span"|"resource"|"attribute"|"body", fieldDataType?: "string"|"bool"|"float64"|"int64"|"number", name: string, signal?: "traces"|"logs"|"metrics", unit?: string}
export def "traces-flamegraph GetFlamegraph" [
  traceID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --selectFields: list # item shape: {description?: string, fieldContext?: "metric"|"log"|"span"|"resource"|"attribute"|"body", fieldDataType?: "string"|"bool"|"float64"|"int64"|"number", name: string, signal?: "traces"|"logs"|"metrics", unit?: string}
  --selectedSpanId: string
]: any -> record<data: record<endTimestampMillis: int, hasMore: bool, spans: list<list>, startTimestampMillis: int>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v3/traces/($traceID)/flamegraph")
  let body = {selectFields: $selectFields, selectedSpanId: $selectedSpanId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get waterfall view for a trace
#
# POST /api/v4/traces/{traceID}/waterfall
# operationId: GetWaterfallV4
export def "traces-waterfall GetWaterfallV4" [
  traceID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --selectedSpanId: string
  --uncollapsedSpans: list # nullable
]: any -> record<data: record<endTimestampMillis: int, hasMissingSpans: bool, hasMore: bool, rootServiceEntryPoint: string, rootServiceName: string, spans: list<record>, startTimestampMillis: int, totalErrorSpansCount: int, totalSpansCount: int, uncollapsedSpans: list<string>>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v4/traces/($traceID)/waterfall")
  let body = {selectedSpanId: $selectedSpanId, uncollapsedSpans: $uncollapsedSpans} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Query range
#
# POST /api/v5/query_range
# operationId: QueryRangeV5
# --compositeQuery shape: {queries?: list}
# --formatOptions shape: {fillGaps?: bool, formatTableResultForUI?: bool}
export def "query-range QueryRangeV5" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --compositeQuery: record # Composite query containing one or more query envelopes. Each query envelope specifies its type and corresponding spec. — shape: {queries?: list}
  --end: int
  --formatOptions: record # shape: {fillGaps?: bool, formatTableResultForUI?: bool}
  --noCache: string@bool-completer
  --requestType: string@requestType-completer
  --schemaVersion: string
  --start: int
  --body-variables: record
]: any -> record<data: record<data: record<results: list>, meta: record<bytesScanned: int, durationMs: int, rowsScanned: int, stepIntervals: record>, type: string, warning: record<message: string, url: string, warnings: list>>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v5/query_range")
  let body = {compositeQuery: $compositeQuery, end: $end, formatOptions: $formatOptions, noCache: $noCache, requestType: $requestType, schemaVersion: $schemaVersion, start: $start, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Replace variables
#
# POST /api/v5/substitute_vars
# operationId: ReplaceVariables
# --compositeQuery shape: {queries?: list}
# --formatOptions shape: {fillGaps?: bool, formatTableResultForUI?: bool}
export def "substitute-vars ReplaceVariables" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --compositeQuery: record # Composite query containing one or more query envelopes. Each query envelope specifies its type and corresponding spec. — shape: {queries?: list}
  --end: int
  --formatOptions: record # shape: {fillGaps?: bool, formatTableResultForUI?: bool}
  --noCache: string@bool-completer
  --requestType: string@requestType-completer
  --schemaVersion: string
  --start: int
  --body-variables: record
]: any -> record<data: record<compositeQuery: record<queries: list>, end: int, formatOptions: record<fillGaps: bool, formatTableResultForUI: bool>, noCache: bool, requestType: string, schemaVersion: string, start: int, variables: record>, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "signoz-api-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v5/substitute_vars")
  let body = {compositeQuery: $compositeQuery, end: $end, formatOptions: $formatOptions, noCache: $noCache, requestType: $requestType, schemaVersion: $schemaVersion, start: $start, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
