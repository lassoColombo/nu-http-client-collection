# Auto-generated client for Twilio - Conversations v1.42.0
# Source: https://api.apis.guru/v2/specs/twilio.com/twilio_conversations_v1/1.42.0/openapi.json
# Auth: --token flag or $env.TWILIO_CONVERSATIONS_TOKEN

const BASE_URL = "https://conversations.twilio.com"
const DEFAULT_AUTH = "basic"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o TWILIO_CONVERSATIONS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
    "basic-credentials" => { {headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: ""} }
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

def base-url-completer [] { ["https://conversations.twilio.com"] }
def auth-scheme-completer [] { ["basic" "basic-credentials"] }

# Completers for enum parameters
def auto-creation-type-completer [] { ["default" "studio" "webhook"] }
def auto-creation-webhook-method-completer [] { ["GET" "POST"] }
def type-completer [] { ["gbm" "messenger" "sms" "whatsapp"] }
def target-completer [] { ["flex" "webhook"] }
def state-completer [] { ["active" "closed" "inactive"] }
def x-twilio-webhook-enabled-completer [] { ["false" "true"] }
def order-completer [] { ["asc" "desc"] }
def configuration-method-completer [] { ["GET" "POST"] }
def target-completer-1 [] { ["studio" "trigger" "webhook"] }
def type-completer-1 [] { ["apn" "fcm" "gcm"] }
def type-completer-2 [] { ["conversation" "service"] }
def notification-level-completer [] { ["default" "muted"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "configuration get" } } | get name | first)
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

# Fetch the global configuration of conversations on your account
#
# GET /v1/Configuration
# operationId: FetchConfiguration
export def "configuration get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, default_chat_service_sid: string, default_closed_timer: string, default_inactive_timer: string, default_messaging_service_sid: string, links: record, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base "/v1/Configuration")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the global configuration of conversations on your account
#
# POST /v1/Configuration
# operationId: UpdateConfiguration
export def "configuration update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-chat-service-sid: string # The SID of the default [Conversation Service](https://www.twilio.com/docs/conversations/api/service-resource) to use when creating a conversation.
  --default-closed-timer: string # Default ISO8601 duration when conversation will be switched to `closed` state. Minimum value for this timer is 10 minutes.
  --default-inactive-timer: string # Default ISO8601 duration when conversation will be switched to `inactive` state. Minimum value for this timer is 1 minute.
  --default-messaging-service-sid: string # The SID of the default [Messaging Service](https://www.twilio.com/docs/sms/services/api) to use when creating a conversation.
]: any -> record<account_sid: string, default_chat_service_sid: string, default_closed_timer: string, default_inactive_timer: string, default_messaging_service_sid: string, links: record, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base "/v1/Configuration")
  let req_body = {"DefaultChatServiceSid": $default_chat_service_sid, "DefaultClosedTimer": $default_closed_timer, "DefaultInactiveTimer": $default_inactive_timer, "DefaultMessagingServiceSid": $default_messaging_service_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Retrieve a list of address configurations for an account
#
# GET /v1/Configuration/Addresses
# operationId: ListConfigurationAddress
export def "configuration-addresses list-address" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string # Filter the address configurations by its type. This value can be one of: `whatsapp`, `sms`.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<address_configurations: table<account_sid: string, address: string, auto_creation: any, date_created: string, date_updated: string, friendly_name: string, sid: string, type: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "Type" $type "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Configuration/Addresses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new address configuration
#
# POST /v1/Configuration/Addresses
# operationId: CreateConfigurationAddress
export def "configuration-addresses create-address" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  address: string # The unique address to be configured. The address can be a whatsapp address or phone number
  --auto-creation-conversation-service-sid: string # Conversation Service for the auto-created conversation. If not set, the conversation is created in the default service.
  --auto-creation-enabled: oneof<nothing, bool> # Enable/Disable auto-creating conversations for messages to this address
  --auto-creation-studio-flow-sid: string # For type `studio`, the studio flow SID where the webhook should be sent to.
  --auto-creation-studio-retry-count: int # For type `studio`, number of times to retry the webhook request
  --auto-creation-type: string@auto-creation-type-completer
  --auto-creation-webhook-filters: list<string> # The list of events, firing webhook event for this Conversation. Values can be any of the following: `onMessageAdded`, `onMessageUpdated`, `onMessageRemoved`, `onConversationUpdated`, `onConversationStateUpdated`, `onConversationRemoved`, `onParticipantAdded`, `onParticipantUpdated`, `onParticipantRemoved`, `onDeliveryUpdated`
  --auto-creation-webhook-method: string@auto-creation-webhook-method-completer
  --auto-creation-webhook-url: string # For type `webhook`, the url for the webhook request.
  --friendly-name: string # The human-readable name of this configuration, limited to 256 characters. Optional.
  type: string@type-completer
]: any -> record<account_sid: string, address: string, auto_creation: any, date_created: string, date_updated: string, friendly_name: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base "/v1/Configuration/Addresses")
  let req_body = {"Address": $address, "AutoCreation.ConversationServiceSid": $auto_creation_conversation_service_sid, "AutoCreation.Enabled": $auto_creation_enabled, "AutoCreation.StudioFlowSid": $auto_creation_studio_flow_sid, "AutoCreation.StudioRetryCount": $auto_creation_studio_retry_count, "AutoCreation.Type": $auto_creation_type, "AutoCreation.WebhookFilters": $auto_creation_webhook_filters, "AutoCreation.WebhookMethod": $auto_creation_webhook_method, "AutoCreation.WebhookUrl": $auto_creation_webhook_url, "FriendlyName": $friendly_name, "Type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Remove an existing address configuration
#
# DELETE /v1/Configuration/Addresses/{Sid}
# operationId: DeleteConfigurationAddress
export def "configuration-addresses delete-address" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Configuration/Addresses/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch an address configuration
#
# GET /v1/Configuration/Addresses/{Sid}
# operationId: FetchConfigurationAddress
export def "configuration-addresses get-address" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, address: string, auto_creation: any, date_created: string, date_updated: string, friendly_name: string, sid: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Configuration/Addresses/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing address configuration
#
# POST /v1/Configuration/Addresses/{Sid}
# operationId: UpdateConfigurationAddress
export def "configuration-addresses update-address" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --auto-creation-conversation-service-sid: string # Conversation Service for the auto-created conversation. If not set, the conversation is created in the default service.
  --auto-creation-enabled: oneof<nothing, bool> # Enable/Disable auto-creating conversations for messages to this address
  --auto-creation-studio-flow-sid: string # For type `studio`, the studio flow SID where the webhook should be sent to.
  --auto-creation-studio-retry-count: int # For type `studio`, number of times to retry the webhook request
  --auto-creation-type: string@auto-creation-type-completer
  --auto-creation-webhook-filters: list<string> # The list of events, firing webhook event for this Conversation. Values can be any of the following: `onMessageAdded`, `onMessageUpdated`, `onMessageRemoved`, `onConversationUpdated`, `onConversationStateUpdated`, `onConversationRemoved`, `onParticipantAdded`, `onParticipantUpdated`, `onParticipantRemoved`, `onDeliveryUpdated`
  --auto-creation-webhook-method: string@auto-creation-webhook-method-completer
  --auto-creation-webhook-url: string # For type `webhook`, the url for the webhook request.
  --friendly-name: string # The human-readable name of this configuration, limited to 256 characters. Optional.
]: any -> record<account_sid: string, address: string, auto_creation: any, date_created: string, date_updated: string, friendly_name: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Configuration/Addresses/{sid}"))
  let req_body = {"AutoCreation.ConversationServiceSid": $auto_creation_conversation_service_sid, "AutoCreation.Enabled": $auto_creation_enabled, "AutoCreation.StudioFlowSid": $auto_creation_studio_flow_sid, "AutoCreation.StudioRetryCount": $auto_creation_studio_retry_count, "AutoCreation.Type": $auto_creation_type, "AutoCreation.WebhookFilters": $auto_creation_webhook_filters, "AutoCreation.WebhookMethod": $auto_creation_webhook_method, "AutoCreation.WebhookUrl": $auto_creation_webhook_url, "FriendlyName": $friendly_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# GET /v1/Configuration/Webhooks
#
# operationId: FetchConfigurationWebhook
export def "configuration-webhooks get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, filters: list<string>, method: string, post_webhook_url: string, pre_webhook_url: string, target: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base "/v1/Configuration/Webhooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /v1/Configuration/Webhooks
#
# operationId: UpdateConfigurationWebhook
export def "configuration-webhooks update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list<string> # The list of webhook event triggers that are enabled for this Service: `onMessageAdded`, `onMessageUpdated`, `onMessageRemoved`, `onConversationUpdated`, `onConversationRemoved`, `onParticipantAdded`, `onParticipantUpdated`, `onParticipantRemoved`
  --method: string # The HTTP method to be used when sending a webhook request.
  --post-webhook-url: string # The absolute url the post-event webhook request should be sent to.
  --pre-webhook-url: string # The absolute url the pre-event webhook request should be sent to.
  --target: string@target-completer
]: any -> record<account_sid: string, filters: list<string>, method: string, post_webhook_url: string, pre_webhook_url: string, target: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base "/v1/Configuration/Webhooks")
  let req_body = {"Filters": $filters, "Method": $method, "PostWebhookUrl": $post_webhook_url, "PreWebhookUrl": $pre_webhook_url, "Target": $target} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Retrieve a list of conversations in your account's default service
#
# GET /v1/Conversations
# operationId: ListConversation
export def "conversations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Start date or time in ISO8601 format for filtering list of Conversations. If a date is provided, the start time of the date is used (YYYY-MM-DDT00:00:00Z). Can be combined with other filters.
  --end-date: string # End date or time in ISO8601 format for filtering list of Conversations. If a date is provided, the end time of the date is used (YYYY-MM-DDT23:59:59Z). Can be combined with other filters.
  --state: string@state-completer # State for sorting and filtering list of Conversations. Can be `active`, `inactive` or `closed`
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<conversations: table<account_sid: string, attributes: string, bindings: any, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, messaging_service_sid: string, sid: string, state: string, timers: any, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "StartDate" $start_date "scalar") (serialize-qp "EndDate" $end_date "scalar") (serialize-qp "State" $state "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Conversations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new conversation in your account's default service
#
# POST /v1/Conversations
# operationId: CreateConversation
export def "conversations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # An optional string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified. **Note** that if the attributes are not set "{}" will be returned.
  --date-created: string # The date that this resource was created. (format: date-time)
  --date-updated: string # The date that this resource was last updated. (format: date-time)
  --friendly-name: string # The human-readable name of this conversation, limited to 256 characters. Optional.
  --messaging-service-sid: string # The unique ID of the [Messaging Service](https://www.twilio.com/docs/sms/services/api) this conversation belongs to.
  --state: string@state-completer
  --timers-closed: string # ISO8601 duration when conversation will be switched to `closed` state. Minimum value for this timer is 10 minutes.
  --timers-inactive: string # ISO8601 duration when conversation will be switched to `inactive` state. Minimum value for this timer is 1 minute.
  --unique-name: string # An application-defined string that uniquely identifies the resource. It can be used to address the resource in place of the resource's `sid` in the URL.
]: any -> record<account_sid: string, attributes: string, bindings: any, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, messaging_service_sid: string, sid: string, state: string, timers: any, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base "/v1/Conversations")
  let req_body = {"Attributes": $attributes, "DateCreated": $date_created, "DateUpdated": $date_updated, "FriendlyName": $friendly_name, "MessagingServiceSid": $messaging_service_sid, "State": $state, "Timers.Closed": $timers_closed, "Timers.Inactive": $timers_inactive, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Retrieve a list of all messages in the conversation
#
# GET /v1/Conversations/{ConversationSid}/Messages
# operationId: ListConversationMessage
export def "conversations-messages list" [
  conversation_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string@order-completer # The sort order of the returned messages. Can be: `asc` (ascending) or `desc` (descending), with `asc` as the default.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<messages: table<account_sid: string, attributes: string, author: string, body: string, content_sid: string, conversation_sid: string, date_created: string, date_updated: string, delivery: any, index: int, links: record, media: list, participant_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "Order" $order "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({conversation_sid: (encode-path-segment $conversation_sid)} | format pattern "/v1/Conversations/{conversation_sid}/Messages") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a new message to the conversation
#
# POST /v1/Conversations/{ConversationSid}/Messages
# operationId: CreateConversationMessage
export def "conversations-messages create" [
  conversation_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # A string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified. **Note** that if the attributes are not set "{}" will be returned.
  --author: string # The channel specific identifier of the message's author. Defaults to `system`.
  --body: string # The content of the message, can be up to 1,600 characters long.
  --content-sid: string # The unique ID of the multi-channel [Rich Content](https://www.twilio.com/docs/content-api) template, required for template-generated messages. **Note** that if this field is set, `Body` and `MediaSid` parameters are ignored.
  --content-variables: string # A structurally valid JSON string that contains values to resolve Rich Content template variables.
  --date-created: string # The date that this resource was created. (format: date-time)
  --date-updated: string # The date that this resource was last updated. `null` if the message has not been edited. (format: date-time)
  --media-sid: string # The Media SID to be attached to the new Message.
]: any -> record<account_sid: string, attributes: string, author: string, body: string, content_sid: string, conversation_sid: string, date_created: string, date_updated: string, delivery: any, index: int, links: record, media: list<any>, participant_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({conversation_sid: (encode-path-segment $conversation_sid)} | format pattern "/v1/Conversations/{conversation_sid}/Messages"))
  let req_body = {"Attributes": $attributes, "Author": $author, "Body": $body, "ContentSid": $content_sid, "ContentVariables": $content_variables, "DateCreated": $date_created, "DateUpdated": $date_updated, "MediaSid": $media_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Retrieve a list of all delivery and read receipts of the conversation message
#
# GET /v1/Conversations/{ConversationSid}/Messages/{MessageSid}/Receipts
# operationId: ListConversationMessageReceipt
export def "conversations-messages-receipts list" [
  conversation_sid: string
  message_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<delivery_receipts: table<account_sid: string, channel_message_sid: string, conversation_sid: string, date_created: string, date_updated: string, error_code: int, message_sid: string, participant_sid: string, sid: string, status: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({conversation_sid: (encode-path-segment $conversation_sid), message_sid: (encode-path-segment $message_sid)} | format pattern "/v1/Conversations/{conversation_sid}/Messages/{message_sid}/Receipts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch the delivery and read receipts of the conversation message
#
# GET /v1/Conversations/{ConversationSid}/Messages/{MessageSid}/Receipts/{Sid}
# operationId: FetchConversationMessageReceipt
export def "conversations-messages-receipts get" [
  conversation_sid: string
  message_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, channel_message_sid: string, conversation_sid: string, date_created: string, date_updated: string, error_code: int, message_sid: string, participant_sid: string, sid: string, status: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({conversation_sid: (encode-path-segment $conversation_sid), message_sid: (encode-path-segment $message_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Conversations/{conversation_sid}/Messages/{message_sid}/Receipts/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a message from the conversation
#
# DELETE /v1/Conversations/{ConversationSid}/Messages/{Sid}
# operationId: DeleteConversationMessage
export def "conversations-messages delete" [
  conversation_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({conversation_sid: (encode-path-segment $conversation_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Conversations/{conversation_sid}/Messages/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a message from the conversation
#
# GET /v1/Conversations/{ConversationSid}/Messages/{Sid}
# operationId: FetchConversationMessage
export def "conversations-messages get" [
  conversation_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, attributes: string, author: string, body: string, content_sid: string, conversation_sid: string, date_created: string, date_updated: string, delivery: any, index: int, links: record, media: list<any>, participant_sid: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({conversation_sid: (encode-path-segment $conversation_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Conversations/{conversation_sid}/Messages/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing message in the conversation
#
# POST /v1/Conversations/{ConversationSid}/Messages/{Sid}
# operationId: UpdateConversationMessage
export def "conversations-messages update" [
  conversation_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # A string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified. **Note** that if the attributes are not set "{}" will be returned.
  --author: string # The channel specific identifier of the message's author. Defaults to `system`.
  --body: string # The content of the message, can be up to 1,600 characters long.
  --date-created: string # The date that this resource was created. (format: date-time)
  --date-updated: string # The date that this resource was last updated. `null` if the message has not been edited. (format: date-time)
]: any -> record<account_sid: string, attributes: string, author: string, body: string, content_sid: string, conversation_sid: string, date_created: string, date_updated: string, delivery: any, index: int, links: record, media: list<any>, participant_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({conversation_sid: (encode-path-segment $conversation_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Conversations/{conversation_sid}/Messages/{sid}"))
  let req_body = {"Attributes": $attributes, "Author": $author, "Body": $body, "DateCreated": $date_created, "DateUpdated": $date_updated} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Retrieve a list of all participants of the conversation
#
# GET /v1/Conversations/{ConversationSid}/Participants
# operationId: ListConversationParticipant
export def "conversations-participants list" [
  conversation_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, participants: table<account_sid: string, attributes: string, conversation_sid: string, date_created: string, date_updated: string, identity: string, last_read_message_index: int, last_read_timestamp: string, messaging_binding: any, role_sid: string, sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({conversation_sid: (encode-path-segment $conversation_sid)} | format pattern "/v1/Conversations/{conversation_sid}/Participants") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a new participant to the conversation
#
# POST /v1/Conversations/{ConversationSid}/Participants
# operationId: CreateConversationParticipant
export def "conversations-participants create" [
  conversation_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # An optional string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified. **Note** that if the attributes are not set "{}" will be returned.
  --date-created: string # The date that this resource was created. (format: date-time)
  --date-updated: string # The date that this resource was last updated. (format: date-time)
  --identity: string # A unique string identifier for the conversation participant as [Conversation User](https://www.twilio.com/docs/conversations/api/user-resource). This parameter is non-null if (and only if) the participant is using the Conversations SDK to communicate. Limited to 256 characters.
  --messaging-binding-address: string # The address of the participant's device, e.g. a phone or WhatsApp number. Together with the Proxy address, this determines a participant uniquely. This field (with proxy_address) is only null when the participant is interacting from an SDK endpoint (see the 'identity' field).
  --messaging-binding-projected-address: string # The address of the Twilio phone number that is used in Group MMS. Communication mask for the Conversation participant with Identity.
  --messaging-binding-proxy-address: string # The address of the Twilio phone number (or WhatsApp number) that the participant is in contact with. This field, together with participant address, is only null when the participant is interacting from an SDK endpoint (see the 'identity' field).
  --role-sid: string # The SID of a conversation-level [Role](https://www.twilio.com/docs/conversations/api/role-resource) to assign to the participant.
]: any -> record<account_sid: string, attributes: string, conversation_sid: string, date_created: string, date_updated: string, identity: string, last_read_message_index: int, last_read_timestamp: string, messaging_binding: any, role_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({conversation_sid: (encode-path-segment $conversation_sid)} | format pattern "/v1/Conversations/{conversation_sid}/Participants"))
  let req_body = {"Attributes": $attributes, "DateCreated": $date_created, "DateUpdated": $date_updated, "Identity": $identity, "MessagingBinding.Address": $messaging_binding_address, "MessagingBinding.ProjectedAddress": $messaging_binding_projected_address, "MessagingBinding.ProxyAddress": $messaging_binding_proxy_address, "RoleSid": $role_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Remove a participant from the conversation
#
# DELETE /v1/Conversations/{ConversationSid}/Participants/{Sid}
# operationId: DeleteConversationParticipant
export def "conversations-participants delete" [
  conversation_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({conversation_sid: (encode-path-segment $conversation_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Conversations/{conversation_sid}/Participants/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a participant of the conversation
#
# GET /v1/Conversations/{ConversationSid}/Participants/{Sid}
# operationId: FetchConversationParticipant
export def "conversations-participants get" [
  conversation_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, attributes: string, conversation_sid: string, date_created: string, date_updated: string, identity: string, last_read_message_index: int, last_read_timestamp: string, messaging_binding: any, role_sid: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({conversation_sid: (encode-path-segment $conversation_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Conversations/{conversation_sid}/Participants/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing participant in the conversation
#
# POST /v1/Conversations/{ConversationSid}/Participants/{Sid}
# operationId: UpdateConversationParticipant
export def "conversations-participants update" [
  conversation_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # An optional string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified. **Note** that if the attributes are not set "{}" will be returned.
  --date-created: string # The date that this resource was created. (format: date-time)
  --date-updated: string # The date that this resource was last updated. (format: date-time)
  --identity: string # A unique string identifier for the conversation participant as [Conversation User](https://www.twilio.com/docs/conversations/api/user-resource). This parameter is non-null if (and only if) the participant is using the Conversations SDK to communicate. Limited to 256 characters.
  --last-read-message-index: int # Index of last “read” message in the [Conversation](https://www.twilio.com/docs/conversations/api/conversation-resource) for the Participant. (nullable)
  --last-read-timestamp: string # Timestamp of last “read” message in the [Conversation](https://www.twilio.com/docs/conversations/api/conversation-resource) for the Participant.
  --messaging-binding-projected-address: string # The address of the Twilio phone number that is used in Group MMS. 'null' value will remove it.
  --messaging-binding-proxy-address: string # The address of the Twilio phone number that the participant is in contact with. 'null' value will remove it.
  --role-sid: string # The SID of a conversation-level [Role](https://www.twilio.com/docs/conversations/api/role-resource) to assign to the participant.
]: any -> record<account_sid: string, attributes: string, conversation_sid: string, date_created: string, date_updated: string, identity: string, last_read_message_index: int, last_read_timestamp: string, messaging_binding: any, role_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({conversation_sid: (encode-path-segment $conversation_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Conversations/{conversation_sid}/Participants/{sid}"))
  let req_body = {"Attributes": $attributes, "DateCreated": $date_created, "DateUpdated": $date_updated, "Identity": $identity, "LastReadMessageIndex": $last_read_message_index, "LastReadTimestamp": $last_read_timestamp, "MessagingBinding.ProjectedAddress": $messaging_binding_projected_address, "MessagingBinding.ProxyAddress": $messaging_binding_proxy_address, "RoleSid": $role_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Retrieve a list of all webhooks scoped to the conversation
#
# GET /v1/Conversations/{ConversationSid}/Webhooks
# operationId: ListConversationScopedWebhook
export def "conversations-webhooks list" [
  conversation_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, webhooks: table<account_sid: string, configuration: any, conversation_sid: string, date_created: string, date_updated: string, sid: string, target: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({conversation_sid: (encode-path-segment $conversation_sid)} | format pattern "/v1/Conversations/{conversation_sid}/Webhooks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new webhook scoped to the conversation
#
# POST /v1/Conversations/{ConversationSid}/Webhooks
# operationId: CreateConversationScopedWebhook
export def "conversations-webhooks create" [
  conversation_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --configuration-filters: list<string> # The list of events, firing webhook event for this Conversation.
  --configuration-flow-sid: string # The studio flow SID, where the webhook should be sent to.
  --configuration-method: string@configuration-method-completer
  --configuration-replay-after: int # The message index for which and it's successors the webhook will be replayed. Not set by default
  --configuration-triggers: list<string> # The list of keywords, firing webhook event for this Conversation.
  --configuration-url: string # The absolute url the webhook request should be sent to.
  target: string@target-completer-1
]: any -> record<account_sid: string, configuration: any, conversation_sid: string, date_created: string, date_updated: string, sid: string, target: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({conversation_sid: (encode-path-segment $conversation_sid)} | format pattern "/v1/Conversations/{conversation_sid}/Webhooks"))
  let req_body = {"Configuration.Filters": $configuration_filters, "Configuration.FlowSid": $configuration_flow_sid, "Configuration.Method": $configuration_method, "Configuration.ReplayAfter": $configuration_replay_after, "Configuration.Triggers": $configuration_triggers, "Configuration.Url": $configuration_url, "Target": $target} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Remove an existing webhook scoped to the conversation
#
# DELETE /v1/Conversations/{ConversationSid}/Webhooks/{Sid}
# operationId: DeleteConversationScopedWebhook
export def "conversations-webhooks delete" [
  conversation_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({conversation_sid: (encode-path-segment $conversation_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Conversations/{conversation_sid}/Webhooks/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch the configuration of a conversation-scoped webhook
#
# GET /v1/Conversations/{ConversationSid}/Webhooks/{Sid}
# operationId: FetchConversationScopedWebhook
export def "conversations-webhooks get" [
  conversation_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, configuration: any, conversation_sid: string, date_created: string, date_updated: string, sid: string, target: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({conversation_sid: (encode-path-segment $conversation_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Conversations/{conversation_sid}/Webhooks/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing conversation-scoped webhook
#
# POST /v1/Conversations/{ConversationSid}/Webhooks/{Sid}
# operationId: UpdateConversationScopedWebhook
export def "conversations-webhooks update" [
  conversation_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --configuration-filters: list<string> # The list of events, firing webhook event for this Conversation.
  --configuration-flow-sid: string # The studio flow SID, where the webhook should be sent to.
  --configuration-method: string@configuration-method-completer
  --configuration-triggers: list<string> # The list of keywords, firing webhook event for this Conversation.
  --configuration-url: string # The absolute url the webhook request should be sent to.
]: any -> record<account_sid: string, configuration: any, conversation_sid: string, date_created: string, date_updated: string, sid: string, target: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({conversation_sid: (encode-path-segment $conversation_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Conversations/{conversation_sid}/Webhooks/{sid}"))
  let req_body = {"Configuration.Filters": $configuration_filters, "Configuration.FlowSid": $configuration_flow_sid, "Configuration.Method": $configuration_method, "Configuration.Triggers": $configuration_triggers, "Configuration.Url": $configuration_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Remove a conversation from your account's default service
#
# DELETE /v1/Conversations/{Sid}
# operationId: DeleteConversation
export def "conversations delete" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Conversations/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a conversation from your account's default service
#
# GET /v1/Conversations/{Sid}
# operationId: FetchConversation
export def "conversations get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, attributes: string, bindings: any, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, messaging_service_sid: string, sid: string, state: string, timers: any, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Conversations/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing conversation in your account's default service
#
# POST /v1/Conversations/{Sid}
# operationId: UpdateConversation
export def "conversations update" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # An optional string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified. **Note** that if the attributes are not set "{}" will be returned.
  --date-created: string # The date that this resource was created. (format: date-time)
  --date-updated: string # The date that this resource was last updated. (format: date-time)
  --friendly-name: string # The human-readable name of this conversation, limited to 256 characters. Optional.
  --messaging-service-sid: string # The unique ID of the [Messaging Service](https://www.twilio.com/docs/sms/services/api) this conversation belongs to.
  --state: string@state-completer
  --timers-closed: string # ISO8601 duration when conversation will be switched to `closed` state. Minimum value for this timer is 10 minutes.
  --timers-inactive: string # ISO8601 duration when conversation will be switched to `inactive` state. Minimum value for this timer is 1 minute.
  --unique-name: string # An application-defined string that uniquely identifies the resource. It can be used to address the resource in place of the resource's `sid` in the URL.
]: any -> record<account_sid: string, attributes: string, bindings: any, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, messaging_service_sid: string, sid: string, state: string, timers: any, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Conversations/{sid}"))
  let req_body = {"Attributes": $attributes, "DateCreated": $date_created, "DateUpdated": $date_updated, "FriendlyName": $friendly_name, "MessagingServiceSid": $messaging_service_sid, "State": $state, "Timers.Closed": $timers_closed, "Timers.Inactive": $timers_inactive, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Retrieve a list of all push notification credentials on your account
#
# GET /v1/Credentials
# operationId: ListCredential
export def "credentials list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<credentials: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sandbox: string, sid: string, type: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Credentials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a new push notification credential to your account
#
# POST /v1/Credentials
# operationId: CreateCredential
export def "credentials create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # [GCM only] The API key for the project that was obtained from the Google Developer console for your GCM Service application credential.
  --certificate: string # [APN only] The URL encoded representation of the certificate. For example, `-----BEGIN CERTIFICATE----- MIIFnTCCBIWgAwIBAgIIAjy9H849+E8wDQYJKoZIhvcNAQEF.....A== -----END CERTIFICATE-----`.
  --friendly-name: string # A descriptive string that you create to describe the new resource. It can be up to 64 characters long.
  --private-key: string # [APN only] The URL encoded representation of the private key. For example, `-----BEGIN RSA PRIVATE KEY----- MIIEpQIBAAKCAQEAuyf/lNrH9ck8DmNyo3fG... -----END RSA PRIVATE KEY-----`.
  --sandbox: oneof<nothing, bool> # [APN only] Whether to send the credential to sandbox APNs. Can be `true` to send to sandbox APNs or `false` to send to production.
  --secret: string # [FCM only] The **Server key** of your project from the Firebase console, found under Settings / Cloud messaging.
  type: string@type-completer-1
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sandbox: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base "/v1/Credentials")
  let req_body = {"ApiKey": $api_key, "Certificate": $certificate, "FriendlyName": $friendly_name, "PrivateKey": $private_key, "Sandbox": $sandbox, "Secret": $secret, "Type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Remove a push notification credential from your account
#
# DELETE /v1/Credentials/{Sid}
# operationId: DeleteCredential
export def "credentials delete" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Credentials/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a push notification credential from your account
#
# GET /v1/Credentials/{Sid}
# operationId: FetchCredential
export def "credentials get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sandbox: string, sid: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Credentials/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing push notification credential on your account
#
# POST /v1/Credentials/{Sid}
# operationId: UpdateCredential
export def "credentials update" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-key: string # [GCM only] The API key for the project that was obtained from the Google Developer console for your GCM Service application credential.
  --certificate: string # [APN only] The URL encoded representation of the certificate. For example, `-----BEGIN CERTIFICATE----- MIIFnTCCBIWgAwIBAgIIAjy9H849+E8wDQYJKoZIhvcNAQEF.....A== -----END CERTIFICATE-----`.
  --friendly-name: string # A descriptive string that you create to describe the new resource. It can be up to 64 characters long.
  --private-key: string # [APN only] The URL encoded representation of the private key. For example, `-----BEGIN RSA PRIVATE KEY----- MIIEpQIBAAKCAQEAuyf/lNrH9ck8DmNyo3fG... -----END RSA PRIVATE KEY-----`.
  --sandbox: oneof<nothing, bool> # [APN only] Whether to send the credential to sandbox APNs. Can be `true` to send to sandbox APNs or `false` to send to production.
  --secret: string # [FCM only] The **Server key** of your project from the Firebase console, found under Settings / Cloud messaging.
  --type: string@type-completer-1
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, sandbox: string, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Credentials/{sid}"))
  let req_body = {"ApiKey": $api_key, "Certificate": $certificate, "FriendlyName": $friendly_name, "PrivateKey": $private_key, "Sandbox": $sandbox, "Secret": $secret, "Type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Retrieve a list of all Conversations that this Participant belongs to by identity or by address. Only one parameter should be specified.
#
# GET /v1/ParticipantConversations
# operationId: ListParticipantConversation
export def "participant-conversations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --identity: string # A unique string identifier for the conversation participant as [Conversation User](https://www.twilio.com/docs/conversations/api/user-resource). This parameter is non-null if (and only if) the participant is using the Conversations SDK to communicate. Limited to 256 characters.
  --address: string # A unique string identifier for the conversation participant who's not a Conversation User. This parameter could be found in messaging_binding.address field of Participant resource. It should be url-encoded.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<conversations: table<account_sid: string, chat_service_sid: string, conversation_attributes: string, conversation_created_by: string, conversation_date_created: string, conversation_date_updated: string, conversation_friendly_name: string, conversation_sid: string, conversation_state: string, conversation_timers: any, conversation_unique_name: string, links: record, participant_identity: string, participant_messaging_binding: any, participant_sid: string, participant_user_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "Identity" $identity "scalar") (serialize-qp "Address" $address "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/ParticipantConversations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of all user roles in your account's default service
#
# GET /v1/Roles
# operationId: ListRole
export def "roles list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, roles: table<account_sid: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list, sid: string, type: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new user role in your account's default service
#
# POST /v1/Roles
# operationId: CreateRole
export def "roles create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  friendly_name: string # A descriptive string that you create to describe the new resource. It can be up to 64 characters long.
  permission: list<string> # A permission that you grant to the new role. Only one permission can be granted per parameter. To assign more than one permission, repeat this parameter for each permission value. The values for this parameter depend on the role's `type`.
  type: string@type-completer-2
]: any -> record<account_sid: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base "/v1/Roles")
  let req_body = {"FriendlyName": $friendly_name, "Permission": $permission, "Type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Remove a user role from your account's default service
#
# DELETE /v1/Roles/{Sid}
# operationId: DeleteRole
export def "roles delete" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Roles/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a user role from your account's default service
#
# GET /v1/Roles/{Sid}
# operationId: FetchRole
export def "roles get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, sid: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Roles/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing user role in your account's default service
#
# POST /v1/Roles/{Sid}
# operationId: UpdateRole
export def "roles update" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  permission: list<string> # A permission that you grant to the role. Only one permission can be granted per parameter. To assign more than one permission, repeat this parameter for each permission value. Note that the update action replaces all previously assigned permissions with those defined in the update action. To remove a permission, do not include it in the subsequent update action. The values for this parameter depend on the role's `type`.
]: any -> record<account_sid: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Roles/{sid}"))
  let req_body = {"Permission": $permission} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Retrieve a list of all conversation services on your account
#
# GET /v1/Services
# operationId: ListService
export def "services list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, services: table<account_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new conversation service on your account
#
# POST /v1/Services
# operationId: CreateService
export def "services create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  friendly_name: string # The human-readable name of this service, limited to 256 characters. Optional.
]: any -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base "/v1/Services")
  let req_body = {"FriendlyName": $friendly_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Retrieve a list of all push notification bindings in the conversation service
#
# GET /v1/Services/{ChatServiceSid}/Bindings
# operationId: ListServiceBinding
export def "services-bindings list" [
  chat_service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --binding-type: list<string> # The push technology used by the Binding resources to read. Can be: `apn`, `gcm`, or `fcm`. See [push notification configuration](https://www.twilio.com/docs/chat/push-notification-configuration) for more info.
  --identity: list<string> # The identity of a [Conversation User](https://www.twilio.com/docs/conversations/api/user-resource) this binding belongs to. See [access tokens](https://www.twilio.com/docs/conversations/create-tokens) for more details.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<bindings: table<account_sid: string, binding_type: string, chat_service_sid: string, credential_sid: string, date_created: string, date_updated: string, endpoint: string, identity: string, message_types: list, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "BindingType" $binding_type "multi") (serialize-qp "Identity" $identity "multi") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid)} | format pattern "/v1/Services/{chat_service_sid}/Bindings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a push notification binding from the conversation service
#
# DELETE /v1/Services/{ChatServiceSid}/Bindings/{Sid}
# operationId: DeleteServiceBinding
export def "services-bindings delete" [
  chat_service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{chat_service_sid}/Bindings/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a push notification binding from the conversation service
#
# GET /v1/Services/{ChatServiceSid}/Bindings/{Sid}
# operationId: FetchServiceBinding
export def "services-bindings get" [
  chat_service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, binding_type: string, chat_service_sid: string, credential_sid: string, date_created: string, date_updated: string, endpoint: string, identity: string, message_types: list<string>, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{chat_service_sid}/Bindings/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch the configuration of a conversation service
#
# GET /v1/Services/{ChatServiceSid}/Configuration
# operationId: FetchServiceConfiguration
export def "services-configuration get" [
  chat_service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<chat_service_sid: string, default_chat_service_role_sid: string, default_conversation_creator_role_sid: string, default_conversation_role_sid: string, links: record, reachability_enabled: bool, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid)} | format pattern "/v1/Services/{chat_service_sid}/Configuration"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update configuration settings of a conversation service
#
# POST /v1/Services/{ChatServiceSid}/Configuration
# operationId: UpdateServiceConfiguration
export def "services-configuration update" [
  chat_service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --default-chat-service-role-sid: string # The service-level role assigned to users when they are added to the service. See the [Conversation Role](https://www.twilio.com/docs/conversations/api/role-resource) for more info about roles.
  --default-conversation-creator-role-sid: string # The conversation-level role assigned to a conversation creator when they join a new conversation. See the [Conversation Role](https://www.twilio.com/docs/conversations/api/role-resource) for more info about roles.
  --default-conversation-role-sid: string # The conversation-level role assigned to users when they are added to a conversation. See the [Conversation Role](https://www.twilio.com/docs/conversations/api/role-resource) for more info about roles.
  --reachability-enabled: oneof<nothing, bool> # Whether the [Reachability Indicator](https://www.twilio.com/docs/chat/reachability-indicator) is enabled for this Conversations Service. The default is `false`.
]: any -> record<chat_service_sid: string, default_chat_service_role_sid: string, default_conversation_creator_role_sid: string, default_conversation_role_sid: string, links: record, reachability_enabled: bool, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid)} | format pattern "/v1/Services/{chat_service_sid}/Configuration"))
  let req_body = {"DefaultChatServiceRoleSid": $default_chat_service_role_sid, "DefaultConversationCreatorRoleSid": $default_conversation_creator_role_sid, "DefaultConversationRoleSid": $default_conversation_role_sid, "ReachabilityEnabled": $reachability_enabled} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Fetch push notification service settings
#
# GET /v1/Services/{ChatServiceSid}/Configuration/Notifications
# operationId: FetchServiceNotification
export def "services-configuration-notifications get" [
  chat_service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, added_to_conversation: any, chat_service_sid: string, log_enabled: bool, new_message: any, removed_from_conversation: any, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid)} | format pattern "/v1/Services/{chat_service_sid}/Configuration/Notifications"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update push notification service settings
#
# POST /v1/Services/{ChatServiceSid}/Configuration/Notifications
# operationId: UpdateServiceNotification
export def "services-configuration-notifications update" [
  chat_service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --added-to-conversation-enabled: oneof<nothing, bool> # Whether to send a notification when a participant is added to a conversation. The default is `false`.
  --added-to-conversation-sound: string # The name of the sound to play when a participant is added to a conversation and `added_to_conversation.enabled` is `true`.
  --added-to-conversation-template: string # The template to use to create the notification text displayed when a participant is added to a conversation and `added_to_conversation.enabled` is `true`.
  --log-enabled: oneof<nothing, bool> # Weather the notification logging is enabled.
  --new-message-badge-count-enabled: oneof<nothing, bool> # Whether the new message badge is enabled. The default is `false`.
  --new-message-enabled: oneof<nothing, bool> # Whether to send a notification when a new message is added to a conversation. The default is `false`.
  --new-message-sound: string # The name of the sound to play when a new message is added to a conversation and `new_message.enabled` is `true`.
  --new-message-template: string # The template to use to create the notification text displayed when a new message is added to a conversation and `new_message.enabled` is `true`.
  --new-message-with-media-enabled: oneof<nothing, bool> # Whether to send a notification when a new message with media/file attachments is added to a conversation. The default is `false`.
  --new-message-with-media-template: string # The template to use to create the notification text displayed when a new message with media/file attachments is added to a conversation and `new_message.attachments.enabled` is `true`.
  --removed-from-conversation-enabled: oneof<nothing, bool> # Whether to send a notification to a user when they are removed from a conversation. The default is `false`.
  --removed-from-conversation-sound: string # The name of the sound to play to a user when they are removed from a conversation and `removed_from_conversation.enabled` is `true`.
  --removed-from-conversation-template: string # The template to use to create the notification text displayed to a user when they are removed from a conversation and `removed_from_conversation.enabled` is `true`.
]: any -> record<account_sid: string, added_to_conversation: any, chat_service_sid: string, log_enabled: bool, new_message: any, removed_from_conversation: any, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid)} | format pattern "/v1/Services/{chat_service_sid}/Configuration/Notifications"))
  let req_body = {"AddedToConversation.Enabled": $added_to_conversation_enabled, "AddedToConversation.Sound": $added_to_conversation_sound, "AddedToConversation.Template": $added_to_conversation_template, "LogEnabled": $log_enabled, "NewMessage.BadgeCountEnabled": $new_message_badge_count_enabled, "NewMessage.Enabled": $new_message_enabled, "NewMessage.Sound": $new_message_sound, "NewMessage.Template": $new_message_template, "NewMessage.WithMedia.Enabled": $new_message_with_media_enabled, "NewMessage.WithMedia.Template": $new_message_with_media_template, "RemovedFromConversation.Enabled": $removed_from_conversation_enabled, "RemovedFromConversation.Sound": $removed_from_conversation_sound, "RemovedFromConversation.Template": $removed_from_conversation_template} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Fetch a specific service webhook configuration.
#
# GET /v1/Services/{ChatServiceSid}/Configuration/Webhooks
# operationId: FetchServiceWebhookConfiguration
export def "services-configuration-webhooks get" [
  chat_service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, chat_service_sid: string, filters: list<string>, method: string, post_webhook_url: string, pre_webhook_url: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid)} | format pattern "/v1/Services/{chat_service_sid}/Configuration/Webhooks"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a specific Webhook.
#
# POST /v1/Services/{ChatServiceSid}/Configuration/Webhooks
# operationId: UpdateServiceWebhookConfiguration
export def "services-configuration-webhooks update" [
  chat_service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filters: list<string> # The list of events that your configured webhook targets will receive. Events not configured here will not fire. Possible values are `onParticipantAdd`, `onParticipantAdded`, `onDeliveryUpdated`, `onConversationUpdated`, `onConversationRemove`, `onParticipantRemove`, `onConversationUpdate`, `onMessageAdd`, `onMessageRemoved`, `onParticipantUpdated`, `onConversationAdded`, `onMessageAdded`, `onConversationAdd`, `onConversationRemoved`, `onParticipantUpdate`, `onMessageRemove`, `onMessageUpdated`, `onParticipantRemoved`, `onMessageUpdate` or `onConversationStateUpdated`.
  --method: string # The HTTP method to be used when sending a webhook request. One of `GET` or `POST`.
  --post-webhook-url: string # The absolute url the post-event webhook request should be sent to. (format: uri)
  --pre-webhook-url: string # The absolute url the pre-event webhook request should be sent to. (format: uri)
]: any -> record<account_sid: string, chat_service_sid: string, filters: list<string>, method: string, post_webhook_url: string, pre_webhook_url: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid)} | format pattern "/v1/Services/{chat_service_sid}/Configuration/Webhooks"))
  let req_body = {"Filters": $filters, "Method": $method, "PostWebhookUrl": $post_webhook_url, "PreWebhookUrl": $pre_webhook_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Retrieve a list of conversations in your service
#
# GET /v1/Services/{ChatServiceSid}/Conversations
# operationId: ListServiceConversation
export def "services-conversations list" [
  chat_service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --start-date: string # Start date or time in ISO8601 format for filtering list of Conversations. If a date is provided, the start time of the date is used (YYYY-MM-DDT00:00:00Z). Can be combined with other filters.
  --end-date: string # End date or time in ISO8601 format for filtering list of Conversations. If a date is provided, the end time of the date is used (YYYY-MM-DDT23:59:59Z). Can be combined with other filters.
  --state: string@state-completer # State for sorting and filtering list of Conversations. Can be `active`, `inactive` or `closed`
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<conversations: table<account_sid: string, attributes: string, bindings: any, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, messaging_service_sid: string, sid: string, state: string, timers: any, unique_name: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "StartDate" $start_date "scalar") (serialize-qp "EndDate" $end_date "scalar") (serialize-qp "State" $state "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid)} | format pattern "/v1/Services/{chat_service_sid}/Conversations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new conversation in your service
#
# POST /v1/Services/{ChatServiceSid}/Conversations
# operationId: CreateServiceConversation
export def "services-conversations create" [
  chat_service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # An optional string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified. **Note** that if the attributes are not set "{}" will be returned.
  --date-created: string # The date that this resource was created. (format: date-time)
  --date-updated: string # The date that this resource was last updated. (format: date-time)
  --friendly-name: string # The human-readable name of this conversation, limited to 256 characters. Optional.
  --messaging-service-sid: string # The unique ID of the [Messaging Service](https://www.twilio.com/docs/sms/services/api) this conversation belongs to.
  --state: string@state-completer
  --timers-closed: string # ISO8601 duration when conversation will be switched to `closed` state. Minimum value for this timer is 10 minutes.
  --timers-inactive: string # ISO8601 duration when conversation will be switched to `inactive` state. Minimum value for this timer is 1 minute.
  --unique-name: string # An application-defined string that uniquely identifies the resource. It can be used to address the resource in place of the resource's `sid` in the URL.
]: any -> record<account_sid: string, attributes: string, bindings: any, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, messaging_service_sid: string, sid: string, state: string, timers: any, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid)} | format pattern "/v1/Services/{chat_service_sid}/Conversations"))
  let req_body = {"Attributes": $attributes, "DateCreated": $date_created, "DateUpdated": $date_updated, "FriendlyName": $friendly_name, "MessagingServiceSid": $messaging_service_sid, "State": $state, "Timers.Closed": $timers_closed, "Timers.Inactive": $timers_inactive, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Retrieve a list of all messages in the conversation
#
# GET /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Messages
# operationId: ListServiceConversationMessage
export def "services-conversations-messages list" [
  chat_service_sid: string
  conversation_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --order: string@order-completer # The sort order of the returned messages. Can be: `asc` (ascending) or `desc` (descending), with `asc` as the default.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<messages: table<account_sid: string, attributes: string, author: string, body: string, chat_service_sid: string, content_sid: string, conversation_sid: string, date_created: string, date_updated: string, delivery: any, index: int, links: record, media: list, participant_sid: string, sid: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "Order" $order "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid), conversation_sid: (encode-path-segment $conversation_sid)} | format pattern "/v1/Services/{chat_service_sid}/Conversations/{conversation_sid}/Messages") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a new message to the conversation in a specific service
#
# POST /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Messages
# operationId: CreateServiceConversationMessage
export def "services-conversations-messages create" [
  chat_service_sid: string
  conversation_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # A string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified. **Note** that if the attributes are not set "{}" will be returned.
  --author: string # The channel specific identifier of the message's author. Defaults to `system`.
  --body: string # The content of the message, can be up to 1,600 characters long.
  --content-sid: string # The unique ID of the multi-channel [Rich Content](https://www.twilio.com/docs/content-api) template, required for template-generated messages. **Note** that if this field is set, `Body` and `MediaSid` parameters are ignored.
  --content-variables: string # A structurally valid JSON string that contains values to resolve Rich Content template variables.
  --date-created: string # The date that this resource was created. (format: date-time)
  --date-updated: string # The date that this resource was last updated. `null` if the message has not been edited. (format: date-time)
  --media-sid: string # The Media SID to be attached to the new Message.
]: any -> record<account_sid: string, attributes: string, author: string, body: string, chat_service_sid: string, content_sid: string, conversation_sid: string, date_created: string, date_updated: string, delivery: any, index: int, links: record, media: list<any>, participant_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid), conversation_sid: (encode-path-segment $conversation_sid)} | format pattern "/v1/Services/{chat_service_sid}/Conversations/{conversation_sid}/Messages"))
  let req_body = {"Attributes": $attributes, "Author": $author, "Body": $body, "ContentSid": $content_sid, "ContentVariables": $content_variables, "DateCreated": $date_created, "DateUpdated": $date_updated, "MediaSid": $media_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Retrieve a list of all delivery and read receipts of the conversation message
#
# GET /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Messages/{MessageSid}/Receipts
# operationId: ListServiceConversationMessageReceipt
export def "services-conversations-messages-receipts list" [
  chat_service_sid: string
  conversation_sid: string
  message_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<delivery_receipts: table<account_sid: string, channel_message_sid: string, chat_service_sid: string, conversation_sid: string, date_created: string, date_updated: string, error_code: int, message_sid: string, participant_sid: string, sid: string, status: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid), conversation_sid: (encode-path-segment $conversation_sid), message_sid: (encode-path-segment $message_sid)} | format pattern "/v1/Services/{chat_service_sid}/Conversations/{conversation_sid}/Messages/{message_sid}/Receipts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch the delivery and read receipts of the conversation message
#
# GET /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Messages/{MessageSid}/Receipts/{Sid}
# operationId: FetchServiceConversationMessageReceipt
export def "services-conversations-messages-receipts get" [
  chat_service_sid: string
  conversation_sid: string
  message_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, channel_message_sid: string, chat_service_sid: string, conversation_sid: string, date_created: string, date_updated: string, error_code: int, message_sid: string, participant_sid: string, sid: string, status: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid), conversation_sid: (encode-path-segment $conversation_sid), message_sid: (encode-path-segment $message_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{chat_service_sid}/Conversations/{conversation_sid}/Messages/{message_sid}/Receipts/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Remove a message from the conversation
#
# DELETE /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Messages/{Sid}
# operationId: DeleteServiceConversationMessage
export def "services-conversations-messages delete" [
  chat_service_sid: string
  conversation_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid), conversation_sid: (encode-path-segment $conversation_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{chat_service_sid}/Conversations/{conversation_sid}/Messages/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a message from the conversation
#
# GET /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Messages/{Sid}
# operationId: FetchServiceConversationMessage
export def "services-conversations-messages get" [
  chat_service_sid: string
  conversation_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, attributes: string, author: string, body: string, chat_service_sid: string, content_sid: string, conversation_sid: string, date_created: string, date_updated: string, delivery: any, index: int, links: record, media: list<any>, participant_sid: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid), conversation_sid: (encode-path-segment $conversation_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{chat_service_sid}/Conversations/{conversation_sid}/Messages/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing message in the conversation
#
# POST /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Messages/{Sid}
# operationId: UpdateServiceConversationMessage
export def "services-conversations-messages update" [
  chat_service_sid: string
  conversation_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # A string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified. **Note** that if the attributes are not set "{}" will be returned.
  --author: string # The channel specific identifier of the message's author. Defaults to `system`.
  --body: string # The content of the message, can be up to 1,600 characters long.
  --date-created: string # The date that this resource was created. (format: date-time)
  --date-updated: string # The date that this resource was last updated. `null` if the message has not been edited. (format: date-time)
]: any -> record<account_sid: string, attributes: string, author: string, body: string, chat_service_sid: string, content_sid: string, conversation_sid: string, date_created: string, date_updated: string, delivery: any, index: int, links: record, media: list<any>, participant_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid), conversation_sid: (encode-path-segment $conversation_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{chat_service_sid}/Conversations/{conversation_sid}/Messages/{sid}"))
  let req_body = {"Attributes": $attributes, "Author": $author, "Body": $body, "DateCreated": $date_created, "DateUpdated": $date_updated} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Retrieve a list of all participants of the conversation
#
# GET /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Participants
# operationId: ListServiceConversationParticipant
export def "services-conversations-participants list" [
  chat_service_sid: string
  conversation_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, participants: table<account_sid: string, attributes: string, chat_service_sid: string, conversation_sid: string, date_created: string, date_updated: string, identity: string, last_read_message_index: int, last_read_timestamp: string, messaging_binding: any, role_sid: string, sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid), conversation_sid: (encode-path-segment $conversation_sid)} | format pattern "/v1/Services/{chat_service_sid}/Conversations/{conversation_sid}/Participants") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a new participant to the conversation in a specific service
#
# POST /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Participants
# operationId: CreateServiceConversationParticipant
export def "services-conversations-participants create" [
  chat_service_sid: string
  conversation_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # An optional string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified. **Note** that if the attributes are not set "{}" will be returned.
  --date-created: string # The date that this resource was created. (format: date-time)
  --date-updated: string # The date that this resource was last updated. (format: date-time)
  --identity: string # A unique string identifier for the conversation participant as [Conversation User](https://www.twilio.com/docs/conversations/api/user-resource). This parameter is non-null if (and only if) the participant is using the Conversation SDK to communicate. Limited to 256 characters.
  --messaging-binding-address: string # The address of the participant's device, e.g. a phone or WhatsApp number. Together with the Proxy address, this determines a participant uniquely. This field (with proxy_address) is only null when the participant is interacting from an SDK endpoint (see the 'identity' field).
  --messaging-binding-projected-address: string # The address of the Twilio phone number that is used in Group MMS. Communication mask for the Conversation participant with Identity.
  --messaging-binding-proxy-address: string # The address of the Twilio phone number (or WhatsApp number) that the participant is in contact with. This field, together with participant address, is only null when the participant is interacting from an SDK endpoint (see the 'identity' field).
  --role-sid: string # The SID of a conversation-level [Role](https://www.twilio.com/docs/conversations/api/role-resource) to assign to the participant.
]: any -> record<account_sid: string, attributes: string, chat_service_sid: string, conversation_sid: string, date_created: string, date_updated: string, identity: string, last_read_message_index: int, last_read_timestamp: string, messaging_binding: any, role_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid), conversation_sid: (encode-path-segment $conversation_sid)} | format pattern "/v1/Services/{chat_service_sid}/Conversations/{conversation_sid}/Participants"))
  let req_body = {"Attributes": $attributes, "DateCreated": $date_created, "DateUpdated": $date_updated, "Identity": $identity, "MessagingBinding.Address": $messaging_binding_address, "MessagingBinding.ProjectedAddress": $messaging_binding_projected_address, "MessagingBinding.ProxyAddress": $messaging_binding_proxy_address, "RoleSid": $role_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Remove a participant from the conversation
#
# DELETE /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Participants/{Sid}
# operationId: DeleteServiceConversationParticipant
export def "services-conversations-participants delete" [
  chat_service_sid: string
  conversation_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid), conversation_sid: (encode-path-segment $conversation_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{chat_service_sid}/Conversations/{conversation_sid}/Participants/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a participant of the conversation
#
# GET /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Participants/{Sid}
# operationId: FetchServiceConversationParticipant
export def "services-conversations-participants get" [
  chat_service_sid: string
  conversation_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, attributes: string, chat_service_sid: string, conversation_sid: string, date_created: string, date_updated: string, identity: string, last_read_message_index: int, last_read_timestamp: string, messaging_binding: any, role_sid: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid), conversation_sid: (encode-path-segment $conversation_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{chat_service_sid}/Conversations/{conversation_sid}/Participants/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing participant in the conversation
#
# POST /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Participants/{Sid}
# operationId: UpdateServiceConversationParticipant
export def "services-conversations-participants update" [
  chat_service_sid: string
  conversation_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # An optional string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified. **Note** that if the attributes are not set "{}" will be returned.
  --date-created: string # The date that this resource was created. (format: date-time)
  --date-updated: string # The date that this resource was last updated. (format: date-time)
  --identity: string # A unique string identifier for the conversation participant as [Conversation User](https://www.twilio.com/docs/conversations/api/user-resource). This parameter is non-null if (and only if) the participant is using the Conversation SDK to communicate. Limited to 256 characters.
  --last-read-message-index: int # Index of last “read” message in the [Conversation](https://www.twilio.com/docs/conversations/api/conversation-resource) for the Participant. (nullable)
  --last-read-timestamp: string # Timestamp of last “read” message in the [Conversation](https://www.twilio.com/docs/conversations/api/conversation-resource) for the Participant.
  --messaging-binding-projected-address: string # The address of the Twilio phone number that is used in Group MMS. 'null' value will remove it.
  --messaging-binding-proxy-address: string # The address of the Twilio phone number that the participant is in contact with. 'null' value will remove it.
  --role-sid: string # The SID of a conversation-level [Role](https://www.twilio.com/docs/conversations/api/role-resource) to assign to the participant.
]: any -> record<account_sid: string, attributes: string, chat_service_sid: string, conversation_sid: string, date_created: string, date_updated: string, identity: string, last_read_message_index: int, last_read_timestamp: string, messaging_binding: any, role_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid), conversation_sid: (encode-path-segment $conversation_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{chat_service_sid}/Conversations/{conversation_sid}/Participants/{sid}"))
  let req_body = {"Attributes": $attributes, "DateCreated": $date_created, "DateUpdated": $date_updated, "Identity": $identity, "LastReadMessageIndex": $last_read_message_index, "LastReadTimestamp": $last_read_timestamp, "MessagingBinding.ProjectedAddress": $messaging_binding_projected_address, "MessagingBinding.ProxyAddress": $messaging_binding_proxy_address, "RoleSid": $role_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Retrieve a list of all webhooks scoped to the conversation
#
# GET /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Webhooks
# operationId: ListServiceConversationScopedWebhook
export def "services-conversations-webhooks list" [
  chat_service_sid: string
  conversation_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, webhooks: table<account_sid: string, chat_service_sid: string, configuration: any, conversation_sid: string, date_created: string, date_updated: string, sid: string, target: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid), conversation_sid: (encode-path-segment $conversation_sid)} | format pattern "/v1/Services/{chat_service_sid}/Conversations/{conversation_sid}/Webhooks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new webhook scoped to the conversation in a specific service
#
# POST /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Webhooks
# operationId: CreateServiceConversationScopedWebhook
export def "services-conversations-webhooks create" [
  chat_service_sid: string
  conversation_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --configuration-filters: list<string> # The list of events, firing webhook event for this Conversation.
  --configuration-flow-sid: string # The studio flow SID, where the webhook should be sent to.
  --configuration-method: string@configuration-method-completer
  --configuration-replay-after: int # The message index for which and it's successors the webhook will be replayed. Not set by default
  --configuration-triggers: list<string> # The list of keywords, firing webhook event for this Conversation.
  --configuration-url: string # The absolute url the webhook request should be sent to.
  target: string@target-completer-1
]: any -> record<account_sid: string, chat_service_sid: string, configuration: any, conversation_sid: string, date_created: string, date_updated: string, sid: string, target: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid), conversation_sid: (encode-path-segment $conversation_sid)} | format pattern "/v1/Services/{chat_service_sid}/Conversations/{conversation_sid}/Webhooks"))
  let req_body = {"Configuration.Filters": $configuration_filters, "Configuration.FlowSid": $configuration_flow_sid, "Configuration.Method": $configuration_method, "Configuration.ReplayAfter": $configuration_replay_after, "Configuration.Triggers": $configuration_triggers, "Configuration.Url": $configuration_url, "Target": $target} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Remove an existing webhook scoped to the conversation
#
# DELETE /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Webhooks/{Sid}
# operationId: DeleteServiceConversationScopedWebhook
export def "services-conversations-webhooks delete" [
  chat_service_sid: string
  conversation_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid), conversation_sid: (encode-path-segment $conversation_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{chat_service_sid}/Conversations/{conversation_sid}/Webhooks/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch the configuration of a conversation-scoped webhook
#
# GET /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Webhooks/{Sid}
# operationId: FetchServiceConversationScopedWebhook
export def "services-conversations-webhooks get" [
  chat_service_sid: string
  conversation_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, chat_service_sid: string, configuration: any, conversation_sid: string, date_created: string, date_updated: string, sid: string, target: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid), conversation_sid: (encode-path-segment $conversation_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{chat_service_sid}/Conversations/{conversation_sid}/Webhooks/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing conversation-scoped webhook
#
# POST /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Webhooks/{Sid}
# operationId: UpdateServiceConversationScopedWebhook
export def "services-conversations-webhooks update" [
  chat_service_sid: string
  conversation_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --configuration-filters: list<string> # The list of events, firing webhook event for this Conversation.
  --configuration-flow-sid: string # The studio flow SID, where the webhook should be sent to.
  --configuration-method: string@configuration-method-completer
  --configuration-triggers: list<string> # The list of keywords, firing webhook event for this Conversation.
  --configuration-url: string # The absolute url the webhook request should be sent to.
]: any -> record<account_sid: string, chat_service_sid: string, configuration: any, conversation_sid: string, date_created: string, date_updated: string, sid: string, target: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid), conversation_sid: (encode-path-segment $conversation_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{chat_service_sid}/Conversations/{conversation_sid}/Webhooks/{sid}"))
  let req_body = {"Configuration.Filters": $configuration_filters, "Configuration.FlowSid": $configuration_flow_sid, "Configuration.Method": $configuration_method, "Configuration.Triggers": $configuration_triggers, "Configuration.Url": $configuration_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Remove a conversation from your service
#
# DELETE /v1/Services/{ChatServiceSid}/Conversations/{Sid}
# operationId: DeleteServiceConversation
export def "services-conversations delete" [
  chat_service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{chat_service_sid}/Conversations/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a conversation from your service
#
# GET /v1/Services/{ChatServiceSid}/Conversations/{Sid}
# operationId: FetchServiceConversation
export def "services-conversations get" [
  chat_service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, attributes: string, bindings: any, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, messaging_service_sid: string, sid: string, state: string, timers: any, unique_name: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{chat_service_sid}/Conversations/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing conversation in your service
#
# POST /v1/Services/{ChatServiceSid}/Conversations/{Sid}
# operationId: UpdateServiceConversation
export def "services-conversations update" [
  chat_service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # An optional string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified. **Note** that if the attributes are not set "{}" will be returned.
  --date-created: string # The date that this resource was created. (format: date-time)
  --date-updated: string # The date that this resource was last updated. (format: date-time)
  --friendly-name: string # The human-readable name of this conversation, limited to 256 characters. Optional.
  --messaging-service-sid: string # The unique ID of the [Messaging Service](https://www.twilio.com/docs/sms/services/api) this conversation belongs to.
  --state: string@state-completer
  --timers-closed: string # ISO8601 duration when conversation will be switched to `closed` state. Minimum value for this timer is 10 minutes.
  --timers-inactive: string # ISO8601 duration when conversation will be switched to `inactive` state. Minimum value for this timer is 1 minute.
  --unique-name: string # An application-defined string that uniquely identifies the resource. It can be used to address the resource in place of the resource's `sid` in the URL.
]: any -> record<account_sid: string, attributes: string, bindings: any, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, messaging_service_sid: string, sid: string, state: string, timers: any, unique_name: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{chat_service_sid}/Conversations/{sid}"))
  let req_body = {"Attributes": $attributes, "DateCreated": $date_created, "DateUpdated": $date_updated, "FriendlyName": $friendly_name, "MessagingServiceSid": $messaging_service_sid, "State": $state, "Timers.Closed": $timers_closed, "Timers.Inactive": $timers_inactive, "UniqueName": $unique_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Retrieve a list of all Conversations that this Participant belongs to by identity or by address. Only one parameter should be specified.
#
# GET /v1/Services/{ChatServiceSid}/ParticipantConversations
# operationId: ListServiceParticipantConversation
export def "services-participant-conversations list" [
  chat_service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --identity: string # A unique string identifier for the conversation participant as [Conversation User](https://www.twilio.com/docs/conversations/api/user-resource). This parameter is non-null if (and only if) the participant is using the Conversations SDK to communicate. Limited to 256 characters.
  --address: string # A unique string identifier for the conversation participant who's not a Conversation User. This parameter could be found in messaging_binding.address field of Participant resource. It should be url-encoded.
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<conversations: table<account_sid: string, chat_service_sid: string, conversation_attributes: string, conversation_created_by: string, conversation_date_created: string, conversation_date_updated: string, conversation_friendly_name: string, conversation_sid: string, conversation_state: string, conversation_timers: any, conversation_unique_name: string, links: record, participant_identity: string, participant_messaging_binding: any, participant_sid: string, participant_user_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "Identity" $identity "scalar") (serialize-qp "Address" $address "scalar") (serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid)} | format pattern "/v1/Services/{chat_service_sid}/ParticipantConversations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of all user roles in your service
#
# GET /v1/Services/{ChatServiceSid}/Roles
# operationId: ListServiceRole
export def "services-roles list" [
  chat_service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, roles: table<account_sid: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list, sid: string, type: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid)} | format pattern "/v1/Services/{chat_service_sid}/Roles") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new user role in your service
#
# POST /v1/Services/{ChatServiceSid}/Roles
# operationId: CreateServiceRole
export def "services-roles create" [
  chat_service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  friendly_name: string # A descriptive string that you create to describe the new resource. It can be up to 64 characters long.
  permission: list<string> # A permission that you grant to the new role. Only one permission can be granted per parameter. To assign more than one permission, repeat this parameter for each permission value. The values for this parameter depend on the role's `type`.
  type: string@type-completer-2
]: any -> record<account_sid: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid)} | format pattern "/v1/Services/{chat_service_sid}/Roles"))
  let req_body = {"FriendlyName": $friendly_name, "Permission": $permission, "Type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Remove a user role from your service
#
# DELETE /v1/Services/{ChatServiceSid}/Roles/{Sid}
# operationId: DeleteServiceRole
export def "services-roles delete" [
  chat_service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{chat_service_sid}/Roles/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a user role from your service
#
# GET /v1/Services/{ChatServiceSid}/Roles/{Sid}
# operationId: FetchServiceRole
export def "services-roles get" [
  chat_service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, sid: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{chat_service_sid}/Roles/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing user role in your service
#
# POST /v1/Services/{ChatServiceSid}/Roles/{Sid}
# operationId: UpdateServiceRole
export def "services-roles update" [
  chat_service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  permission: list<string> # A permission that you grant to the role. Only one permission can be granted per parameter. To assign more than one permission, repeat this parameter for each permission value. Note that the update action replaces all previously assigned permissions with those defined in the update action. To remove a permission, do not include it in the subsequent update action. The values for this parameter depend on the role's `type`.
]: any -> record<account_sid: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, permissions: list<string>, sid: string, type: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{chat_service_sid}/Roles/{sid}"))
  let req_body = {"Permission": $permission} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Retrieve a list of all conversation users in your service
#
# GET /v1/Services/{ChatServiceSid}/Users
# operationId: ListServiceUser
export def "services-users list" [
  chat_service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, users: table<account_sid: string, attributes: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, links: record, role_sid: string, sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid)} | format pattern "/v1/Services/{chat_service_sid}/Users") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a new conversation user to your service
#
# POST /v1/Services/{ChatServiceSid}/Users
# operationId: CreateServiceUser
export def "services-users create" [
  chat_service_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # The JSON Object string that stores application-specific data. If attributes have not been set, `{}` is returned.
  --friendly-name: string # The string that you assigned to describe the resource.
  identity: string # The application-defined string that uniquely identifies the resource's User within the [Conversation Service](https://www.twilio.com/docs/conversations/api/service-resource). This value is often a username or an email address, and is case-sensitive.
  --role-sid: string # The SID of a service-level [Role](https://www.twilio.com/docs/conversations/api/role-resource) to assign to the user.
]: any -> record<account_sid: string, attributes: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, links: record, role_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid)} | format pattern "/v1/Services/{chat_service_sid}/Users"))
  let req_body = {"Attributes": $attributes, "FriendlyName": $friendly_name, "Identity": $identity, "RoleSid": $role_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Remove a conversation user from your service
#
# DELETE /v1/Services/{ChatServiceSid}/Users/{Sid}
# operationId: DeleteServiceUser
export def "services-users delete" [
  chat_service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{chat_service_sid}/Users/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a conversation user from your service
#
# GET /v1/Services/{ChatServiceSid}/Users/{Sid}
# operationId: FetchServiceUser
export def "services-users get" [
  chat_service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, attributes: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, links: record, role_sid: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{chat_service_sid}/Users/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing conversation user in your service
#
# POST /v1/Services/{ChatServiceSid}/Users/{Sid}
# operationId: UpdateServiceUser
export def "services-users update" [
  chat_service_sid: string
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # The JSON Object string that stores application-specific data. If attributes have not been set, `{}` is returned.
  --friendly-name: string # The string that you assigned to describe the resource.
  --role-sid: string # The SID of a service-level [Role](https://www.twilio.com/docs/conversations/api/role-resource) to assign to the user.
]: any -> record<account_sid: string, attributes: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, links: record, role_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid), sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{chat_service_sid}/Users/{sid}"))
  let req_body = {"Attributes": $attributes, "FriendlyName": $friendly_name, "RoleSid": $role_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Retrieve a list of all User Conversations for the User.
#
# GET /v1/Services/{ChatServiceSid}/Users/{UserSid}/Conversations
# operationId: ListServiceUserConversation
export def "services-users-conversations list" [
  chat_service_sid: string
  user_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<conversations: table<account_sid: string, attributes: string, chat_service_sid: string, conversation_sid: string, conversation_state: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, last_read_message_index: int, links: record, notification_level: string, participant_sid: string, timers: any, unique_name: string, unread_messages_count: int, url: string, user_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid), user_sid: (encode-path-segment $user_sid)} | format pattern "/v1/Services/{chat_service_sid}/Users/{user_sid}/Conversations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a specific User Conversation.
#
# DELETE /v1/Services/{ChatServiceSid}/Users/{UserSid}/Conversations/{ConversationSid}
# operationId: DeleteServiceUserConversation
export def "services-users-conversations delete" [
  chat_service_sid: string
  user_sid: string
  conversation_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid), user_sid: (encode-path-segment $user_sid), conversation_sid: (encode-path-segment $conversation_sid)} | format pattern "/v1/Services/{chat_service_sid}/Users/{user_sid}/Conversations/{conversation_sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a specific User Conversation.
#
# GET /v1/Services/{ChatServiceSid}/Users/{UserSid}/Conversations/{ConversationSid}
# operationId: FetchServiceUserConversation
export def "services-users-conversations get" [
  chat_service_sid: string
  user_sid: string
  conversation_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, attributes: string, chat_service_sid: string, conversation_sid: string, conversation_state: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, last_read_message_index: int, links: record, notification_level: string, participant_sid: string, timers: any, unique_name: string, unread_messages_count: int, url: string, user_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid), user_sid: (encode-path-segment $user_sid), conversation_sid: (encode-path-segment $conversation_sid)} | format pattern "/v1/Services/{chat_service_sid}/Users/{user_sid}/Conversations/{conversation_sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a specific User Conversation.
#
# POST /v1/Services/{ChatServiceSid}/Users/{UserSid}/Conversations/{ConversationSid}
# operationId: UpdateServiceUserConversation
export def "services-users-conversations update" [
  chat_service_sid: string
  user_sid: string
  conversation_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --last-read-message-index: int # The index of the last Message in the Conversation that the Participant has read. (nullable)
  --last-read-timestamp: string # The date of the last message read in conversation by the user, given in ISO 8601 format. (format: date-time)
  --notification-level: string@notification-level-completer
]: any -> record<account_sid: string, attributes: string, chat_service_sid: string, conversation_sid: string, conversation_state: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, last_read_message_index: int, links: record, notification_level: string, participant_sid: string, timers: any, unique_name: string, unread_messages_count: int, url: string, user_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({chat_service_sid: (encode-path-segment $chat_service_sid), user_sid: (encode-path-segment $user_sid), conversation_sid: (encode-path-segment $conversation_sid)} | format pattern "/v1/Services/{chat_service_sid}/Users/{user_sid}/Conversations/{conversation_sid}"))
  let req_body = {"LastReadMessageIndex": $last_read_message_index, "LastReadTimestamp": $last_read_timestamp, "NotificationLevel": $notification_level} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Remove a conversation service with all its nested resources from your account
#
# DELETE /v1/Services/{Sid}
# operationId: DeleteService
export def "services delete" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a conversation service from your account
#
# GET /v1/Services/{Sid}
# operationId: FetchService
export def "services get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, date_created: string, date_updated: string, friendly_name: string, links: record, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Services/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve a list of all conversation users in your account's default service
#
# GET /v1/Users
# operationId: ListUser
export def "users list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>, users: table<account_sid: string, attributes: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, links: record, role_sid: string, sid: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a new conversation user to your account's default service
#
# POST /v1/Users
# operationId: CreateUser
export def "users create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # The JSON Object string that stores application-specific data. If attributes have not been set, `{}` is returned.
  --friendly-name: string # The string that you assigned to describe the resource.
  identity: string # The application-defined string that uniquely identifies the resource's User within the [Conversation Service](https://www.twilio.com/docs/conversations/api/service-resource). This value is often a username or an email address, and is case-sensitive.
  --role-sid: string # The SID of a service-level [Role](https://www.twilio.com/docs/conversations/api/role-resource) to assign to the user.
]: any -> record<account_sid: string, attributes: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, links: record, role_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base "/v1/Users")
  let req_body = {"Attributes": $attributes, "FriendlyName": $friendly_name, "Identity": $identity, "RoleSid": $role_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Remove a conversation user from your account's default service
#
# DELETE /v1/Users/{Sid}
# operationId: DeleteUser
export def "users delete" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Users/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a conversation user from your account's default service
#
# GET /v1/Users/{Sid}
# operationId: FetchUser
export def "users get" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, attributes: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, links: record, role_sid: string, sid: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Users/{sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an existing conversation user in your account's default service
#
# POST /v1/Users/{Sid}
# operationId: UpdateUser
export def "users update" [
  sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --x-twilio-webhook-enabled: string@x-twilio-webhook-enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --attributes: string # The JSON Object string that stores application-specific data. If attributes have not been set, `{}` is returned.
  --friendly-name: string # The string that you assigned to describe the resource.
  --role-sid: string # The SID of a service-level [Role](https://www.twilio.com/docs/conversations/api/role-resource) to assign to the user.
]: any -> record<account_sid: string, attributes: string, chat_service_sid: string, date_created: string, date_updated: string, friendly_name: string, identity: string, is_notifiable: bool, is_online: bool, links: record, role_sid: string, sid: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({sid: (encode-path-segment $sid)} | format pattern "/v1/Users/{sid}"))
  let req_body = {"Attributes": $attributes, "FriendlyName": $friendly_name, "RoleSid": $role_sid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"X-Twilio-Webhook-Enabled": $x_twilio_webhook_enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}

# Retrieve a list of all User Conversations for the User.
#
# GET /v1/Users/{UserSid}/Conversations
# operationId: ListUserConversation
export def "users-conversations list" [
  user_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-size: int # How many resources to return in each list page. The default is 50, and the maximum is 1000.
  --page: int # The page index. This value is simply for client state.
  --page-token: string # The page token. This is provided by the API.
]: nothing -> record<conversations: table<account_sid: string, attributes: string, chat_service_sid: string, conversation_sid: string, conversation_state: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, last_read_message_index: int, links: record, notification_level: string, participant_sid: string, timers: any, unique_name: string, unread_messages_count: int, url: string, user_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "PageSize" $page_size "scalar") (serialize-qp "Page" $page "scalar") (serialize-qp "PageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({user_sid: (encode-path-segment $user_sid)} | format pattern "/v1/Users/{user_sid}/Conversations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a specific User Conversation.
#
# DELETE /v1/Users/{UserSid}/Conversations/{ConversationSid}
# operationId: DeleteUserConversation
export def "users-conversations delete" [
  user_sid: string
  conversation_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({user_sid: (encode-path-segment $user_sid), conversation_sid: (encode-path-segment $conversation_sid)} | format pattern "/v1/Users/{user_sid}/Conversations/{conversation_sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch a specific User Conversation.
#
# GET /v1/Users/{UserSid}/Conversations/{ConversationSid}
# operationId: FetchUserConversation
export def "users-conversations get" [
  user_sid: string
  conversation_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_sid: string, attributes: string, chat_service_sid: string, conversation_sid: string, conversation_state: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, last_read_message_index: int, links: record, notification_level: string, participant_sid: string, timers: any, unique_name: string, unread_messages_count: int, url: string, user_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({user_sid: (encode-path-segment $user_sid), conversation_sid: (encode-path-segment $conversation_sid)} | format pattern "/v1/Users/{user_sid}/Conversations/{conversation_sid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a specific User Conversation.
#
# POST /v1/Users/{UserSid}/Conversations/{ConversationSid}
# operationId: UpdateUserConversation
export def "users-conversations update" [
  user_sid: string
  conversation_sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --last-read-message-index: int # The index of the last Message in the Conversation that the Participant has read. (nullable)
  --last-read-timestamp: string # The date of the last message read in conversation by the user, given in ISO 8601 format. (format: date-time)
  --notification-level: string@notification-level-completer
]: any -> record<account_sid: string, attributes: string, chat_service_sid: string, conversation_sid: string, conversation_state: string, created_by: string, date_created: string, date_updated: string, friendly_name: string, last_read_message_index: int, links: record, notification_level: string, participant_sid: string, timers: any, unique_name: string, unread_messages_count: int, url: string, user_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base ({user_sid: (encode-path-segment $user_sid), conversation_sid: (encode-path-segment $conversation_sid)} | format pattern "/v1/Users/{user_sid}/Conversations/{conversation_sid}"))
  let req_body = {"LastReadMessageIndex": $last_read_message_index, "LastReadTimestamp": $last_read_timestamp, "NotificationLevel": $notification_level} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req_body = ($req_body | transpose k v | where {|p| $p.v != null} | each {|p| $"(encode-path-segment $p.k)=(encode-path-segment $p.v)" } | str join "&")
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/x-www-form-urlencoded" $req_body
}
