# Auto-generated client for Chatwoot v1.1.0
# Source: https://raw.githubusercontent.com/chatwoot/chatwoot/develop/swagger/swagger.json
# Auth: --token flag or $env.CHATWOOT_TOKEN

const BASE_URL = "https://app.chatwoot.com"
const DEFAULT_AUTH = "api_access_token"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CHATWOOT_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "api_access_token" => { {headers: {api_access_token: $token_val}, query: ""} }
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
def base-url-completer [] { ["https://app.chatwoot.com"] }
def auth-scheme-completer [] { ["api_access_token"] }

# Completers for enum parameters
def status-completer [] { ["active" "suspended"] }
def typing-status-completer [] { ["off" "on"] }
def role-completer [] { ["administrator" "agent"] }
def availability-completer [] { ["busy" "offline" "online"] }
def attribute-model-completer [] { ["0" "1"] }
def sort-completer [] { ["-email" "-last_activity_at" "-name" "-phone_number" "email" "last_activity_at" "name" "phone_number"] }
def event-name-completer [] { ["conversation_created" "conversation_resolved" "conversation_updated" "message_created"] }
def status-completer-1 [] { ["all" "open" "pending" "resolved" "snoozed"] }
def assignee-type-completer [] { ["all" "assigned" "me" "unassigned"] }
def status-completer-2 [] { ["open" "pending" "resolved"] }
def priority-completer [] { ["high" "low" "medium" "none" "urgent"] }
def status-completer-3 [] { ["open" "pending" "resolved" "snoozed"] }
def sender-name-type-completer [] { ["friendly" "professional"] }
def message-type-completer [] { ["incoming" "outgoing"] }
def content-type-completer [] { ["article" "cards" "form" "input_email" "input_select" "text"] }
def filter-type-completer [] { ["contact" "conversation" "report"] }
def type-completer [] { ["contact" "conversation" "report"] }
def metric-completer [] { ["avg_first_response_time" "avg_resolution_time" "conversations_count" "incoming_messages_count" "outgoing_messages_count" "resolutions_count"] }
def type-completer-1 [] { ["account" "agent" "inbox" "label" "team"] }
def type-completer-2 [] { ["account"] }
def type-completer-3 [] { ["agent"] }
def group-by-completer [] { ["agent" "inbox" "label" "team"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "platform-accounts create-an-account" } } | get name | first)
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

# Create an Account
#
# POST /platform/api/v1/accounts
# operationId: create-an-account
export def "platform-accounts create-an-account" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of the account (e.g. My Account)
  --locale: string # The locale of the account (e.g. en)
  --domain: string # The domain of the account (e.g. example.com)
  --support-email: string # The support email of the account (e.g. support@example.com)
  --status: string@status-completer # The status of the account (e.g. active)
  --limits: record # The limits of the account (e.g. {})
  --custom-attributes: record # The custom attributes of the account (e.g. {})
]: any -> record<id: float, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/platform/api/v1/accounts")
  let body = {name: $name, locale: $locale, domain: $domain, support_email: $support_email, status: $status, limits: $limits, custom_attributes: $custom_attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an account details
#
# GET /platform/api/v1/accounts/{account_id}
# operationId: get-details-of-an-account
export def "platform-accounts get-details-of-an-account" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: float, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/platform/api/v1/accounts/($account_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an account
#
# PATCH /platform/api/v1/accounts/{account_id}
# operationId: update-an-account
export def "platform-accounts update-an-account" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of the account (e.g. My Account)
  --locale: string # The locale of the account (e.g. en)
  --domain: string # The domain of the account (e.g. example.com)
  --support-email: string # The support email of the account (e.g. support@example.com)
  --status: string@status-completer # The status of the account (e.g. active)
  --limits: record # The limits of the account (e.g. {})
  --custom-attributes: record # The custom attributes of the account (e.g. {})
]: any -> record<id: float, name: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/platform/api/v1/accounts/($account_id)")
  let body = {name: $name, locale: $locale, domain: $domain, support_email: $support_email, status: $status, limits: $limits, custom_attributes: $custom_attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an Account
#
# DELETE /platform/api/v1/accounts/{account_id}
# operationId: delete-an-account
export def "platform-accounts delete-an-account" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/platform/api/v1/accounts/($account_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all Account Users
#
# GET /platform/api/v1/accounts/{account_id}/account_users
# operationId: list-all-account-users
export def "platform-accounts-account-users list-all-account-users" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<account_id: int, user_id: int, role: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/platform/api/v1/accounts/($account_id)/account_users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Account User
#
# POST /platform/api/v1/accounts/{account_id}/account_users
# operationId: create-an-account-user
export def "platform-accounts-account-users create-an-account-user" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user_id: int # The ID of the user (e.g. 1)
  role: string # whether user is an administrator or agent (e.g. administrator)
]: any -> record<account_id: int, user_id: int, role: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/platform/api/v1/accounts/($account_id)/account_users")
  let body = {user_id: $user_id, role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an Account User
#
# DELETE /platform/api/v1/accounts/{account_id}/account_users
# operationId: delete-an-account-user
export def "platform-accounts-account-users delete-an-account-user" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/platform/api/v1/accounts/($account_id)/account_users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all AgentBots
#
# GET /platform/api/v1/agent_bots
# operationId: list-all-agent-bots
export def "platform-agent-bots list-all-agent-bots" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: float, name: string, description: string, thumbnail: string, outgoing_url: string, bot_type: string, bot_config: record, account_id: float, access_token: string, system_bot: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/platform/api/v1/agent_bots")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Agent Bot
#
# POST /platform/api/v1/agent_bots
# operationId: create-an-agent-bot
export def "platform-agent-bots create-an-agent-bot" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the agent bot (e.g. My Agent Bot)
  --description: string # The description of the agent bot (e.g. This is a sample agent bot)
  --outgoing-url: string # The webhook URL for the bot (e.g. https://example.com/webhook)
  --account-id: int # The account ID to associate the agent bot with (e.g. 1)
  --avatar: string # Send the form data with the avatar image binary or use the avatar_url (format: binary)
  --avatar-url: string # The url to a jpeg, png file for the agent bot avatar (e.g. https://example.com/avatar.png)
]: any -> record<id: float, name: string, description: string, thumbnail: string, outgoing_url: string, bot_type: string, bot_config: record, account_id: float, access_token: string, system_bot: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/platform/api/v1/agent_bots")
  let body = {name: $name, description: $description, outgoing_url: $outgoing_url, account_id: $account_id, avatar: $avatar, avatar_url: $avatar_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an agent bot details
#
# GET /platform/api/v1/agent_bots/{id}
# operationId: get-details-of-a-single-agent-bot
export def "platform-agent-bots get-details-of-a-single-agent-bot" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: float, name: string, description: string, thumbnail: string, outgoing_url: string, bot_type: string, bot_config: record, account_id: float, access_token: string, system_bot: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/platform/api/v1/agent_bots/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an agent bot
#
# PATCH /platform/api/v1/agent_bots/{id}
# operationId: update-an-agent-bot
export def "platform-agent-bots update-an-agent-bot" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the agent bot (e.g. My Agent Bot)
  --description: string # The description of the agent bot (e.g. This is a sample agent bot)
  --outgoing-url: string # The webhook URL for the bot (e.g. https://example.com/webhook)
  --account-id: int # The account ID to associate the agent bot with (e.g. 1)
  --avatar: string # Send the form data with the avatar image binary or use the avatar_url (format: binary)
  --avatar-url: string # The url to a jpeg, png file for the agent bot avatar (e.g. https://example.com/avatar.png)
]: any -> record<id: float, name: string, description: string, thumbnail: string, outgoing_url: string, bot_type: string, bot_config: record, account_id: float, access_token: string, system_bot: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/platform/api/v1/agent_bots/($id)")
  let body = {name: $name, description: $description, outgoing_url: $outgoing_url, account_id: $account_id, avatar: $avatar, avatar_url: $avatar_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an AgentBot
#
# DELETE /platform/api/v1/agent_bots/{id}
# operationId: delete-an-agent-bot
export def "platform-agent-bots delete-an-agent-bot" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/platform/api/v1/agent_bots/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a User
#
# POST /platform/api/v1/users
# operationId: create-a-user
export def "platform-users create-a-user" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of the user (e.g. Daniel)
  --display-name: string # Display name of the user (e.g. Dan)
  --email: string # Email of the user (e.g. daniel@acme.inc)
  --password: string # Password must contain uppercase, lowercase letters, number and a special character (e.g. Password2!)
  --custom-attributes: record # Custom attributes you want to associate with the user (e.g. {})
]: any -> record<id: float, access_token: string, account_id: float, available_name: string, avatar_url: string, confirmed: bool, display_name: string, message_signature: string, email: string, hmac_identifier: string, inviter_id: float, name: string, provider: string, pubsub_token: string, role: string, ui_settings: record, uid: string, type: string, custom_attributes: record, accounts: table<id: float, name: string, status: string, active_at: string, role: string, permissions: list, availability: string, availability_status: string, auto_offline: bool, custom_role_id: float, custom_role: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/platform/api/v1/users")
  let body = {name: $name, display_name: $display_name, email: $email, password: $password, custom_attributes: $custom_attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an user details
#
# GET /platform/api/v1/users/{id}
# operationId: get-details-of-a-user
export def "platform-users get-details-of-a-user" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: float, access_token: string, account_id: float, available_name: string, avatar_url: string, confirmed: bool, display_name: string, message_signature: string, email: string, hmac_identifier: string, inviter_id: float, name: string, provider: string, pubsub_token: string, role: string, ui_settings: record, uid: string, type: string, custom_attributes: record, accounts: table<id: float, name: string, status: string, active_at: string, role: string, permissions: list, availability: string, availability_status: string, auto_offline: bool, custom_role_id: float, custom_role: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/platform/api/v1/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a user
#
# PATCH /platform/api/v1/users/{id}
# operationId: update-a-user
export def "platform-users update-a-user" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of the user (e.g. Daniel)
  --display-name: string # Display name of the user (e.g. Dan)
  --email: string # Email of the user (e.g. daniel@acme.inc)
  --password: string # Password must contain uppercase, lowercase letters, number and a special character (e.g. Password2!)
  --custom-attributes: record # Custom attributes you want to associate with the user (e.g. {})
]: any -> record<id: float, access_token: string, account_id: float, available_name: string, avatar_url: string, confirmed: bool, display_name: string, message_signature: string, email: string, hmac_identifier: string, inviter_id: float, name: string, provider: string, pubsub_token: string, role: string, ui_settings: record, uid: string, type: string, custom_attributes: record, accounts: table<id: float, name: string, status: string, active_at: string, role: string, permissions: list, availability: string, availability_status: string, auto_offline: bool, custom_role_id: float, custom_role: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/platform/api/v1/users/($id)")
  let body = {name: $name, display_name: $display_name, email: $email, password: $password, custom_attributes: $custom_attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a User
#
# DELETE /platform/api/v1/users/{id}
# operationId: delete-a-user
export def "platform-users delete-a-user" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/platform/api/v1/users/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get User SSO Link
#
# GET /platform/api/v1/users/{id}/login
# operationId: get-sso-url-of-a-user
export def "platform-users-login get-sso-url-of-a-user" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<url: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/platform/api/v1/users/($id)/login")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Inbox details
#
# GET /public/api/v1/inboxes/{inbox_identifier}
# operationId: get-details-of-a-inbox
export def "public-inboxes get-details-of-a-inbox" [
  inbox_identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<identifier: string, name: string, timezone: string, working_hours: table<day_of_week: int, open_all_day: bool, closed_all_day: bool, open_hour: int, open_minutes: int, close_hour: int, close_minutes: int>, working_hours_enabled: bool, csat_survey_enabled: bool, greeting_enabled: bool, identity_validation_enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/api/v1/inboxes/($inbox_identifier)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a contact
#
# POST /public/api/v1/inboxes/{inbox_identifier}/contacts
# operationId: create-a-contact
export def "public-inboxes-contacts create-a-contact" [
  inbox_identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifier: string # External identifier of the contact (e.g. 1234567890)
  --identifier-hash: string # Identifier hash prepared for HMAC authentication (e.g. e93275d4eba0e5679ad55f5360af00444e2a888df9b0afa3e8b691c3173725f9)
  --email: string # Email of the contact (e.g. alice@acme.inc)
  --name: string # Name of the contact (e.g. Alice)
  --phone-number: string # Phone number of the contact (e.g. +123456789)
  --avatar: string # Send the form data with the avatar image binary or use the avatar_url (format: binary)
  --custom-attributes: record # Custom attributes of the customer (e.g. {})
]: any -> record<id: int, source_id: string, name: string, email: string, phone_number: string, pubsub_token: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/api/v1/inboxes/($inbox_identifier)/contacts")
  let body = {identifier: $identifier, identifier_hash: $identifier_hash, email: $email, name: $name, phone_number: $phone_number, avatar: $avatar, custom_attributes: $custom_attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a contact
#
# GET /public/api/v1/inboxes/{inbox_identifier}/contacts/{contact_identifier}
# operationId: get-details-of-a-contact
export def "public-inboxes-contacts get-details-of-a-contact" [
  inbox_identifier: string
  contact_identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, source_id: string, name: string, email: string, phone_number: string, pubsub_token: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/api/v1/inboxes/($inbox_identifier)/contacts/($contact_identifier)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a contact
#
# PATCH /public/api/v1/inboxes/{inbox_identifier}/contacts/{contact_identifier}
# operationId: update-a-contact
export def "public-inboxes-contacts update-a-contact" [
  inbox_identifier: string
  contact_identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifier: string # External identifier of the contact (e.g. 1234567890)
  --identifier-hash: string # Identifier hash prepared for HMAC authentication (e.g. e93275d4eba0e5679ad55f5360af00444e2a888df9b0afa3e8b691c3173725f9)
  --email: string # Email of the contact (e.g. alice@acme.inc)
  --name: string # Name of the contact (e.g. Alice)
  --phone-number: string # Phone number of the contact (e.g. +123456789)
  --avatar: string # Send the form data with the avatar image binary or use the avatar_url (format: binary)
  --custom-attributes: record # Custom attributes of the customer (e.g. {})
]: any -> record<id: int, name: string, email: string, phone_number: string, identifier: string, blocked: bool, additional_attributes: record, custom_attributes: record, contact_type: string, country_code: string, last_activity_at: string, created_at: string, updated_at: string, last_name: string, middle_name: string, location: string, account_id: int, company_id: int, label_list: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/api/v1/inboxes/($inbox_identifier)/contacts/($contact_identifier)")
  let body = {identifier: $identifier, identifier_hash: $identifier_hash, email: $email, name: $name, phone_number: $phone_number, avatar: $avatar, custom_attributes: $custom_attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a conversation
#
# POST /public/api/v1/inboxes/{inbox_identifier}/contacts/{contact_identifier}/conversations
# operationId: create-a-conversation
export def "public-inboxes-contacts-conversations create-a-conversation" [
  inbox_identifier: string
  contact_identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --custom-attributes: record # Custom attributes of the conversation (e.g. {})
]: any -> record<id: int, uuid: string, inbox_id: int, contact_last_seen_at: int, status: string, agent_last_seen_at: int, messages: table<id: int, content: string, message_type: int, content_type: string, content_attributes: record, created_at: int, conversation_id: int, attachments: list, sender: record>, contact: record<id: int, name: string, email: string, phone_number: string, identifier: string, blocked: bool, additional_attributes: record, custom_attributes: record, contact_type: string, country_code: string, last_activity_at: string, created_at: string, updated_at: string, last_name: string, middle_name: string, location: string, account_id: int, company_id: int, label_list: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/api/v1/inboxes/($inbox_identifier)/contacts/($contact_identifier)/conversations")
  let body = {custom_attributes: $custom_attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all conversations
#
# GET /public/api/v1/inboxes/{inbox_identifier}/contacts/{contact_identifier}/conversations
# operationId: list-all-contact-conversations
export def "public-inboxes-contacts-conversations list-all-contact-conversations" [
  inbox_identifier: string
  contact_identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, uuid: string, inbox_id: int, contact_last_seen_at: int, status: string, agent_last_seen_at: int, messages: list<record>, contact: record<id: int, name: string, email: string, phone_number: string, identifier: string, blocked: bool, additional_attributes: record, custom_attributes: record, contact_type: string, country_code: string, last_activity_at: string, created_at: string, updated_at: string, last_name: string, middle_name: string, location: string, account_id: int, company_id: int, label_list: list>> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/api/v1/inboxes/($inbox_identifier)/contacts/($contact_identifier)/conversations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single conversation
#
# GET /public/api/v1/inboxes/{inbox_identifier}/contacts/{contact_identifier}/conversations/{conversation_id}
# operationId: get-single-conversation
export def "public-inboxes-contacts-conversations get-single-conversation" [
  inbox_identifier: string
  contact_identifier: string
  conversation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, uuid: string, inbox_id: int, contact_last_seen_at: int, status: string, agent_last_seen_at: int, messages: table<id: int, content: string, message_type: int, content_type: string, content_attributes: record, created_at: int, conversation_id: int, attachments: list, sender: record>, contact: record<id: int, name: string, email: string, phone_number: string, identifier: string, blocked: bool, additional_attributes: record, custom_attributes: record, contact_type: string, country_code: string, last_activity_at: string, created_at: string, updated_at: string, last_name: string, middle_name: string, location: string, account_id: int, company_id: int, label_list: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/api/v1/inboxes/($inbox_identifier)/contacts/($contact_identifier)/conversations/($conversation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Resolve a conversation
#
# POST /public/api/v1/inboxes/{inbox_identifier}/contacts/{contact_identifier}/conversations/{conversation_id}/toggle_status
# operationId: resolve-conversation
export def "public-inboxes-contacts-conversations-toggle-status resolve-conversation" [
  inbox_identifier: string
  contact_identifier: string
  conversation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, uuid: string, inbox_id: int, contact_last_seen_at: int, status: string, agent_last_seen_at: int, messages: table<id: int, content: string, message_type: int, content_type: string, content_attributes: record, created_at: int, conversation_id: int, attachments: list, sender: record>, contact: record<id: int, name: string, email: string, phone_number: string, identifier: string, blocked: bool, additional_attributes: record, custom_attributes: record, contact_type: string, country_code: string, last_activity_at: string, created_at: string, updated_at: string, last_name: string, middle_name: string, location: string, account_id: int, company_id: int, label_list: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/api/v1/inboxes/($inbox_identifier)/contacts/($contact_identifier)/conversations/($conversation_id)/toggle_status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Toggle typing status
#
# POST /public/api/v1/inboxes/{inbox_identifier}/contacts/{contact_identifier}/conversations/{conversation_id}/toggle_typing
# operationId: toggle-typing-status
export def "public-inboxes-contacts-conversations-toggle-typing toggle-typing-status" [
  inbox_identifier: string
  contact_identifier: string
  conversation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --typing-status: string # Typing status, either 'on' or 'off'
  --typing-status: string@typing-status-completer # The typing status to set (e.g. on)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "typing_status" $typing_status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/public/api/v1/inboxes/($inbox_identifier)/contacts/($contact_identifier)/conversations/($conversation_id)/toggle_typing" $qp)
  let body = {typing_status: $typing_status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update last seen
#
# POST /public/api/v1/inboxes/{inbox_identifier}/contacts/{contact_identifier}/conversations/{conversation_id}/update_last_seen
# operationId: update-last-seen
export def "public-inboxes-contacts-conversations-update-last-seen update-last-seen" [
  inbox_identifier: string
  contact_identifier: string
  conversation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/api/v1/inboxes/($inbox_identifier)/contacts/($contact_identifier)/conversations/($conversation_id)/update_last_seen")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a message
#
# POST /public/api/v1/inboxes/{inbox_identifier}/contacts/{contact_identifier}/conversations/{conversation_id}/messages
# operationId: create-a-message
export def "public-inboxes-contacts-conversations-messages create-a-message" [
  inbox_identifier: string
  contact_identifier: string
  conversation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --content: string # Content for the message (e.g. Hello, how can I help you?)
  --echo-id: string # Temporary identifier which will be passed back via websockets (e.g. 1234567890)
]: any -> record<id: int, content: string, message_type: int, content_type: string, content_attributes: record, created_at: int, conversation_id: int, attachments: table<id: int, message_id: int, file_type: string, account_id: int, extension: string, data_url: string, thumb_url: string, file_size: int, width: int, height: int, coordinates_lat: float, coordinates_long: float, fallback_title: string, meta: record, transcribed_text: string>, sender: record<id: int, name: string, avatar_url: string, thumbnail: string, type: string, available_name: string, availability_status: string, email: string, phone_number: string, identifier: string, blocked: bool, additional_attributes: record, custom_attributes: record, description: string, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/api/v1/inboxes/($inbox_identifier)/contacts/($contact_identifier)/conversations/($conversation_id)/messages")
  let body = {content: $content, echo_id: $echo_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all messages
#
# GET /public/api/v1/inboxes/{inbox_identifier}/contacts/{contact_identifier}/conversations/{conversation_id}/messages
# operationId: list-all-conversation-messages
export def "public-inboxes-contacts-conversations-messages list-all-conversation-messages" [
  inbox_identifier: string
  contact_identifier: string
  conversation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, content: string, message_type: int, content_type: string, content_attributes: record, created_at: int, conversation_id: int, attachments: list<record>, sender: record<id: int, name: string, avatar_url: string, thumbnail: string, type: string, available_name: string, availability_status: string, email: string, phone_number: string, identifier: string, blocked: bool, additional_attributes: record, custom_attributes: record, description: string, created_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/api/v1/inboxes/($inbox_identifier)/contacts/($contact_identifier)/conversations/($conversation_id)/messages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a message
#
# PATCH /public/api/v1/inboxes/{inbox_identifier}/contacts/{contact_identifier}/conversations/{conversation_id}/messages/{message_id}
# operationId: update-a-message
# --submitted_values shape: {name?: string, title?: string, value?: string, csat_survey_response?: record}
export def "public-inboxes-contacts-conversations-messages update-a-message" [
  inbox_identifier: string
  contact_identifier: string
  conversation_id: int
  message_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --submitted-values: record # Replies to the Bot Message Types — shape: {name?: string, title?: string, value?: string, csat_survey_response?: record}
]: any -> record<id: int, content: string, message_type: int, content_type: string, content_attributes: record, created_at: int, conversation_id: int, attachments: table<id: int, message_id: int, file_type: string, account_id: int, extension: string, data_url: string, thumb_url: string, file_size: int, width: int, height: int, coordinates_lat: float, coordinates_long: float, fallback_title: string, meta: record, transcribed_text: string>, sender: record<id: int, name: string, avatar_url: string, thumbnail: string, type: string, available_name: string, availability_status: string, email: string, phone_number: string, identifier: string, blocked: bool, additional_attributes: record, custom_attributes: record, description: string, created_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/public/api/v1/inboxes/($inbox_identifier)/contacts/($contact_identifier)/conversations/($conversation_id)/messages/($message_id)")
  let body = {submitted_values: $submitted_values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get CSAT survey page
#
# GET /survey/responses/{conversation_uuid}
# operationId: get-csat-survey-page
export def "survey-responses get-csat-survey-page" [
  conversation_uuid: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/survey/responses/($conversation_uuid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get account details
#
# GET /api/v1/accounts/{account_id}
# operationId: get-account-details
export def "accounts get-account-details" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: float, name: string, locale: string, domain: string, support_email: string, status: string, created_at: string, cache_keys: record, features: record, settings: record<auto_resolve_after: float, auto_resolve_message: string, auto_resolve_ignore_waiting: bool>, custom_attributes: record<plan_name: string, subscribed_quantity: float, subscription_status: string, subscription_ends_on: string, industry: string, company_size: string, timezone: string, logo: string, onboarding_step: string, marked_for_deletion_at: string, marked_for_deletion_reason: string>, latest_chatwoot_version: string, subscribed_features: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update account
#
# PATCH /api/v1/accounts/{account_id}
# operationId: update-account
export def "accounts update-account" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Name of the account (e.g. My Account)
  --locale: string # The locale of the account (e.g. en)
  --domain: string # The domain of the account (e.g. example.com)
  --support-email: string # The support email of the account (e.g. support@example.com)
  --auto-resolve-after: int # Auto resolve conversations after specified minutes (nullable, e.g. 1440)
  --auto-resolve-message: string # Message to send when auto resolving (nullable, e.g. This conversation has been automatically resolved due to inactivity)
  --auto-resolve-ignore-waiting: string@bool-completer # Whether to ignore waiting conversations for auto resolve (nullable, e.g. false)
  --industry: string # Industry type (e.g. Technology)
  --company-size: string # Company size (e.g. 50-100)
  --timezone: string # Account timezone (e.g. UTC)
]: any -> record<id: float, name: string, locale: string, domain: string, support_email: string, status: string, created_at: string, cache_keys: record, features: record, settings: record<auto_resolve_after: float, auto_resolve_message: string, auto_resolve_ignore_waiting: bool>, custom_attributes: record<plan_name: string, subscribed_quantity: float, subscription_status: string, subscription_ends_on: string, industry: string, company_size: string, timezone: string, logo: string, onboarding_step: string, marked_for_deletion_at: string, marked_for_deletion_reason: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)")
  let body = {name: $name, locale: $locale, domain: $domain, support_email: $support_email, auto_resolve_after: $auto_resolve_after, auto_resolve_message: $auto_resolve_message, auto_resolve_ignore_waiting: $auto_resolve_ignore_waiting, industry: $industry, company_size: $company_size, timezone: $timezone} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Audit Logs in Account
#
# GET /api/v1/accounts/{account_id}/audit_logs
# operationId: get-account-audit-logs
export def "accounts-audit-logs get-account-audit-logs" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # Page number for pagination (default: 1)
]: nothing -> record<per_page: int, total_entries: int, current_page: int, audit_logs: table<id: int, auditable_id: int, auditable_type: string, auditable: record, associated_id: int, associated_type: string, user_id: int, user_type: string, username: string, action: string, audited_changes: record, version: int, comment: string, request_uuid: string, created_at: int, remote_address: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/audit_logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all AgentBots
#
# GET /api/v1/accounts/{account_id}/agent_bots
# operationId: list-all-account-agent-bots
export def "accounts-agent-bots list-all-account-agent-bots" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: float, name: string, description: string, thumbnail: string, outgoing_url: string, bot_type: string, bot_config: record, account_id: float, access_token: string, system_bot: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/agent_bots")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an Agent Bot
#
# POST /api/v1/accounts/{account_id}/agent_bots
# operationId: create-an-account-agent-bot
export def "accounts-agent-bots create-an-account-agent-bot" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the agent bot (e.g. My Agent Bot)
  --description: string # The description of the agent bot (e.g. This is a sample agent bot)
  --outgoing-url: string # The webhook URL for the bot (e.g. https://example.com/webhook)
  --avatar: string # Send the form data with the avatar image binary or use the avatar_url (format: binary)
  --avatar-url: string # The url to a jpeg, png file for the agent bot avatar (e.g. https://example.com/avatar.png)
  --bot-type: int # The type of the bot (0 for webhook) (e.g. 0)
  --bot-config: record # The configuration for the bot (e.g. {})
]: any -> record<id: float, name: string, description: string, thumbnail: string, outgoing_url: string, bot_type: string, bot_config: record, account_id: float, access_token: string, system_bot: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/agent_bots")
  let body = {name: $name, description: $description, outgoing_url: $outgoing_url, avatar: $avatar, avatar_url: $avatar_url, bot_type: $bot_type, bot_config: $bot_config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an agent bot details
#
# GET /api/v1/accounts/{account_id}/agent_bots/{id}
# operationId: get-details-of-a-single-account-agent-bot
export def "accounts-agent-bots get-details-of-a-single-account-agent-bot" [
  account_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: float, name: string, description: string, thumbnail: string, outgoing_url: string, bot_type: string, bot_config: record, account_id: float, access_token: string, system_bot: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/agent_bots/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an agent bot
#
# PATCH /api/v1/accounts/{account_id}/agent_bots/{id}
# operationId: update-an-account-agent-bot
export def "accounts-agent-bots update-an-account-agent-bot" [
  account_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the agent bot (e.g. My Agent Bot)
  --description: string # The description of the agent bot (e.g. This is a sample agent bot)
  --outgoing-url: string # The webhook URL for the bot (e.g. https://example.com/webhook)
  --avatar: string # Send the form data with the avatar image binary or use the avatar_url (format: binary)
  --avatar-url: string # The url to a jpeg, png file for the agent bot avatar (e.g. https://example.com/avatar.png)
  --bot-type: int # The type of the bot (0 for webhook) (e.g. 0)
  --bot-config: record # The configuration for the bot (e.g. {})
]: any -> record<id: float, name: string, description: string, thumbnail: string, outgoing_url: string, bot_type: string, bot_config: record, account_id: float, access_token: string, system_bot: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/agent_bots/($id)")
  let body = {name: $name, description: $description, outgoing_url: $outgoing_url, avatar: $avatar, avatar_url: $avatar_url, bot_type: $bot_type, bot_config: $bot_config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an AgentBot
#
# DELETE /api/v1/accounts/{account_id}/agent_bots/{id}
# operationId: delete-an-account-agent-bot
export def "accounts-agent-bots delete-an-account-agent-bot" [
  account_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/agent_bots/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Agents in Account
#
# GET /api/v1/accounts/{account_id}/agents
# operationId: get-account-agents
export def "accounts-agents get-account-agents" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, account_id: int, availability_status: string, auto_offline: bool, confirmed: bool, email: string, available_name: string, name: string, role: string, thumbnail: string, custom_role_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/agents")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a New Agent
#
# POST /api/v1/accounts/{account_id}/agents
# operationId: add-new-agent-to-account
export def "accounts-agents add-new-agent-to-account" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Full Name of the agent (e.g. John Doe)
  email: string # Email of the Agent (e.g. john.doe@acme.inc)
  role: string@role-completer # Whether its administrator or agent (e.g. agent)
  --availability: string@availability-completer # The configured availability of the agent. (e.g. online)
  --auto-offline: string@bool-completer # Whether the agent is automatically marked offline when they are away. (e.g. true)
]: any -> record<id: int, account_id: int, availability_status: string, auto_offline: bool, confirmed: bool, email: string, available_name: string, name: string, role: string, thumbnail: string, custom_role_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/agents")
  let body = {name: $name, email: $email, role: $role, availability: $availability, auto_offline: $auto_offline} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Agent in Account
#
# PATCH /api/v1/accounts/{account_id}/agents/{id}
# operationId: update-agent-in-account
export def "accounts-agents update-agent-in-account" [
  account_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  role: string@role-completer # Whether its administrator or agent (e.g. agent)
  --availability: string@availability-completer # The configured availability of the agent. (e.g. online)
  --auto-offline: string@bool-completer # Whether the agent is automatically marked offline when they are away. (e.g. true)
]: any -> record<id: int, account_id: int, availability_status: string, auto_offline: bool, confirmed: bool, email: string, available_name: string, name: string, role: string, thumbnail: string, custom_role_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/agents/($id)")
  let body = {role: $role, availability: $availability, auto_offline: $auto_offline} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove an Agent from Account
#
# DELETE /api/v1/accounts/{account_id}/agents/{id}
# operationId: delete-agent-from-account
export def "accounts-agents delete-agent-from-account" [
  account_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/agents/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all Canned Responses in an Account
#
# GET /api/v1/accounts/{account_id}/canned_responses
# operationId: get-account-canned-response
export def "accounts-canned-responses get-account-canned-response" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, account_id: int, short_code: string, content: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/canned_responses")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a New Canned Response
#
# POST /api/v1/accounts/{account_id}/canned_responses
# operationId: add-new-canned-response-to-account
export def "accounts-canned-responses add-new-canned-response-to-account" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --content: string # Message content for canned response (e.g. Hello, {{contact.name}}! Welcome to our service.)
  --short-code: string # Short Code for quick access of the canned response (e.g. welcome)
]: any -> record<id: int, account_id: int, short_code: string, content: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/canned_responses")
  let body = {content: $content, short_code: $short_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Canned Response in Account
#
# PATCH /api/v1/accounts/{account_id}/canned_responses/{id}
# operationId: update-canned-response-in-account
export def "accounts-canned-responses update-canned-response-in-account" [
  account_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --content: string # Message content for canned response (e.g. Hello, {{contact.name}}! Welcome to our service.)
  --short-code: string # Short Code for quick access of the canned response (e.g. welcome)
]: any -> record<id: int, account_id: int, short_code: string, content: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/canned_responses/($id)")
  let body = {content: $content, short_code: $short_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a Canned Response from Account
#
# DELETE /api/v1/accounts/{account_id}/canned_responses/{id}
# operationId: delete-canned-response-from-account
export def "accounts-canned-responses delete-canned-response-from-account" [
  account_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/canned_responses/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all custom attributes in an account
#
# GET /api/v1/accounts/{account_id}/custom_attribute_definitions
# operationId: get-account-custom-attribute
export def "accounts-custom-attribute-definitions get-account-custom-attribute" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --attribute-model: string@attribute-model-completer # conversation_attribute(0)/contact_attribute(1)
]: nothing -> table<id: int, attribute_display_name: string, attribute_display_type: string, attribute_description: string, attribute_key: string, regex_pattern: string, regex_cue: string, attribute_values: string, attribute_model: string, default_value: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attribute_model" $attribute_model "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/custom_attribute_definitions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a new custom attribute
#
# POST /api/v1/accounts/{account_id}/custom_attribute_definitions
# operationId: add-new-custom-attribute-to-account
export def "accounts-custom-attribute-definitions add-new-custom-attribute-to-account" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --attribute-display-name: string # Attribute display name (e.g. Custom Attribute)
  --attribute-display-type: int # Attribute display type (text- 0, number- 1, currency- 2, percent- 3, link- 4, date- 5, list- 6, checkbox- 7) (e.g. 0)
  --attribute-description: string # Attribute description (e.g. This is a custom attribute)
  --attribute-key: string # Attribute unique key value (e.g. custom_attribute)
  --attribute-values: list # Attribute values (e.g. [value1, value2])
  --attribute-model: int # Attribute type(conversation_attribute- 0, contact_attribute- 1) (e.g. 0)
  --regex-pattern: string # Regex pattern (Only applicable for type- text). The regex pattern is used to validate the attribute value(s). (e.g. ^[a-zA-Z0-9]+$)
  --regex-cue: string # Regex cue message (Only applicable for type- text). The cue message is shown when the regex pattern is not matched. (e.g. Please enter a valid value)
]: any -> record<id: int, attribute_display_name: string, attribute_display_type: string, attribute_description: string, attribute_key: string, regex_pattern: string, regex_cue: string, attribute_values: string, attribute_model: string, default_value: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/custom_attribute_definitions")
  let body = {attribute_display_name: $attribute_display_name, attribute_display_type: $attribute_display_type, attribute_description: $attribute_description, attribute_key: $attribute_key, attribute_values: $attribute_values, attribute_model: $attribute_model, regex_pattern: $regex_pattern, regex_cue: $regex_cue} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a custom attribute details
#
# GET /api/v1/accounts/{account_id}/custom_attribute_definitions/{id}
# operationId: get-details-of-a-single-custom-attribute
export def "accounts-custom-attribute-definitions get-details-of-a-single-custom-attribute" [
  account_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: int, attribute_display_name: string, attribute_display_type: string, attribute_description: string, attribute_key: string, regex_pattern: string, regex_cue: string, attribute_values: string, attribute_model: string, default_value: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/custom_attribute_definitions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update custom attribute in Account
#
# PATCH /api/v1/accounts/{account_id}/custom_attribute_definitions/{id}
# operationId: update-custom-attribute-in-account
export def "accounts-custom-attribute-definitions update-custom-attribute-in-account" [
  account_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --attribute-display-name: string # Attribute display name (e.g. Custom Attribute)
  --attribute-display-type: int # Attribute display type (text- 0, number- 1, currency- 2, percent- 3, link- 4, date- 5, list- 6, checkbox- 7) (e.g. 0)
  --attribute-description: string # Attribute description (e.g. This is a custom attribute)
  --attribute-key: string # Attribute unique key value (e.g. custom_attribute)
  --attribute-values: list # Attribute values (e.g. [value1, value2])
  --attribute-model: int # Attribute type(conversation_attribute- 0, contact_attribute- 1) (e.g. 0)
  --regex-pattern: string # Regex pattern (Only applicable for type- text). The regex pattern is used to validate the attribute value(s). (e.g. ^[a-zA-Z0-9]+$)
  --regex-cue: string # Regex cue message (Only applicable for type- text). The cue message is shown when the regex pattern is not matched. (e.g. Please enter a valid value)
]: any -> record<id: int, attribute_display_name: string, attribute_display_type: string, attribute_description: string, attribute_key: string, regex_pattern: string, regex_cue: string, attribute_values: string, attribute_model: string, default_value: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/custom_attribute_definitions/($id)")
  let body = {attribute_display_name: $attribute_display_name, attribute_display_type: $attribute_display_type, attribute_description: $attribute_description, attribute_key: $attribute_key, attribute_values: $attribute_values, attribute_model: $attribute_model, regex_pattern: $regex_pattern, regex_cue: $regex_cue} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a custom attribute from account
#
# DELETE /api/v1/accounts/{account_id}/custom_attribute_definitions/{id}
# operationId: delete-custom-attribute-from-account
export def "accounts-custom-attribute-definitions delete-custom-attribute-from-account" [
  account_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/custom_attribute_definitions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Contacts
#
# GET /api/v1/accounts/{account_id}/contacts
# operationId: contactList
export def "accounts-contacts contactList" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-sort: string@sort-completer # The attribute by which list should be sorted
  --page: int # The page parameter (default: 1)
]: nothing -> record<meta: record<count: int, current_page: string>, payload: table<additional_attributes: record, availability_status: string, email: string, id: int, name: string, phone_number: string, blocked: bool, identifier: string, thumbnail: string, custom_attributes: record, last_activity_at: int, created_at: int, contact_inboxes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/contacts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create Contact
#
# POST /api/v1/accounts/{account_id}/contacts
# operationId: contactCreate
export def "accounts-contacts contactCreate" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  inbox_id: float # ID of the inbox to which the contact belongs (e.g. 1)
  --name: string # name of the contact (e.g. Alice)
  --email: string # email of the contact (e.g. alice@acme.inc)
  --blocked: string@bool-completer # whether the contact is blocked or not (e.g. false)
  --phone-number: string # phone number of the contact (e.g. +123456789)
  --avatar: string # Send the form data with the avatar image binary or use the avatar_url (format: binary)
  --avatar-url: string # The url to a jpeg, png file for the contact avatar (e.g. https://example.com/avatar.png)
  --identifier: string # A unique identifier for the contact in external system (e.g. 1234567890)
  --additional-attributes: record # An object where you can store additional attributes for contact. example {"type":"customer", "age":30} (e.g. {type: customer, age: 30})
  --custom-attributes: record # An object where you can store custom attributes for contact. example {"type":"customer", "age":30}, this should have a valid custom attribute definition. (e.g. {})
]: any -> record<payload: table<additional_attributes: record, availability_status: string, email: string, id: int, name: string, phone_number: string, blocked: bool, identifier: string, thumbnail: string, custom_attributes: record, last_activity_at: int, created_at: int, contact_inboxes: list>, id: float, availability_status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/contacts")
  let body = {inbox_id: $inbox_id, name: $name, email: $email, blocked: $blocked, phone_number: $phone_number, avatar: $avatar, avatar_url: $avatar_url, identifier: $identifier, additional_attributes: $additional_attributes, custom_attributes: $custom_attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show Contact
#
# GET /api/v1/accounts/{account_id}/contacts/{id}
# operationId: contactDetails
export def "accounts-contacts contactDetails" [
  account_id: int
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<payload: record<additional_attributes: record<city: string, country: string, country_code: string, created_at_ip: string>, availability_status: string, email: string, id: int, name: string, phone_number: string, blocked: bool, identifier: string, thumbnail: string, custom_attributes: record, last_activity_at: int, created_at: int, contact_inboxes: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/contacts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Contact
#
# PUT /api/v1/accounts/{account_id}/contacts/{id}
# operationId: contactUpdate
export def "accounts-contacts contactUpdate" [
  account_id: int
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # name of the contact (e.g. Alice)
  --email: string # email of the contact (e.g. alice@acme.inc)
  --blocked: string@bool-completer # whether the contact is blocked or not (e.g. false)
  --phone-number: string # phone number of the contact (e.g. +123456789)
  --avatar: string # Send the form data with the avatar image binary or use the avatar_url (format: binary)
  --avatar-url: string # The url to a jpeg, png file for the contact avatar (e.g. https://example.com/avatar.png)
  --identifier: string # A unique identifier for the contact in external system (e.g. 1234567890)
  --additional-attributes: record # An object where you can store additional attributes for contact. example {"type":"customer", "age":30} (e.g. {type: customer, age: 30})
  --custom-attributes: record # An object where you can store custom attributes for contact. example {"type":"customer", "age":30}, this should have a valid custom attribute definition. (e.g. {})
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/contacts/($id)")
  let body = {name: $name, email: $email, blocked: $blocked, phone_number: $phone_number, avatar: $avatar, avatar_url: $avatar_url, identifier: $identifier, additional_attributes: $additional_attributes, custom_attributes: $custom_attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Contact
#
# DELETE /api/v1/accounts/{account_id}/contacts/{id}
# operationId: contactDelete
export def "accounts-contacts contactDelete" [
  account_id: int
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/contacts/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Contact Conversations
#
# GET /api/v1/accounts/{account_id}/contacts/{id}/conversations
# operationId: contactConversations
export def "accounts-contacts-conversations contactConversations" [
  account_id: int
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<payload: table<id: float, messages: list, account_id: float, uuid: string, additional_attributes: record, agent_last_seen_at: float, assignee_last_seen_at: float, can_reply: bool, contact_last_seen_at: float, custom_attributes: record, inbox_id: float, labels: list, muted: bool, snoozed_until: float, status: string, created_at: float, updated_at: float, timestamp: float, first_reply_created_at: float, unread_count: float, last_non_activity_message: any, last_activity_at: float, priority: string, waiting_since: float, sla_policy_id: float, applied_sla: record, sla_events: list, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/contacts/($id)/conversations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Labels
#
# GET /api/v1/accounts/{account_id}/contacts/{id}/labels
# operationId: list-all-labels-of-a-contact
export def "accounts-contacts-labels list-all-labels-of-a-contact" [
  account_id: int
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<payload: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/contacts/($id)/labels")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Labels
#
# POST /api/v1/accounts/{account_id}/contacts/{id}/labels
# operationId: contact-add-labels
export def "accounts-contacts-labels contact-add-labels" [
  account_id: int
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  labels: list # Array of labels (comma-separated strings) (e.g. [support, billing])
]: any -> record<payload: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/contacts/($id)/labels")
  let body = {labels: $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search Contacts
#
# GET /api/v1/accounts/{account_id}/contacts/search
# operationId: contactSearch
export def "accounts-contacts-search contactSearch" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --q: string # Search using contact `name`, `identifier`, `email` or `phone number`
  --qp-sort: string@sort-completer # The attribute by which list should be sorted
  --page: int # The page parameter (default: 1)
]: nothing -> record<meta: record<count: int, current_page: string>, payload: table<additional_attributes: record, availability_status: string, email: string, id: int, name: string, phone_number: string, blocked: bool, identifier: string, thumbnail: string, custom_attributes: record, last_activity_at: int, created_at: int, contact_inboxes: list>> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "q" $q "scalar") (serialize-qp "sort" $qp_sort "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/contacts/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Contact Filter
#
# POST /api/v1/accounts/{account_id}/contacts/filter
# operationId: contactFilter
# --payload item shape: {attribute_key?: string, filter_operator?: "equal_to"|"not_equal_to"|"contains"|"does_not_contain", values?: list, query_operator?: "AND"|"OR"}
export def "accounts-contacts-filter contactFilter" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: float
  --payload: list # e.g. [{attribute_key: name, filter_operator: equal_to, values: [en], query_operator: AND}, {attribute_key: country_code, filter_operator: equal_to, values: [us], query_operator: }] — item shape: {attribute_key?: string, filter_operator?: "equal_to"|"not_equal_to"|"contains"|"does_not_contain", values?: list, query_operator?: "AND"|"OR"}
]: any -> record<meta: record<count: int, current_page: string>, payload: table<additional_attributes: record, availability_status: string, email: string, id: int, name: string, phone_number: string, blocked: bool, identifier: string, thumbnail: string, custom_attributes: record, last_activity_at: int, created_at: int, contact_inboxes: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/contacts/filter" $qp)
  let body = {payload: $payload} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create contact inbox
#
# POST /api/v1/accounts/{account_id}/contacts/{id}/contact_inboxes
# operationId: contactInboxCreation
export def "accounts-contacts-contact-inboxes contactInboxCreation" [
  account_id: int
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  inbox_id: float # The ID of the inbox (e.g. 1)
  --source-id: string # Contact Inbox Source Id
]: any -> record<source_id: string, inbox: record<id: float, avatar_url: string, channel_id: float, name: string, channel_type: string, provider: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/contacts/($id)/contact_inboxes")
  let body = {inbox_id: $inbox_id, source_id: $source_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Contactable Inboxes
#
# GET /api/v1/accounts/{account_id}/contacts/{id}/contactable_inboxes
# operationId: contactableInboxesGet
export def "accounts-contacts-contactable-inboxes contactableInboxesGet" [
  account_id: int
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<payload: table<source_id: string, inbox: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/contacts/($id)/contactable_inboxes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Merge Contacts
#
# POST /api/v1/accounts/{account_id}/actions/contact_merge
# operationId: contactMerge
export def "accounts-actions-contact-merge contactMerge" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  base_contact_id: int # ID of the contact that will remain after the merge and receive all data (e.g. 1)
  mergee_contact_id: int # ID of the contact that will be merged into the base contact and deleted (e.g. 2)
]: any -> record<id: float, payload: table<additional_attributes: record, availability_status: string, email: string, id: int, name: string, phone_number: string, blocked: bool, identifier: string, thumbnail: string, custom_attributes: record, last_activity_at: int, created_at: int, contact_inboxes: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/actions/contact_merge")
  let body = {base_contact_id: $base_contact_id, mergee_contact_id: $mergee_contact_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all automation rules in an account
#
# GET /api/v1/accounts/{account_id}/automation_rules
# operationId: get-account-automation-rule
export def "accounts-automation-rules get-account-automation-rule" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page parameter (default: 1)
]: nothing -> record<payload: any> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/automation_rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a new automation rule
#
# POST /api/v1/accounts/{account_id}/automation_rules
# operationId: add-new-automation-rule-to-account
export def "accounts-automation-rules add-new-automation-rule-to-account" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Rule name (e.g. Add label on message create event)
  --description: string # The description about the automation and actions (e.g. Add label support and sales on message create event if incoming message content contains text help)
  --event-name: string@event-name-completer # The event when you want to execute the automation actions (e.g. message_created)
  --active: string@bool-completer # Enable/disable automation rule
  --actions: list # Array of actions which you want to perform when condition matches, e.g add label support if message contains content help.
  --conditions: list # Array of conditions on which conversation filter would work, e.g message content contains text help.
]: any -> record<payload: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/automation_rules")
  let body = {name: $name, description: $description, event_name: $event_name, active: $active, actions: $actions, conditions: $conditions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a automation rule details
#
# GET /api/v1/accounts/{account_id}/automation_rules/{id}
# operationId: get-details-of-a-single-automation-rule
export def "accounts-automation-rules get-details-of-a-single-automation-rule" [
  account_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<payload: any> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/automation_rules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update automation rule in Account
#
# PATCH /api/v1/accounts/{account_id}/automation_rules/{id}
# operationId: update-automation-rule-in-account
export def "accounts-automation-rules update-automation-rule-in-account" [
  account_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # Rule name (e.g. Add label on message create event)
  --description: string # The description about the automation and actions (e.g. Add label support and sales on message create event if incoming message content contains text help)
  --event-name: string@event-name-completer # The event when you want to execute the automation actions (e.g. message_created)
  --active: string@bool-completer # Enable/disable automation rule
  --actions: list # Array of actions which you want to perform when condition matches, e.g add label support if message contains content help.
  --conditions: list # Array of conditions on which conversation filter would work, e.g message content contains text help.
]: any -> record<payload: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/automation_rules/($id)")
  let body = {name: $name, description: $description, event_name: $event_name, active: $active, actions: $actions, conditions: $conditions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a automation rule from account
#
# DELETE /api/v1/accounts/{account_id}/automation_rules/{id}
# operationId: delete-automation-rule-from-account
export def "accounts-automation-rules delete-automation-rule-from-account" [
  account_id: int
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/automation_rules/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a new portal
#
# POST /api/v1/accounts/{account_id}/portals
# operationId: add-new-portal-to-account
export def "accounts-portals add-new-portal-to-account" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --color: string # Header color for help-center in hex format (e.g. #FFFFFF)
  --custom-domain: string # Custom domain to display help center. (e.g. chatwoot.help)
  --header-text: string # Help center header (e.g. Handbook)
  --homepage-link: string # link to main dashboard (e.g. https://www.chatwoot.com/)
  --name: string # Name for the portal (e.g. Handbook)
  --page-title: string # Page title for the portal (e.g. Handbook)
  --slug: string # Slug for the portal to display in link (e.g. handbook)
  --archived: string@bool-completer # Status to check if portal is live (e.g. false)
  --config: record # Configuration about supporting locales (e.g. {allowed_locales: [en, es], default_locale: en})
]: any -> record<payload: table<id: int, archived: bool, color: string, config: record, custom_domain: string, header_text: string, homepage_link: string, name: string, slug: string, page_title: string, account_id: int, inbox: record, logo: record, meta: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/portals")
  let body = {color: $color, custom_domain: $custom_domain, header_text: $header_text, homepage_link: $homepage_link, name: $name, page_title: $page_title, slug: $slug, archived: $archived, config: $config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all portals in an account
#
# GET /api/v1/accounts/{account_id}/portals
# operationId: get-portal
export def "accounts-portals get-portal" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<payload: table<id: int, archived: bool, color: string, config: record, custom_domain: string, header_text: string, homepage_link: string, name: string, slug: string, page_title: string, account_id: int, inbox: record, logo: record, meta: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/portals")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a portal
#
# PATCH /api/v1/accounts/{account_id}/portals/{id}
# operationId: update-portal-to-account
export def "accounts-portals update-portal-to-account" [
  account_id: int
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --color: string # Header color for help-center in hex format (e.g. #FFFFFF)
  --custom-domain: string # Custom domain to display help center. (e.g. chatwoot.help)
  --header-text: string # Help center header (e.g. Handbook)
  --homepage-link: string # link to main dashboard (e.g. https://www.chatwoot.com/)
  --name: string # Name for the portal (e.g. Handbook)
  --page-title: string # Page title for the portal (e.g. Handbook)
  --slug: string # Slug for the portal to display in link (e.g. handbook)
  --archived: string@bool-completer # Status to check if portal is live (e.g. false)
  --config: record # Configuration about supporting locales (e.g. {allowed_locales: [en, es], default_locale: en})
]: any -> record<payload: record<id: int, archived: bool, color: string, config: record<allowed_locales: list>, custom_domain: string, header_text: string, homepage_link: string, name: string, slug: string, page_title: string, account_id: int, inbox: record<id: float, name: string, website_url: string, channel_type: string, avatar_url: string, widget_color: string, website_token: string, enable_auto_assignment: bool, web_widget_script: string, welcome_title: string, welcome_tagline: string, greeting_enabled: bool, greeting_message: string, channel_id: float, working_hours_enabled: bool, enable_email_collect: bool, csat_survey_enabled: bool, auto_assignment_config: record, out_of_office_message: string, working_hours: list, timezone: string, callback_webhook_url: string, allow_messages_after_resolved: bool, lock_to_single_conversation: bool, sender_name_type: string, business_name: string, hmac_mandatory: bool, selected_feature_flags: list, reply_time: string, messaging_service_sid: string, phone_number: string, medium: string, provider: string>, logo: record<id: int, portal_id: int, file_type: string, account_id: int, file_url: string, blob_id: int, filename: string>, meta: record<all_articles_count: int, archived_articles_count: int, published_count: int, draft_articles_count: int, categories_count: int, default_locale: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/portals/($id)")
  let body = {color: $color, custom_domain: $custom_domain, header_text: $header_text, homepage_link: $homepage_link, name: $name, page_title: $page_title, slug: $slug, archived: $archived, config: $config} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a new category
#
# POST /api/v1/accounts/{account_id}/portals/{id}/categories
# operationId: add-new-category-to-account
export def "accounts-portals-categories add-new-category-to-account" [
  account_id: int
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the category (e.g. Category Name)
  --description: string # A description for the category (e.g. Category description)
  --position: int # Category position in the portal list to sort (e.g. 1)
  --slug: string # The category slug used in the URL (e.g. category-name)
  --locale: string # The locale of the category (e.g. en)
  --icon: string # The icon of the category as a string (emoji) (e.g. 📚)
  --parent-category-id: int # To define parent category, e.g product documentation has multiple level features in sales category or in engineering category. (e.g. 1)
  --associated-category-id: int # To associate similar categories to each other, e.g same category of product documentation in different languages (e.g. 2)
]: any -> record<id: int, description: string, locale: string, name: string, slug: string, position: int, portal_id: int, account_id: int, associated_category_id: int, parent_category_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/portals/($id)/categories")
  let body = {name: $name, description: $description, position: $position, slug: $slug, locale: $locale, icon: $icon, parent_category_id: $parent_category_id, associated_category_id: $associated_category_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Add a new article
#
# POST /api/v1/accounts/{account_id}/portals/{id}/articles
# operationId: add-new-article-to-account
export def "accounts-portals-articles add-new-article-to-account" [
  account_id: int
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # The title of the article (e.g. Article Title)
  --slug: string # The slug of the article (e.g. article-title)
  --position: int # article position in category (e.g. 1)
  --content: string # The text content. (e.g. This is the content of the article)
  --description: string # The description of the article (e.g. This is the description of the article)
  --category-id: int # The category id of the article (e.g. 1)
  --author-id: int # The author agent id of the article (e.g. 1)
  --associated-article-id: int # To associate similar articles to each other, e.g to provide the link for the reference. (e.g. 2)
  --status: int # The status of the article. 0 for draft, 1 for published, 2 for archived (e.g. 1)
  --locale: string # The locale of the article (e.g. en)
  --meta: record # Use for search (e.g. {tags: [article_name], title: article title, description: article description})
]: any -> record<id: int, content: string, meta: record, position: int, status: int, title: string, slug: string, views: int, portal_id: int, account_id: int, author_id: int, category_id: int, folder_id: int, associated_article_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/portals/($id)/articles")
  let body = {title: $title, slug: $slug, position: $position, content: $content, description: $description, category_id: $category_id, author_id: $author_id, associated_article_id: $associated_article_id, status: $status, locale: $locale, meta: $meta} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get Conversation Counts
#
# GET /api/v1/accounts/{account_id}/conversations/meta
# operationId: conversationListMeta
export def "accounts-conversations-meta conversationListMeta" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: string@status-completer-1 # Filter by conversation status. (default: open)
  --q: string # Filters conversations with messages containing the search term
  --inbox-id: int
  --team-id: int
  --labels: list
]: nothing -> record<meta: record<mine_count: float, unassigned_count: float, assigned_count: float, all_count: float>> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "inbox_id" $inbox_id "scalar") (serialize-qp "team_id" $team_id "scalar") (serialize-qp "labels" $labels "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/conversations/meta" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Conversations List
#
# GET /api/v1/accounts/{account_id}/conversations
# operationId: conversationList
export def "accounts-conversations conversationList" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --assignee-type: string@assignee-type-completer # Filter conversations by assignee type. (default: all)
  --status: string@status-completer-1 # Filter by conversation status. (default: open)
  --q: string # Filters conversations with messages containing the search term
  --inbox-id: int
  --team-id: int
  --labels: list
  --page: int # paginate through conversations (default: 1)
]: nothing -> record<data: record<meta: record<mine_count: float, unassigned_count: float, assigned_count: float, all_count: float>, payload: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "assignee_type" $assignee_type "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "q" $q "scalar") (serialize-qp "inbox_id" $inbox_id "scalar") (serialize-qp "team_id" $team_id "scalar") (serialize-qp "labels" $labels "multi") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/conversations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create New Conversation
#
# POST /api/v1/accounts/{account_id}/conversations
# operationId: newConversation
# --message shape: {content: string, template_params?: record}
export def "accounts-conversations newConversation" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  source_id: string # Conversation source id (e.g. 1234567890)
  --inbox-id: int # Id of inbox in which the conversation is created <br/> Allowed Inbox Types: Website, Phone, Api, Email (e.g. 1)
  --contact-id: int # Contact Id for which conversation is created (e.g. 1)
  --additional-attributes: record # Lets you specify attributes like browser information (e.g. {browser: Chrome, browser_version: 89.0.4389.82, os: Windows, os_version: 10})
  --custom-attributes: record # The object to save custom attributes for conversation, accepts custom attributes key and value (e.g. {attribute_key: attribute_value, priority_conversation_number: 3})
  --status: string@status-completer-2 # Specify the conversation whether it's pending, open, closed (e.g. open)
  --assignee-id: int # Agent Id for assigning a conversation to an agent (e.g. 1)
  --team-id: int # Team Id for assigning a conversation to a team\ (e.g. 1)
  --snoozed-until: string # Snoozed until date time (format: date-time, e.g. 2030-07-21T17:32:28Z)
  --message: record # The initial message to be sent to the conversation — shape: {content: string, template_params?: record}
]: any -> record<id: float, account_id: float, inbox_id: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/conversations")
  let body = {source_id: $source_id, inbox_id: $inbox_id, contact_id: $contact_id, additional_attributes: $additional_attributes, custom_attributes: $custom_attributes, status: $status, assignee_id: $assignee_id, team_id: $team_id, snoozed_until: $snoozed_until, message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Conversations Filter
#
# POST /api/v1/accounts/{account_id}/conversations/filter
# operationId: conversationFilter
# --payload item shape: {attribute_key?: string, filter_operator?: "equal_to"|"not_equal_to"|"contains"|"does_not_contain", values?: list, query_operator?: "AND"|"OR"}
export def "accounts-conversations-filter conversationFilter" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: float
  --payload: list # e.g. [{attribute_key: browser_language, filter_operator: not_equal_to, values: [en], query_operator: AND}, {attribute_key: status, filter_operator: equal_to, values: [pending], query_operator: }] — item shape: {attribute_key?: string, filter_operator?: "equal_to"|"not_equal_to"|"contains"|"does_not_contain", values?: list, query_operator?: "AND"|"OR"}
]: any -> record<data: record<meta: record<mine_count: float, unassigned_count: float, assigned_count: float, all_count: float>, payload: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/conversations/filter" $qp)
  let body = {payload: $payload} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Conversation Details
#
# GET /api/v1/accounts/{account_id}/conversations/{conversation_id}
# operationId: get-details-of-a-conversation
export def "accounts-conversations get-details-of-a-conversation" [
  account_id: int
  conversation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/conversations/($conversation_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Conversation
#
# PATCH /api/v1/accounts/{account_id}/conversations/{conversation_id}
# operationId: update-conversation
export def "accounts-conversations update-conversation" [
  account_id: int
  conversation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --priority: string@priority-completer # The priority of the conversation (e.g. high)
  --sla-policy-id: float # The ID of the SLA policy (Available only in Enterprise edition) (e.g. 1)
]: any -> record<id: float, messages: table<id: float, content: string, account_id: float, inbox_id: float, conversation_id: float, message_type: int, created_at: int, updated_at: int, private: bool, status: string, source_id: string, content_type: string, content_attributes: record, sender_type: string, sender_id: float, external_source_ids: record, additional_attributes: record, processed_message_content: string, sentiment: record, conversation: record, attachment: record, sender: record>, account_id: float, uuid: string, additional_attributes: record, agent_last_seen_at: float, assignee_last_seen_at: float, can_reply: bool, contact_last_seen_at: float, custom_attributes: record, inbox_id: float, labels: list<string>, muted: bool, snoozed_until: float, status: string, created_at: float, updated_at: float, timestamp: float, first_reply_created_at: float, unread_count: float, last_non_activity_message: any, last_activity_at: float, priority: string, waiting_since: float, sla_policy_id: float, applied_sla: record, sla_events: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/conversations/($conversation_id)")
  let body = {priority: $priority, sla_policy_id: $sla_policy_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Toggle Status
#
# POST /api/v1/accounts/{account_id}/conversations/{conversation_id}/toggle_status
# operationId: toggle-status-of-a-conversation
export def "accounts-conversations-toggle-status toggle-status-of-a-conversation" [
  account_id: int
  conversation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  status: string@status-completer-3 # The status of the conversation (e.g. open)
  --snoozed-until: float # When status is `snoozed`, schedule the reopen time as a Unix timestamp in seconds. If not provided, the conversation is snoozed until the next customer reply. The conversation always reopens when the customer replies. (e.g. 1757506877)
]: any -> record<meta: record, payload: record<success: bool, current_status: string, conversation_id: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/conversations/($conversation_id)/toggle_status")
  let body = {status: $status, snoozed_until: $snoozed_until} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Toggle Priority
#
# POST /api/v1/accounts/{account_id}/conversations/{conversation_id}/toggle_priority
# operationId: toggle-priority-of-a-conversation
export def "accounts-conversations-toggle-priority toggle-priority-of-a-conversation" [
  account_id: int
  conversation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  priority: string@priority-completer # The priority of the conversation (e.g. high)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/conversations/($conversation_id)/toggle_priority")
  let body = {priority: $priority} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Toggle Typing Status
#
# POST /api/v1/accounts/{account_id}/conversations/{conversation_id}/toggle_typing_status
# operationId: toggle-typing-status-of-a-conversation
export def "accounts-conversations-toggle-typing-status toggle-typing-status-of-a-conversation" [
  account_id: int
  conversation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  typing_status: string@typing-status-completer # Typing status to set. (e.g. on)
  --is-private: string@bool-completer # Whether the typing event is for private notes. (e.g. false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/conversations/($conversation_id)/toggle_typing_status")
  let body = {typing_status: $typing_status, is_private: $is_private} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Custom Attributes
#
# POST /api/v1/accounts/{account_id}/conversations/{conversation_id}/custom_attributes
# operationId: update-custom-attributes-of-a-conversation
export def "accounts-conversations-custom-attributes update-custom-attributes-of-a-conversation" [
  account_id: int
  conversation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  custom_attributes: record # The custom attributes to be set for the conversation (e.g. {order_id: 12345, previous_conversation: 67890})
]: any -> record<custom_attributes: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/conversations/($conversation_id)/custom_attributes")
  let body = {custom_attributes: $custom_attributes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Assign Conversation
#
# POST /api/v1/accounts/{account_id}/conversations/{conversation_id}/assignments
# operationId: assign-a-conversation
export def "accounts-conversations-assignments assign-a-conversation" [
  account_id: int
  conversation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --assignee-id: float # Id of the assignee user (e.g. 1)
  --team-id: float # Id of the team. If the assignee_id is present, this param would be ignored (e.g. 1)
]: any -> record<id: float, access_token: string, account_id: float, available_name: string, avatar_url: string, confirmed: bool, display_name: string, message_signature: string, email: string, hmac_identifier: string, inviter_id: float, name: string, provider: string, pubsub_token: string, role: string, ui_settings: record, uid: string, type: string, custom_attributes: record, accounts: table<id: float, name: string, status: string, active_at: string, role: string, permissions: list, availability: string, availability_status: string, auto_offline: bool, custom_role_id: float, custom_role: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/conversations/($conversation_id)/assignments")
  let body = {assignee_id: $assignee_id, team_id: $team_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Labels
#
# GET /api/v1/accounts/{account_id}/conversations/{conversation_id}/labels
# operationId: list-all-labels-of-a-conversation
export def "accounts-conversations-labels list-all-labels-of-a-conversation" [
  account_id: int
  conversation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<payload: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/conversations/($conversation_id)/labels")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add Labels
#
# POST /api/v1/accounts/{account_id}/conversations/{conversation_id}/labels
# operationId: conversation-add-labels
export def "accounts-conversations-labels conversation-add-labels" [
  account_id: int
  conversation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  labels: list # Array of labels (comma-separated strings) (e.g. [support, billing])
]: any -> record<payload: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/conversations/($conversation_id)/labels")
  let body = {labels: $labels} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Conversation Reporting Events
#
# GET /api/v1/accounts/{account_id}/conversations/{conversation_id}/reporting_events
# operationId: get-conversation-reporting-events
export def "accounts-conversations-reporting-events get-conversation-reporting-events" [
  account_id: int
  conversation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: float, name: string, value: float, value_in_business_hours: float, event_start_time: string, event_end_time: string, account_id: float, conversation_id: float, inbox_id: float, user_id: float, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/conversations/($conversation_id)/reporting_events")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all inboxes
#
# GET /api/v1/accounts/{account_id}/inboxes
# operationId: listAllInboxes
export def "accounts-inboxes listAllInboxes" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<payload: table<id: float, name: string, website_url: string, channel_type: string, avatar_url: string, widget_color: string, website_token: string, enable_auto_assignment: bool, web_widget_script: string, welcome_title: string, welcome_tagline: string, greeting_enabled: bool, greeting_message: string, channel_id: float, working_hours_enabled: bool, enable_email_collect: bool, csat_survey_enabled: bool, auto_assignment_config: record, out_of_office_message: string, working_hours: list, timezone: string, callback_webhook_url: string, allow_messages_after_resolved: bool, lock_to_single_conversation: bool, sender_name_type: string, business_name: string, hmac_mandatory: bool, selected_feature_flags: list, reply_time: string, messaging_service_sid: string, phone_number: string, medium: string, provider: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/inboxes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an inbox
#
# POST /api/v1/accounts/{account_id}/inboxes
# operationId: inboxCreation
# --csat_config shape: {display_type?: "emoji"|"star", message?: string, button_text?: string, language?: string, survey_rules?: record}
export def "accounts-inboxes inboxCreation" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the inbox. (e.g. Support)
  --avatar: string # Image file for avatar. (format: binary)
  --greeting-enabled: string@bool-completer # Enable greeting message. (e.g. true)
  --greeting-message: string # Greeting message to send when greeting messages are enabled. (e.g. Hello, how can I help you?)
  --enable-email-collect: string@bool-completer # Enable email collection.  Available for: `Website`  (e.g. true)
  --csat-survey-enabled: string@bool-completer # Enable CSAT survey. (e.g. true)
  --csat-config: record # CSAT survey configuration. — shape: {display_type?: "emoji"|"star", message?: string, button_text?: string, language?: string, survey_rules?: record}
  --enable-auto-assignment: string@bool-completer # Enable Auto Assignment. (e.g. true)
  --working-hours-enabled: string@bool-completer # Enable working hours. (e.g. true)
  --out-of-office-message: string # Out of office message to send outside working hours. (e.g. We are currently out of office. Please leave a message and we will get back to you.)
  --timezone: string # Timezone of the inbox. (e.g. America/New_York)
  --allow-messages-after-resolved: string@bool-completer # Allow messages after conversation is resolved.  Available for: `Website`  (e.g. true)
  --lock-to-single-conversation: string@bool-completer # Lock contact messages to a single active conversation.  Available for: `API` `LINE` `Telegram` `WhatsApp` `SMS`  (e.g. true)
  --portal-id: int # Id of the help center portal to attach to the inbox. (e.g. 1)
  --sender-name-type: string@sender-name-type-completer # Sender name type for outbound email replies.  Available for: `Website` `Email`  (e.g. friendly)
  --business-name: string # Business name for outbound email replies.  Available for: `Website` `Email`  (e.g. My Business)
  --channel: any
]: any -> record<id: float, name: string, website_url: string, channel_type: string, avatar_url: string, widget_color: string, website_token: string, enable_auto_assignment: bool, web_widget_script: string, welcome_title: string, welcome_tagline: string, greeting_enabled: bool, greeting_message: string, channel_id: float, working_hours_enabled: bool, enable_email_collect: bool, csat_survey_enabled: bool, auto_assignment_config: record, out_of_office_message: string, working_hours: table<day_of_week: float, closed_all_day: bool, open_hour: float, open_minutes: float, close_hour: float, close_minutes: float, open_all_day: bool>, timezone: string, callback_webhook_url: string, allow_messages_after_resolved: bool, lock_to_single_conversation: bool, sender_name_type: string, business_name: string, hmac_mandatory: bool, selected_feature_flags: list<string>, reply_time: string, messaging_service_sid: string, phone_number: string, medium: string, provider: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/inboxes")
  let body = {name: $name, avatar: $avatar, greeting_enabled: $greeting_enabled, greeting_message: $greeting_message, enable_email_collect: $enable_email_collect, csat_survey_enabled: $csat_survey_enabled, csat_config: $csat_config, enable_auto_assignment: $enable_auto_assignment, working_hours_enabled: $working_hours_enabled, out_of_office_message: $out_of_office_message, timezone: $timezone, allow_messages_after_resolved: $allow_messages_after_resolved, lock_to_single_conversation: $lock_to_single_conversation, portal_id: $portal_id, sender_name_type: $sender_name_type, business_name: $business_name, channel: $channel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get an inbox
#
# GET /api/v1/accounts/{account_id}/inboxes/{id}
# operationId: GetInbox
export def "accounts-inboxes GetInbox" [
  account_id: int
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: float, name: string, website_url: string, channel_type: string, avatar_url: string, widget_color: string, website_token: string, enable_auto_assignment: bool, web_widget_script: string, welcome_title: string, welcome_tagline: string, greeting_enabled: bool, greeting_message: string, channel_id: float, working_hours_enabled: bool, enable_email_collect: bool, csat_survey_enabled: bool, auto_assignment_config: record, out_of_office_message: string, working_hours: table<day_of_week: float, closed_all_day: bool, open_hour: float, open_minutes: float, close_hour: float, close_minutes: float, open_all_day: bool>, timezone: string, callback_webhook_url: string, allow_messages_after_resolved: bool, lock_to_single_conversation: bool, sender_name_type: string, business_name: string, hmac_mandatory: bool, selected_feature_flags: list<string>, reply_time: string, messaging_service_sid: string, phone_number: string, medium: string, provider: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/inboxes/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Inbox
#
# PATCH /api/v1/accounts/{account_id}/inboxes/{id}
# operationId: updateInbox
# --csat_config shape: {display_type?: "emoji"|"star", message?: string, button_text?: string, language?: string, survey_rules?: record}
export def "accounts-inboxes updateInbox" [
  account_id: int
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the inbox. (e.g. Support)
  --avatar: string # Image file for avatar. (format: binary)
  --greeting-enabled: string@bool-completer # Enable greeting message. (e.g. true)
  --greeting-message: string # Greeting message to send when greeting messages are enabled. (e.g. Hello, how can I help you?)
  --enable-email-collect: string@bool-completer # Enable email collection.  Available for: `Website`  (e.g. true)
  --csat-survey-enabled: string@bool-completer # Enable CSAT survey. (e.g. true)
  --csat-config: record # CSAT survey configuration. — shape: {display_type?: "emoji"|"star", message?: string, button_text?: string, language?: string, survey_rules?: record}
  --enable-auto-assignment: string@bool-completer # Enable Auto Assignment. (e.g. true)
  --working-hours-enabled: string@bool-completer # Enable working hours. (e.g. true)
  --out-of-office-message: string # Out of office message to send outside working hours. (e.g. We are currently out of office. Please leave a message and we will get back to you.)
  --timezone: string # Timezone of the inbox. (e.g. America/New_York)
  --allow-messages-after-resolved: string@bool-completer # Allow messages after conversation is resolved.  Available for: `Website`  (e.g. true)
  --lock-to-single-conversation: string@bool-completer # Lock contact messages to a single active conversation.  Available for: `API` `LINE` `Telegram` `WhatsApp` `SMS`  (e.g. true)
  --portal-id: int # Id of the help center portal to attach to the inbox. (e.g. 1)
  --sender-name-type: string@sender-name-type-completer # Sender name type for outbound email replies.  Available for: `Website` `Email`  (e.g. friendly)
  --business-name: string # Business name for outbound email replies.  Available for: `Website` `Email`  (e.g. My Business)
  --channel: any
]: any -> record<id: float, name: string, website_url: string, channel_type: string, avatar_url: string, widget_color: string, website_token: string, enable_auto_assignment: bool, web_widget_script: string, welcome_title: string, welcome_tagline: string, greeting_enabled: bool, greeting_message: string, channel_id: float, working_hours_enabled: bool, enable_email_collect: bool, csat_survey_enabled: bool, auto_assignment_config: record, out_of_office_message: string, working_hours: table<day_of_week: float, closed_all_day: bool, open_hour: float, open_minutes: float, close_hour: float, close_minutes: float, open_all_day: bool>, timezone: string, callback_webhook_url: string, allow_messages_after_resolved: bool, lock_to_single_conversation: bool, sender_name_type: string, business_name: string, hmac_mandatory: bool, selected_feature_flags: list<string>, reply_time: string, messaging_service_sid: string, phone_number: string, medium: string, provider: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/inboxes/($id)")
  let body = {name: $name, avatar: $avatar, greeting_enabled: $greeting_enabled, greeting_message: $greeting_message, enable_email_collect: $enable_email_collect, csat_survey_enabled: $csat_survey_enabled, csat_config: $csat_config, enable_auto_assignment: $enable_auto_assignment, working_hours_enabled: $working_hours_enabled, out_of_office_message: $out_of_office_message, timezone: $timezone, allow_messages_after_resolved: $allow_messages_after_resolved, lock_to_single_conversation: $lock_to_single_conversation, portal_id: $portal_id, sender_name_type: $sender_name_type, business_name: $business_name, channel: $channel} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Show Inbox Agent Bot
#
# GET /api/v1/accounts/{account_id}/inboxes/{id}/agent_bot
# operationId: getInboxAgentBot
export def "accounts-inboxes-agent-bot get" [
  account_id: int
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/inboxes/($id)/agent_bot")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add or remove agent bot
#
# POST /api/v1/accounts/{account_id}/inboxes/{id}/set_agent_bot
# operationId: updateAgentBot
export def "accounts-inboxes-set-agent-bot updateAgentBot" [
  account_id: int
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  agent_bot: float # Agent bot ID (e.g. 1)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/inboxes/($id)/set_agent_bot")
  let body = {agent_bot: $agent_bot} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List Agents in Inbox
#
# GET /api/v1/accounts/{account_id}/inbox_members/{inbox_id}
# operationId: get-inbox-members
export def "accounts-inbox-members get-inbox-members" [
  inbox_id: int
  account_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<payload: table<id: int, account_id: int, availability_status: string, auto_offline: bool, confirmed: bool, email: string, available_name: string, name: string, role: string, thumbnail: string, custom_role_id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/inbox_members/($inbox_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a New Agent
#
# POST /api/v1/accounts/{account_id}/inbox_members
# operationId: add-new-agent-to-inbox
export def "accounts-inbox-members add-new-agent-to-inbox" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  inbox_id: int # The ID of the inbox (e.g. 1)
  user_ids: list # IDs of users to be added to the inbox (e.g. [1])
]: any -> record<payload: table<id: int, account_id: int, availability_status: string, auto_offline: bool, confirmed: bool, email: string, available_name: string, name: string, role: string, thumbnail: string, custom_role_id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/inbox_members")
  let body = {inbox_id: $inbox_id, user_ids: $user_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Agents in Inbox
#
# PATCH /api/v1/accounts/{account_id}/inbox_members
# operationId: update-agents-in-inbox
export def "accounts-inbox-members update-agents-in-inbox" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  inbox_id: string # The ID of the inbox (e.g. 1)
  user_ids: list # IDs of users to be added to the inbox (e.g. [1])
]: any -> record<payload: table<id: int, account_id: int, availability_status: string, auto_offline: bool, confirmed: bool, email: string, available_name: string, name: string, role: string, thumbnail: string, custom_role_id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/inbox_members")
  let body = {inbox_id: $inbox_id, user_ids: $user_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove an Agent from Inbox
#
# DELETE /api/v1/accounts/{account_id}/inbox_members
# operationId: delete-agent-in-inbox
export def "accounts-inbox-members delete-agent-in-inbox" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  inbox_id: string # The ID of the inbox
  user_ids: list # IDs of users to be deleted from the inbox
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/inbox_members")
  let body = {inbox_id: $inbox_id, user_ids: $user_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all labels
#
# GET /api/v1/accounts/{account_id}/labels
# operationId: list-all-labels
export def "accounts-labels list-all-labels" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<payload: table<id: float, title: string, description: string, color: string, show_on_sidebar: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/labels")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a label
#
# POST /api/v1/accounts/{account_id}/labels
# operationId: create-a-label
export def "accounts-labels create-a-label" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # The label title (e.g. support)
  --description: string # A short description for the label (e.g. Conversations that need support follow-up)
  --color: string # Hex color code for the label (e.g. #1f93ff)
  --show-on-sidebar: string@bool-completer # Whether the label should appear in the sidebar (e.g. true)
]: any -> record<id: float, title: string, description: string, color: string, show_on_sidebar: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/labels")
  let body = {title: $title, description: $description, color: $color, show_on_sidebar: $show_on_sidebar} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a label
#
# GET /api/v1/accounts/{account_id}/labels/{id}
# operationId: get-details-of-a-single-label
export def "accounts-labels get-details-of-a-single-label" [
  account_id: int
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: float, title: string, description: string, color: string, show_on_sidebar: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/labels/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a label
#
# PATCH /api/v1/accounts/{account_id}/labels/{id}
# operationId: update-a-label
export def "accounts-labels update-a-label" [
  account_id: int
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --title: string # The label title (e.g. support)
  --description: string # A short description for the label (e.g. Conversations that need support follow-up)
  --color: string # Hex color code for the label (e.g. #1f93ff)
  --show-on-sidebar: string@bool-completer # Whether the label should appear in the sidebar (e.g. true)
]: any -> record<id: float, title: string, description: string, color: string, show_on_sidebar: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/labels/($id)")
  let body = {title: $title, description: $description, color: $color, show_on_sidebar: $show_on_sidebar} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a label
#
# DELETE /api/v1/accounts/{account_id}/labels/{id}
# operationId: delete-a-label
export def "accounts-labels delete-a-label" [
  account_id: int
  id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/labels/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get messages
#
# GET /api/v1/accounts/{account_id}/conversations/{conversation_id}/messages
# operationId: list-all-messages
export def "accounts-conversations-messages list-all-messages" [
  account_id: int
  conversation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: int # Fetch messages after the message with this ID. Returns up to 100 messages in ascending order.
  --before: int # Fetch messages before the message with this ID. Returns up to 20 messages in ascending order.
]: nothing -> record<meta: record<labels: list<string>, additional_attributes: record, contact: record<payload: list>, assignee: record<id: int, account_id: int, availability_status: string, auto_offline: bool, confirmed: bool, email: string, available_name: string, name: string, role: string, thumbnail: string, custom_role_id: int>, agent_last_seen_at: string, assignee_last_seen_at: string>, payload: table<id: float, content: string, account_id: float, inbox_id: float, conversation_id: float, message_type: int, created_at: int, updated_at: int, private: bool, status: string, source_id: string, content_type: string, content_attributes: record, sender_type: string, sender_id: float, external_source_ids: record, additional_attributes: record, processed_message_content: string, sentiment: record, conversation: record, attachment: record, sender: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/conversations/($conversation_id)/messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create New Message
#
# POST /api/v1/accounts/{account_id}/conversations/{conversation_id}/messages
# operationId: create-a-new-message-in-a-conversation
# --template_params shape: {name: string, category: "UTILITY"|"MARKETING"|"SHIPPING_UPDATE"|"TICKET_UPDATE"|"ISSUE_RESOLUTION", language: string, processed_params: record}
export def "accounts-conversations-messages create-a-new-message-in-a-conversation" [
  account_id: int
  conversation_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  content: string # The content of the message (e.g. Hello, how can I help you?)
  --message-type: string@message-type-completer # The type of the message (e.g. outgoing)
  --private: string@bool-completer # Flag to identify if it is a private note (e.g. false)
  --content-type: string@content-type-completer # Content type of the message (e.g. text)
  --content-attributes: record # Attributes based on the content type (e.g. {})
  --campaign-id: int # The campaign id to which the message belongs (e.g. 1)
  --template-params: record # WhatsApp template parameters for sending structured messages — shape: {name: string, category: "UTILITY"|"MARKETING"|"SHIPPING_UPDATE"|"TICKET_UPDATE"|"ISSUE_RESOLUTION", language: string, processed_params: record}
]: any -> record<id: float, content: string, account_id: float, inbox_id: float, conversation_id: float, message_type: int, created_at: int, updated_at: int, private: bool, status: string, source_id: string, content_type: string, content_attributes: record, sender_type: string, sender_id: float, external_source_ids: record, additional_attributes: record, processed_message_content: string, sentiment: record, conversation: record, attachment: record, sender: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/conversations/($conversation_id)/messages")
  let body = {content: $content, message_type: $message_type, private: $private, content_type: $content_type, content_attributes: $content_attributes, campaign_id: $campaign_id, template_params: $template_params} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a message
#
# DELETE /api/v1/accounts/{account_id}/conversations/{conversation_id}/messages/{message_id}
# operationId: delete-a-message
export def "accounts-conversations-messages delete-a-message" [
  account_id: int
  conversation_id: int
  message_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/conversations/($conversation_id)/messages/($message_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all the Integrations
#
# GET /api/v1/accounts/{account_id}/integrations/apps
# operationId: get-details-of-all-integrations
export def "accounts-integrations-apps get-details-of-all-integrations" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<payload: table<id: string, name: string, description: string, hook_type: string, enabled: bool, allow_multiple_hooks: bool, hooks: list>> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/integrations/apps")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an integration hook
#
# POST /api/v1/accounts/{account_id}/integrations/hooks
# operationId: create-an-integration-hook
export def "accounts-integrations-hooks create-an-integration-hook" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --app-id: int # The ID of app for which integration hook is being created (e.g. 1)
  --inbox-id: int # The inbox ID, if the hook is an inbox hook (e.g. 1)
  --status: int # The status of the integration (0 for inactive, 1 for active) (e.g. 1)
  --settings: record # The settings required by the integration (e.g. {})
]: any -> record<id: string, app_id: string, inbox_id: string, account_id: string, status: bool, hook_type: bool, settings: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/integrations/hooks")
  let body = {app_id: $app_id, inbox_id: $inbox_id, status: $status, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an Integration Hook
#
# PATCH /api/v1/accounts/{account_id}/integrations/hooks/{hook_id}
# operationId: update-an-integrations-hook
export def "accounts-integrations-hooks update-an-integrations-hook" [
  account_id: int
  hook_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --status: int # The status of the integration (0 for inactive, 1 for active) (e.g. 1)
  --settings: record # The settings required by the integration (e.g. {})
]: any -> record<id: string, app_id: string, inbox_id: string, account_id: string, status: bool, hook_type: bool, settings: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/integrations/hooks/($hook_id)")
  let body = {status: $status, settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an Integration Hook
#
# DELETE /api/v1/accounts/{account_id}/integrations/hooks/{hook_id}
# operationId: delete-an-integration-hook
export def "accounts-integrations-hooks delete-an-integration-hook" [
  account_id: int
  hook_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/integrations/hooks/($hook_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch user profile
#
# GET /api/v1/profile
# operationId: fetchProfile
export def "profile fetchProfile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: float, access_token: string, account_id: float, available_name: string, avatar_url: string, confirmed: bool, display_name: string, message_signature: string, email: string, hmac_identifier: string, inviter_id: float, name: string, provider: string, pubsub_token: string, role: string, ui_settings: record, uid: string, type: string, custom_attributes: record, accounts: table<id: float, name: string, status: string, active_at: string, role: string, permissions: list, availability: string, availability_status: string, auto_offline: bool, custom_role_id: float, custom_role: record>> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/profile")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update user profile
#
# PUT /api/v1/profile
# operationId: updateProfile
# --profile shape: {name?: string, email?: string, display_name?: string, message_signature?: string, phone_number?: string, current_password?: string, password?: string, password_confirmation?: string, ui_settings?: record}
export def "profile updateProfile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  profile: record # shape: {name?: string, email?: string, display_name?: string, message_signature?: string, phone_number?: string, current_password?: string, password?: string, password_confirmation?: string, ui_settings?: record}
]: any -> record<id: float, access_token: string, account_id: float, available_name: string, avatar_url: string, confirmed: bool, display_name: string, message_signature: string, email: string, hmac_identifier: string, inviter_id: float, name: string, provider: string, pubsub_token: string, role: string, ui_settings: record, uid: string, type: string, custom_attributes: record, accounts: table<id: float, name: string, status: string, active_at: string, role: string, permissions: list, availability: string, availability_status: string, auto_offline: bool, custom_role_id: float, custom_role: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/v1/profile")
  let body = {profile: $profile} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all teams
#
# GET /api/v1/accounts/{account_id}/teams
# operationId: list-all-teams
export def "accounts-teams list-all-teams" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: float, name: string, description: string, allow_auto_assign: bool, account_id: float, is_member: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/teams")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a team
#
# POST /api/v1/accounts/{account_id}/teams
# operationId: create-a-team
export def "accounts-teams create-a-team" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the team (e.g. Support Team)
  --description: string # The description of the team (e.g. This is a team of support agents)
  --allow-auto-assign: string@bool-completer # If this setting is turned on, the system would automatically assign the conversation to an agent in the team while assigning the conversation to a team (e.g. true)
]: any -> record<id: float, name: string, description: string, allow_auto_assign: bool, account_id: float, is_member: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/teams")
  let body = {name: $name, description: $description, allow_auto_assign: $allow_auto_assign} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a team details
#
# GET /api/v1/accounts/{account_id}/teams/{team_id}
# operationId: get-details-of-a-single-team
export def "accounts-teams get-details-of-a-single-team" [
  account_id: int
  team_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: float, name: string, description: string, allow_auto_assign: bool, account_id: float, is_member: bool> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/teams/($team_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a team
#
# PATCH /api/v1/accounts/{account_id}/teams/{team_id}
# operationId: update-a-team
export def "accounts-teams update-a-team" [
  account_id: int
  team_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the team (e.g. Support Team)
  --description: string # The description of the team (e.g. This is a team of support agents)
  --allow-auto-assign: string@bool-completer # If this setting is turned on, the system would automatically assign the conversation to an agent in the team while assigning the conversation to a team (e.g. true)
]: any -> record<id: float, name: string, description: string, allow_auto_assign: bool, account_id: float, is_member: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/teams/($team_id)")
  let body = {name: $name, description: $description, allow_auto_assign: $allow_auto_assign} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a team
#
# DELETE /api/v1/accounts/{account_id}/teams/{team_id}
# operationId: delete-a-team
export def "accounts-teams delete-a-team" [
  account_id: int
  team_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/teams/($team_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List Agents in Team
#
# GET /api/v1/accounts/{account_id}/teams/{team_id}/team_members
# operationId: get-team-members
export def "accounts-teams-team-members get-team-members" [
  account_id: int
  team_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: int, account_id: int, availability_status: string, auto_offline: bool, confirmed: bool, email: string, available_name: string, name: string, role: string, thumbnail: string, custom_role_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/teams/($team_id)/team_members")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a New Agent
#
# POST /api/v1/accounts/{account_id}/teams/{team_id}/team_members
# operationId: add-new-agent-to-team
export def "accounts-teams-team-members add-new-agent-to-team" [
  account_id: int
  team_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user_ids: list # IDs of users to be added to the team (e.g. [1])
]: any -> table<id: int, account_id: int, availability_status: string, auto_offline: bool, confirmed: bool, email: string, available_name: string, name: string, role: string, thumbnail: string, custom_role_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/teams/($team_id)/team_members")
  let body = {user_ids: $user_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update Agents in Team
#
# PATCH /api/v1/accounts/{account_id}/teams/{team_id}/team_members
# operationId: update-agents-in-team
export def "accounts-teams-team-members update-agents-in-team" [
  account_id: int
  team_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user_ids: list # IDs of users to be added to the team (e.g. [1])
]: any -> table<id: int, account_id: int, availability_status: string, auto_offline: bool, confirmed: bool, email: string, available_name: string, name: string, role: string, thumbnail: string, custom_role_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/teams/($team_id)/team_members")
  let body = {user_ids: $user_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove an Agent from Team
#
# DELETE /api/v1/accounts/{account_id}/teams/{team_id}/team_members
# operationId: delete-agent-in-team
export def "accounts-teams-team-members delete-agent-in-team" [
  account_id: int
  team_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  user_ids: list # IDs of users to be deleted from the team
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/teams/($team_id)/team_members")
  let body = {user_ids: $user_ids} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all custom filters
#
# GET /api/v1/accounts/{account_id}/custom_filters
# operationId: list-all-filters
export def "accounts-custom-filters list-all-filters" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter-type: string@filter-type-completer # The type of custom filter
]: nothing -> table<id: float, name: string, type: string, query: record, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter_type" $filter_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/custom_filters" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a custom filter
#
# POST /api/v1/accounts/{account_id}/custom_filters
# operationId: create-a-custom-filter
export def "accounts-custom-filters create-a-custom-filter" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filter-type: string@filter-type-completer # The type of custom filter
  --name: string # The name of the custom filter (e.g. My Custom Filter)
  --type: string@type-completer # The description about the custom filter (e.g. conversation)
  --body-query: record # A query that needs to be saved as a custom filter (e.g. {})
]: any -> record<id: float, name: string, type: string, query: record, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter_type" $filter_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/custom_filters" $qp)
  let body = {name: $name, type: $type, query: $body_query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a custom filter details
#
# GET /api/v1/accounts/{account_id}/custom_filters/{custom_filter_id}
# operationId: get-details-of-a-single-custom-filter
export def "accounts-custom-filters get-details-of-a-single-custom-filter" [
  account_id: int
  custom_filter_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<id: float, name: string, type: string, query: record, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/custom_filters/($custom_filter_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a custom filter
#
# PATCH /api/v1/accounts/{account_id}/custom_filters/{custom_filter_id}
# operationId: update-a-custom-filter
export def "accounts-custom-filters update-a-custom-filter" [
  account_id: int
  custom_filter_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the custom filter (e.g. My Custom Filter)
  --type: string@type-completer # The description about the custom filter (e.g. conversation)
  --body-query: record # A query that needs to be saved as a custom filter (e.g. {})
]: any -> record<id: float, name: string, type: string, query: record, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/custom_filters/($custom_filter_id)")
  let body = {name: $name, type: $type, query: $body_query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a custom filter
#
# DELETE /api/v1/accounts/{account_id}/custom_filters/{custom_filter_id}
# operationId: delete-a-custom-filter
export def "accounts-custom-filters delete-a-custom-filter" [
  account_id: int
  custom_filter_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/custom_filters/($custom_filter_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all webhooks
#
# GET /api/v1/accounts/{account_id}/webhooks
# operationId: list-all-webhooks
export def "accounts-webhooks list-all-webhooks" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<id: float, url: string, name: string, subscriptions: list<string>, secret: string, account_id: float> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/webhooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a webhook
#
# POST /api/v1/accounts/{account_id}/webhooks
# operationId: create-a-webhook
export def "accounts-webhooks create-a-webhook" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-url: string # The url where the events should be sent (e.g. https://example.com/webhook)
  --name: string # The name of the webhook
  --subscriptions: list # The events you want to subscribe to. (e.g. [conversation_created, conversation_status_changed])
]: any -> record<id: float, url: string, name: string, subscriptions: list<string>, secret: string, account_id: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/webhooks")
  let body = {url: $body_url, name: $name, subscriptions: $subscriptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a webhook object
#
# PATCH /api/v1/accounts/{account_id}/webhooks/{webhook_id}
# operationId: update-a-webhook
export def "accounts-webhooks update-a-webhook" [
  account_id: int
  webhook_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-url: string # The url where the events should be sent (e.g. https://example.com/webhook)
  --name: string # The name of the webhook
  --subscriptions: list # The events you want to subscribe to. (e.g. [conversation_created, conversation_status_changed])
]: any -> record<id: float, url: string, name: string, subscriptions: list<string>, secret: string, account_id: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/webhooks/($webhook_id)")
  let body = {url: $body_url, name: $name, subscriptions: $subscriptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a webhook
#
# DELETE /api/v1/accounts/{account_id}/webhooks/{webhook_id}
# operationId: delete-a-webhook
export def "accounts-webhooks delete-a-webhook" [
  account_id: int
  webhook_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/webhooks/($webhook_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Account Reporting Events
#
# GET /api/v1/accounts/{account_id}/reporting_events
# operationId: get-account-reporting-events
export def "accounts-reporting-events get-account-reporting-events" [
  account_id: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # The page parameter (default: 1)
  --since: string # The timestamp from where events should start (Unix timestamp in seconds)
  --until: string # The timestamp from where events should stop (Unix timestamp in seconds)
  --inbox-id: float # Filter events by inbox ID
  --user-id: float # Filter events by user/agent ID
  --name: string # Filter events by event name (e.g., first_response, resolution, reply_time)
]: nothing -> record<meta: record<count: int, current_page: int, total_pages: int>, payload: table<id: float, name: string, value: float, value_in_business_hours: float, event_start_time: string, event_end_time: string, account_id: float, conversation_id: float, inbox_id: float, user_id: float, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "inbox_id" $inbox_id "scalar") (serialize-qp "user_id" $user_id "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v1/accounts/($account_id)/reporting_events" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Account reports
#
# GET /api/v2/accounts/{account_id}/reports
# operationId: list-all-conversation-statistics
export def "accounts-reports list-all-conversation-statistics" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --metric: string@metric-completer # The type of metric
  --type: string@type-completer-1 # Type of report
  --id: string # The Id of specific object in case of agent/inbox/label
  --since: string # The timestamp from where report should start.
  --until: string # The timestamp from where report should stop.
]: nothing -> table<value: string, timestamp: float> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "metric" $metric "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/accounts/($account_id)/reports" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Account reports summary
#
# GET /api/v2/accounts/{account_id}/reports/summary
# operationId: list-all-conversation-statistics-summary
export def "accounts-reports-summary list-all-conversation-statistics-summary" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-1 # Type of report
  --id: string # The Id of specific object in case of agent/inbox/label
  --since: string # The timestamp from where report should start.
  --until: string # The timestamp from where report should stop.
]: nothing -> record<avg_first_response_time: string, avg_resolution_time: string, conversations_count: float, incoming_messages_count: float, outgoing_messages_count: float, resolutions_count: float, previous: record<avg_first_response_time: string, avg_resolution_time: string, conversations_count: float, incoming_messages_count: float, outgoing_messages_count: float, resolutions_count: float>> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/accounts/($account_id)/reports/summary" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Account Conversation Metrics
#
# GET /api/v2/accounts/{account_id}/reports/conversations
# operationId: get-account-conversation-metrics
export def "accounts-reports-conversations get-account-conversation-metrics" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-2 # Type of report
]: nothing -> record<open: float, unattended: float, unassigned: float> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/accounts/($account_id)/reports/conversations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Agent Conversation Metrics
#
# GET /api/v2/accounts/{account_id}/reports/conversations/
# operationId: get-agent-conversation-metrics
export def "accounts-reports-conversations get-agent-conversation-metrics" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-3 # Type of report
  --user-id: string # The numeric ID of the user
]: nothing -> table<id: float, name: string, email: string, thumbnail: string, availability: string, metric: record<open: float, unattended: float>> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar") (serialize-qp "user_id" $user_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/accounts/($account_id)/reports/conversations/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get conversation statistics grouped by channel type
#
# GET /api/v2/accounts/{account_id}/summary_reports/channel
# operationId: get-channel-summary-report
export def "accounts-summary-reports-channel get-channel-summary-report" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # The timestamp from where report should start (Unix timestamp).
  --until: string # The timestamp from where report should stop (Unix timestamp).
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/accounts/($account_id)/summary_reports/channel" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get conversation statistics grouped by inbox
#
# GET /api/v2/accounts/{account_id}/summary_reports/inbox
# operationId: get-inbox-summary-report
export def "accounts-summary-reports-inbox get-inbox-summary-report" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # The timestamp from where report should start (Unix timestamp).
  --until: string # The timestamp from where report should stop (Unix timestamp).
  --business-hours: string@bool-completer # Whether to calculate metrics using business hours only.
]: nothing -> table<id: float, conversations_count: float, resolved_conversations_count: float, avg_resolution_time: float, avg_first_response_time: float, avg_reply_time: float> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "business_hours" $business_hours "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/accounts/($account_id)/summary_reports/inbox" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get conversation statistics grouped by agent
#
# GET /api/v2/accounts/{account_id}/summary_reports/agent
# operationId: get-agent-summary-report
export def "accounts-summary-reports-agent get-agent-summary-report" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # The timestamp from where report should start (Unix timestamp).
  --until: string # The timestamp from where report should stop (Unix timestamp).
  --business-hours: string@bool-completer # Whether to calculate metrics using business hours only.
]: nothing -> table<id: float, conversations_count: float, resolved_conversations_count: float, avg_resolution_time: float, avg_first_response_time: float, avg_reply_time: float> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "business_hours" $business_hours "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/accounts/($account_id)/summary_reports/agent" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get conversation statistics grouped by team
#
# GET /api/v2/accounts/{account_id}/summary_reports/team
# operationId: get-team-summary-report
export def "accounts-summary-reports-team get-team-summary-report" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # The timestamp from where report should start (Unix timestamp).
  --until: string # The timestamp from where report should stop (Unix timestamp).
  --business-hours: string@bool-completer # Whether to calculate metrics using business hours only.
]: nothing -> table<id: float, conversations_count: float, resolved_conversations_count: float, avg_resolution_time: float, avg_first_response_time: float, avg_reply_time: float> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "business_hours" $business_hours "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/accounts/($account_id)/summary_reports/team" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get first response time distribution by channel
#
# GET /api/v2/accounts/{account_id}/reports/first_response_time_distribution
# operationId: get-first-response-time-distribution
export def "accounts-reports-first-response-time-distribution get-first-response-time-distribution" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # The timestamp from where report should start (Unix timestamp).
  --until: string # The timestamp from where report should stop (Unix timestamp).
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/accounts/($account_id)/reports/first_response_time_distribution" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get inbox-label matrix report
#
# GET /api/v2/accounts/{account_id}/reports/inbox_label_matrix
# operationId: get-inbox-label-matrix
export def "accounts-reports-inbox-label-matrix get-inbox-label-matrix" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # The timestamp from where report should start (Unix timestamp).
  --until: string # The timestamp from where report should stop (Unix timestamp).
  --inbox-ids: list # Filter by specific inbox IDs.
  --label-ids: list # Filter by specific label IDs.
]: nothing -> record<inboxes: table<id: float, name: string>, labels: table<id: float, title: string>, matrix: list<list<float>>> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "inbox_ids" $inbox_ids "multi") (serialize-qp "label_ids" $label_ids "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/accounts/($account_id)/reports/inbox_label_matrix" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get outgoing messages count grouped by entity
#
# GET /api/v2/accounts/{account_id}/reports/outgoing_messages_count
# operationId: get-outgoing-messages-count
export def "accounts-reports-outgoing-messages-count get-outgoing-messages-count" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --since: string # The timestamp from where report should start (Unix timestamp).
  --until: string # The timestamp from where report should stop (Unix timestamp).
  --group-by: string@group-by-completer # The entity to group outgoing message counts by.
]: nothing -> table<id: float, name: string, outgoing_messages_count: float> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "since" $since "scalar") (serialize-qp "until" $until "scalar") (serialize-qp "group_by" $group_by "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/v2/accounts/($account_id)/reports/outgoing_messages_count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get messages from a conversation
#
# GET /accounts/{account_id}/conversations/{conversation_id}/messages
# operationId: getConversationMessages
export def "accounts-conversations-messages get" [
  account_id: int
  conversation_id: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<meta: record<labels: list<string>, additional_attributes: record<browser: record, referer: string, initiated_at: record, browser_language: string, conversation_language: string>, contact: record<additional_attributes: record, custom_attributes: record, email: string, id: int, identifier: string, name: string, phone_number: string, thumbnail: string, blocked: bool, type: string>, assignee: record<id: int, account_id: int, availability_status: string, auto_offline: bool, confirmed: bool, email: string, available_name: string, name: string, role: string, thumbnail: string, custom_role_id: int>, agent_last_seen_at: string, assignee_last_seen_at: string>, payload: table<id: float, content: string, inbox_id: float, conversation_id: float, message_type: int, content_type: string, status: string, content_attributes: record, echo_id: string, created_at: int, private: bool, source_id: string, sender: record, attachments: list>> {
  let auth = (build-auth $token ($auth_scheme | default "api_access_token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/accounts/($account_id)/conversations/($conversation_id)/messages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
