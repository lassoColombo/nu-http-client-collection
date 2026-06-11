# Auto-generated client for Twilio - Conversations v1.0.0
# Source: https://raw.githubusercontent.com/twilio/twilio-oai/main/spec/json/twilio_conversations_v1.json
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
def base-url-completer [] { ["https://conversations.twilio.com"] }
def auth-scheme-completer [] { ["basic"] }

# Completers for enum parameters
def Type-completer [] { ["apple" "chat" "email" "gbm" "messenger" "rcs" "sms" "whatsapp"] }
def AutoCreationType-completer [] { ["default" "studio" "webhook"] }
def AutoCreationWebhookMethod-completer [] { ["get" "post"] }
def Target-completer [] { ["flex" "webhook"] }
def State-completer [] { ["active" "closed" "inactive" "initializing"] }
def X-Twilio-Webhook-Enabled-completer [] { ["false" "true"] }
def Order-completer [] { ["asc" "desc"] }
def Target-completer-1 [] { ["studio" "trigger" "webhook"] }
def ConfigurationMethod-completer [] { ["get" "post"] }
def Type-completer-1 [] { ["apn" "fcm" "gcm"] }
def Type-completer-2 [] { ["conversation" "service"] }
def NotificationLevel-completer [] { ["default" "muted"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "configuration FetchConfiguration" } } | get name | first)
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
export def "configuration FetchConfiguration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, default_chat_service_sid: string, default_messaging_service_sid: string, default_inactive_timer: string, default_closed_timer: string, url: string, links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base "/v1/Configuration")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update the global configuration of conversations on your account
#
# POST /v1/Configuration
# operationId: UpdateConfiguration
export def "configuration UpdateConfiguration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --DefaultChatServiceSid: string # The SID of the default [Conversation Service](https://www.twilio.com/docs/conversations/api/service-resource) to use when creating a conversation.
  --DefaultMessagingServiceSid: string # The SID of the default [Messaging Service](https://www.twilio.com/docs/messaging/api/service-resource) to use when creating a conversation.
  --DefaultInactiveTimer: string # Default ISO8601 duration when conversation will be switched to `inactive` state. Minimum value for this timer is 1 minute.
  --DefaultClosedTimer: string # Default ISO8601 duration when conversation will be switched to `closed` state. Minimum value for this timer is 10 minutes.
]: any -> record<account_sid: string, default_chat_service_sid: string, default_messaging_service_sid: string, default_inactive_timer: string, default_closed_timer: string, url: string, links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base "/v1/Configuration")
  let body = {DefaultChatServiceSid: $DefaultChatServiceSid, DefaultMessagingServiceSid: $DefaultMessagingServiceSid, DefaultInactiveTimer: $DefaultInactiveTimer, DefaultClosedTimer: $DefaultClosedTimer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of address configurations for an account
#
# GET /v1/Configuration/Addresses
# operationId: ListConfigurationAddress
export def "configuration-addresses ListConfigurationAddress" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Type: string # Filter the address configurations by its type. This value can be one of: `whatsapp`, `sms`.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 50. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<address_configurations: table<sid: string, account_sid: string, type: string, address: string, friendly_name: string, auto_creation: any, date_created: string, date_updated: string, url: string, address_country: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "Type" $Type "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Configuration/Addresses" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new address configuration
#
# POST /v1/Configuration/Addresses
# operationId: CreateConfigurationAddress
export def "configuration-addresses CreateConfigurationAddress" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Type: string@Type-completer # Type of Address, value can be `whatsapp` or `sms`.
  Address: string # The unique address to be configured. The address can be a whatsapp address or phone number
  --FriendlyName: string # The human-readable name of this configuration, limited to 256 characters. Optional.
  --AutoCreationEnabled: string@bool-completer # Enable/Disable auto-creating conversations for messages to this address
  --AutoCreationType: string@AutoCreationType-completer
  --AutoCreationConversationServiceSid: string # Conversation Service for the auto-created conversation. If not set, the conversation is created in the default service.
  --AutoCreationWebhookUrl: string # For type `webhook`, the url for the webhook request.
  --AutoCreationWebhookMethod: string@AutoCreationWebhookMethod-completer
  --AutoCreationWebhookFilters: list # The list of events, firing webhook event for this Conversation. Values can be any of the following: `onMessageAdded`, `onMessageUpdated`, `onMessageRemoved`, `onConversationUpdated`, `onConversationStateUpdated`, `onConversationRemoved`, `onParticipantAdded`, `onParticipantUpdated`, `onParticipantRemoved`, `onDeliveryUpdated`
  --AutoCreationStudioFlowSid: string # For type `studio`, the studio flow SID where the webhook should be sent to.
  --AutoCreationStudioRetryCount: int # For type `studio`, number of times to retry the webhook request
  --AddressCountry: string # An ISO 3166-1 alpha-2n country code which the address belongs to. This is currently only applicable to short code addresses.
]: any -> record<sid: string, account_sid: string, type: string, address: string, friendly_name: string, auto_creation: any, date_created: string, date_updated: string, url: string, address_country: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base "/v1/Configuration/Addresses")
  let body = {Type: $Type, Address: $Address, FriendlyName: $FriendlyName, AutoCreation.Enabled: $AutoCreationEnabled, AutoCreation.Type: $AutoCreationType, AutoCreation.ConversationServiceSid: $AutoCreationConversationServiceSid, AutoCreation.WebhookUrl: $AutoCreationWebhookUrl, AutoCreation.WebhookMethod: $AutoCreationWebhookMethod, AutoCreation.WebhookFilters: $AutoCreationWebhookFilters, AutoCreation.StudioFlowSid: $AutoCreationStudioFlowSid, AutoCreation.StudioRetryCount: $AutoCreationStudioRetryCount, AddressCountry: $AddressCountry} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Fetch an address configuration 
#
# GET /v1/Configuration/Addresses/{Sid}
# operationId: FetchConfigurationAddress
export def "configuration-addresses FetchConfigurationAddress" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sid: string, account_sid: string, type: string, address: string, friendly_name: string, auto_creation: any, date_created: string, date_updated: string, url: string, address_country: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Configuration/Addresses/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing address configuration
#
# POST /v1/Configuration/Addresses/{Sid}
# operationId: UpdateConfigurationAddress
export def "configuration-addresses UpdateConfigurationAddress" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --FriendlyName: string # The human-readable name of this configuration, limited to 256 characters. Optional.
  --AutoCreationEnabled: string@bool-completer # Enable/Disable auto-creating conversations for messages to this address
  --AutoCreationType: string@AutoCreationType-completer
  --AutoCreationConversationServiceSid: string # Conversation Service for the auto-created conversation. If not set, the conversation is created in the default service.
  --AutoCreationWebhookUrl: string # For type `webhook`, the url for the webhook request.
  --AutoCreationWebhookMethod: string@AutoCreationWebhookMethod-completer
  --AutoCreationWebhookFilters: list # The list of events, firing webhook event for this Conversation. Values can be any of the following: `onMessageAdded`, `onMessageUpdated`, `onMessageRemoved`, `onConversationUpdated`, `onConversationStateUpdated`, `onConversationRemoved`, `onParticipantAdded`, `onParticipantUpdated`, `onParticipantRemoved`, `onDeliveryUpdated`
  --AutoCreationStudioFlowSid: string # For type `studio`, the studio flow SID where the webhook should be sent to.
  --AutoCreationStudioRetryCount: int # For type `studio`, number of times to retry the webhook request
]: any -> record<sid: string, account_sid: string, type: string, address: string, friendly_name: string, auto_creation: any, date_created: string, date_updated: string, url: string, address_country: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Configuration/Addresses/($Sid)")
  let body = {FriendlyName: $FriendlyName, AutoCreation.Enabled: $AutoCreationEnabled, AutoCreation.Type: $AutoCreationType, AutoCreation.ConversationServiceSid: $AutoCreationConversationServiceSid, AutoCreation.WebhookUrl: $AutoCreationWebhookUrl, AutoCreation.WebhookMethod: $AutoCreationWebhookMethod, AutoCreation.WebhookFilters: $AutoCreationWebhookFilters, AutoCreation.StudioFlowSid: $AutoCreationStudioFlowSid, AutoCreation.StudioRetryCount: $AutoCreationStudioRetryCount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove an existing address configuration
#
# DELETE /v1/Configuration/Addresses/{Sid}
# operationId: DeleteConfigurationAddress
export def "configuration-addresses DeleteConfigurationAddress" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Configuration/Addresses/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# GET /v1/Configuration/Webhooks
#
# operationId: FetchConfigurationWebhook
export def "configuration-webhooks FetchConfigurationWebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, method: string, filters: list<string>, pre_webhook_url: string, post_webhook_url: string, target: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base "/v1/Configuration/Webhooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# POST /v1/Configuration/Webhooks
#
# operationId: UpdateConfigurationWebhook
export def "configuration-webhooks UpdateConfigurationWebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Method: string # The HTTP method to be used when sending a webhook request.
  --Filters: list # The list of webhook event triggers that are enabled for this Service: `onMessageAdded`, `onMessageUpdated`, `onMessageRemoved`, `onMessageAdd`, `onMessageUpdate`, `onMessageRemove`, `onConversationUpdated`, `onConversationRemoved`, `onConversationAdd`, `onConversationAdded`, `onConversationRemove`, `onConversationUpdate`, `onConversationStateUpdated`, `onParticipantAdded`, `onParticipantUpdated`, `onParticipantRemoved`, `onParticipantAdd`, `onParticipantRemove`, `onParticipantUpdate`, `onDeliveryUpdated`, `onUserAdded`, `onUserUpdate`, `onUserUpdated`
  --PreWebhookUrl: string # The absolute url the pre-event webhook request should be sent to.
  --PostWebhookUrl: string # The absolute url the post-event webhook request should be sent to.
  --Target: string@Target-completer # The routing target of the webhook. Can be ordinary or route internally to Flex
]: any -> record<account_sid: string, method: string, filters: list<string>, pre_webhook_url: string, post_webhook_url: string, target: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base "/v1/Configuration/Webhooks")
  let body = {Method: $Method, Filters: $Filters, PreWebhookUrl: $PreWebhookUrl, PostWebhookUrl: $PostWebhookUrl, Target: $Target} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Create a new conversation in your account's default service
#
# POST /v1/Conversations
# operationId: CreateConversation
export def "conversations CreateConversation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --FriendlyName: string # The human-readable name of this conversation, limited to 256 characters. Optional.
  --UniqueName: string # An application-defined string that uniquely identifies the resource. It can be used to address the resource in place of the resource's `sid` in the URL.
  --DateCreated: string # The date that this resource was created. (format: date-time)
  --DateUpdated: string # The date that this resource was last updated. (format: date-time)
  --MessagingServiceSid: string # The unique ID of the [Messaging Service](https://www.twilio.com/docs/messaging/api/service-resource) this conversation belongs to.
  --Attributes: string # An optional string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified.  **Note** that if the attributes are not set "{}" will be returned.
  --State: string@State-completer # Current state of this conversation. Can be either `initializing`, `active`, `inactive` or `closed` and defaults to `active`
  --TimersInactive: string # ISO8601 duration when conversation will be switched to `inactive` state. Minimum value for this timer is 1 minute.
  --TimersClosed: string # ISO8601 duration when conversation will be switched to `closed` state. Minimum value for this timer is 10 minutes.
  --BindingsEmailAddress: string # The default email address that will be used when sending outbound emails in this conversation.
  --BindingsEmailName: string # The default name that will be used when sending outbound emails in this conversation.
]: any -> record<account_sid: string, chat_service_sid: string, messaging_service_sid: string, sid: string, friendly_name: string, unique_name: string, attributes: string, state: string, date_created: string, date_updated: string, timers: any, url: string, links: record, bindings: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base "/v1/Conversations")
  let body = {FriendlyName: $FriendlyName, UniqueName: $UniqueName, DateCreated: $DateCreated, DateUpdated: $DateUpdated, MessagingServiceSid: $MessagingServiceSid, Attributes: $Attributes, State: $State, Timers.Inactive: $TimersInactive, Timers.Closed: $TimersClosed, Bindings.Email.Address: $BindingsEmailAddress, Bindings.Email.Name: $BindingsEmailName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of conversations in your account's default service
#
# GET /v1/Conversations
# operationId: ListConversation
export def "conversations ListConversation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --StartDate: string # Specifies the beginning of the date range for filtering Conversations based on their creation date. Conversations that were created on or after this date will be included in the results. The date must be in ISO8601 format, specifically starting at the beginning of the specified date (YYYY-MM-DDT00:00:00Z), for precise filtering. This parameter can be combined with other filters. If this filter is used, the returned list is sorted by latest conversation creation date in descending order.
  --EndDate: string # Defines the end of the date range for filtering conversations by their creation date. Only conversations that were created on or before this date will appear in the results.  The date must be in ISO8601 format, specifically capturing up to the end of the specified date (YYYY-MM-DDT23:59:59Z), to ensure that conversations from the entire end day are included. This parameter can be combined with other filters. If this filter is used, the returned list is sorted by latest conversation creation date in descending order.
  --State: string@State-completer # State for sorting and filtering list of Conversations. Can be `active`, `inactive` or `closed`
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 100. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<conversations: table<account_sid: string, chat_service_sid: string, messaging_service_sid: string, sid: string, friendly_name: string, unique_name: string, attributes: string, state: string, date_created: string, date_updated: string, timers: any, url: string, links: record, bindings: any>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "StartDate" $StartDate "scalar") (serialize-qp "EndDate" $EndDate "scalar") (serialize-qp "State" $State "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Conversations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing conversation in your account's default service
#
# POST /v1/Conversations/{Sid}
# operationId: UpdateConversation
export def "conversations UpdateConversation" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --FriendlyName: string # The human-readable name of this conversation, limited to 256 characters. Optional.
  --DateCreated: string # The date that this resource was created. (format: date-time)
  --DateUpdated: string # The date that this resource was last updated. (format: date-time)
  --Attributes: string # An optional string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified.  **Note** that if the attributes are not set "{}" will be returned.
  --MessagingServiceSid: string # The unique ID of the [Messaging Service](https://www.twilio.com/docs/messaging/api/service-resource) this conversation belongs to.
  --State: string@State-completer # Current state of this conversation. Can be either `initializing`, `active`, `inactive` or `closed` and defaults to `active`
  --TimersInactive: string # ISO8601 duration when conversation will be switched to `inactive` state. Minimum value for this timer is 1 minute.
  --TimersClosed: string # ISO8601 duration when conversation will be switched to `closed` state. Minimum value for this timer is 10 minutes.
  --UniqueName: string # An application-defined string that uniquely identifies the resource. It can be used to address the resource in place of the resource's `sid` in the URL.
  --BindingsEmailAddress: string # The default email address that will be used when sending outbound emails in this conversation.
  --BindingsEmailName: string # The default name that will be used when sending outbound emails in this conversation.
]: any -> record<account_sid: string, chat_service_sid: string, messaging_service_sid: string, sid: string, friendly_name: string, unique_name: string, attributes: string, state: string, date_created: string, date_updated: string, timers: any, url: string, links: record, bindings: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Conversations/($Sid)")
  let body = {FriendlyName: $FriendlyName, DateCreated: $DateCreated, DateUpdated: $DateUpdated, Attributes: $Attributes, MessagingServiceSid: $MessagingServiceSid, State: $State, Timers.Inactive: $TimersInactive, Timers.Closed: $TimersClosed, UniqueName: $UniqueName, Bindings.Email.Address: $BindingsEmailAddress, Bindings.Email.Name: $BindingsEmailName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove a conversation from your account's default service
#
# DELETE /v1/Conversations/{Sid}
# operationId: DeleteConversation
export def "conversations DeleteConversation" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Conversations/($Sid)")
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a conversation from your account's default service
#
# GET /v1/Conversations/{Sid}
# operationId: FetchConversation
export def "conversations FetchConversation" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, chat_service_sid: string, messaging_service_sid: string, sid: string, friendly_name: string, unique_name: string, attributes: string, state: string, date_created: string, date_updated: string, timers: any, url: string, links: record, bindings: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Conversations/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a new message to the conversation
#
# POST /v1/Conversations/{ConversationSid}/Messages
# operationId: CreateConversationMessage
export def "conversations-messages CreateConversationMessage" [
  ConversationSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --Author: string # The channel specific identifier of the message's author. Defaults to `system`.
  --Body: string # The content of the message, can be up to 1,600 characters long.
  --DateCreated: string # The date that this resource was created. (format: date-time)
  --DateUpdated: string # The date that this resource was last updated. `null` if the message has not been edited. (format: date-time)
  --Attributes: string # A string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified.  **Note** that if the attributes are not set "{}" will be returned.
  --MediaSid: string # The Media SID to be attached to the new Message.
  --ContentSid: string # The unique ID of the multi-channel [Rich Content](https://www.twilio.com/docs/content) template, required for template-generated messages.  **Note** that if this field is set, `Body` and `MediaSid` parameters are ignored.
  --ContentVariables: string # A structurally valid JSON string that contains values to resolve Rich Content template variables.
  --Subject: string # The subject of the message, can be up to 256 characters long.
]: any -> record<account_sid: string, conversation_sid: string, sid: string, index: int, author: string, body: string, media: list<any>, attributes: string, participant_sid: string, date_created: string, date_updated: string, url: string, delivery: any, links: record, content_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Conversations/($ConversationSid)/Messages")
  let body = {Author: $Author, Body: $Body, DateCreated: $DateCreated, DateUpdated: $DateUpdated, Attributes: $Attributes, MediaSid: $MediaSid, ContentSid: $ContentSid, ContentVariables: $ContentVariables, Subject: $Subject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of all messages in the conversation
#
# GET /v1/Conversations/{ConversationSid}/Messages
# operationId: ListConversationMessage
export def "conversations-messages ListConversationMessage" [
  ConversationSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Order: string@Order-completer # The sort order of the returned messages. Can be: `asc` (ascending) or `desc` (descending), with `asc` as the default.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 100. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<messages: table<account_sid: string, conversation_sid: string, sid: string, index: int, author: string, body: string, media: list, attributes: string, participant_sid: string, date_created: string, date_updated: string, url: string, delivery: any, links: record, content_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "Order" $Order "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Conversations/($ConversationSid)/Messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing message in the conversation
#
# POST /v1/Conversations/{ConversationSid}/Messages/{Sid}
# operationId: UpdateConversationMessage
export def "conversations-messages UpdateConversationMessage" [
  ConversationSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --Author: string # The channel specific identifier of the message's author. Defaults to `system`.
  --Body: string # The content of the message, can be up to 1,600 characters long.
  --DateCreated: string # The date that this resource was created. (format: date-time)
  --DateUpdated: string # The date that this resource was last updated. `null` if the message has not been edited. (format: date-time)
  --Attributes: string # A string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified.  **Note** that if the attributes are not set "{}" will be returned.
  --Subject: string # The subject of the message, can be up to 256 characters long.
]: any -> record<account_sid: string, conversation_sid: string, sid: string, index: int, author: string, body: string, media: list<any>, attributes: string, participant_sid: string, date_created: string, date_updated: string, url: string, delivery: any, links: record, content_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Conversations/($ConversationSid)/Messages/($Sid)")
  let body = {Author: $Author, Body: $Body, DateCreated: $DateCreated, DateUpdated: $DateUpdated, Attributes: $Attributes, Subject: $Subject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove a message from the conversation
#
# DELETE /v1/Conversations/{ConversationSid}/Messages/{Sid}
# operationId: DeleteConversationMessage
export def "conversations-messages DeleteConversationMessage" [
  ConversationSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Conversations/($ConversationSid)/Messages/($Sid)")
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a message from the conversation
#
# GET /v1/Conversations/{ConversationSid}/Messages/{Sid}
# operationId: FetchConversationMessage
export def "conversations-messages FetchConversationMessage" [
  ConversationSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, conversation_sid: string, sid: string, index: int, author: string, body: string, media: list<any>, attributes: string, participant_sid: string, date_created: string, date_updated: string, url: string, delivery: any, links: record, content_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Conversations/($ConversationSid)/Messages/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch the delivery and read receipts of the conversation message
#
# GET /v1/Conversations/{ConversationSid}/Messages/{MessageSid}/Receipts/{Sid}
# operationId: FetchConversationMessageReceipt
export def "conversations-messages-receipts FetchConversationMessageReceipt" [
  ConversationSid: string
  MessageSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, conversation_sid: string, sid: string, message_sid: string, channel_message_sid: string, participant_sid: string, status: string, error_code: int, date_created: string, date_updated: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Conversations/($ConversationSid)/Messages/($MessageSid)/Receipts/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of all delivery and read receipts of the conversation message
#
# GET /v1/Conversations/{ConversationSid}/Messages/{MessageSid}/Receipts
# operationId: ListConversationMessageReceipt
export def "conversations-messages-receipts ListConversationMessageReceipt" [
  ConversationSid: string
  MessageSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 50. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<delivery_receipts: table<account_sid: string, conversation_sid: string, sid: string, message_sid: string, channel_message_sid: string, participant_sid: string, status: string, error_code: int, date_created: string, date_updated: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Conversations/($ConversationSid)/Messages/($MessageSid)/Receipts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a new participant to the conversation
#
# POST /v1/Conversations/{ConversationSid}/Participants
# operationId: CreateConversationParticipant
export def "conversations-participants CreateConversationParticipant" [
  ConversationSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --Identity: string # A unique string identifier for the conversation participant as [Conversation User](https://www.twilio.com/docs/conversations/api/user-resource). This parameter is non-null if (and only if) the participant is using the Conversations SDK to communicate. Limited to 256 characters.
  --MessagingBindingAddress: string # The address of the participant's device, e.g. a phone or WhatsApp number. Together with the Proxy address, this determines a participant uniquely. This field (with proxy_address) is only null when the participant is interacting from an SDK endpoint (see the 'identity' field).
  --MessagingBindingProxyAddress: string # The address of the Twilio phone number (or WhatsApp number) that the participant is in contact with. This field, together with participant address, is only null when the participant is interacting from an SDK endpoint (see the 'identity' field).
  --DateCreated: string # The date that this resource was created. (format: date-time)
  --DateUpdated: string # The date that this resource was last updated. (format: date-time)
  --Attributes: string # An optional string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified.  **Note** that if the attributes are not set "{}" will be returned.
  --MessagingBindingProjectedAddress: string # The address of the Twilio phone number that is used in Group MMS. Communication mask for the Conversation participant with Identity.
  --RoleSid: string # The SID of a conversation-level [Role](https://www.twilio.com/docs/conversations/api/role-resource) to assign to the participant.
]: any -> record<account_sid: string, conversation_sid: string, sid: string, identity: string, attributes: string, messaging_binding: any, role_sid: string, date_created: string, date_updated: string, url: string, last_read_message_index: int, last_read_timestamp: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Conversations/($ConversationSid)/Participants")
  let body = {Identity: $Identity, MessagingBinding.Address: $MessagingBindingAddress, MessagingBinding.ProxyAddress: $MessagingBindingProxyAddress, DateCreated: $DateCreated, DateUpdated: $DateUpdated, Attributes: $Attributes, MessagingBinding.ProjectedAddress: $MessagingBindingProjectedAddress, RoleSid: $RoleSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of all participants of the conversation
#
# GET /v1/Conversations/{ConversationSid}/Participants
# operationId: ListConversationParticipant
export def "conversations-participants ListConversationParticipant" [
  ConversationSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 100. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<participants: table<account_sid: string, conversation_sid: string, sid: string, identity: string, attributes: string, messaging_binding: any, role_sid: string, date_created: string, date_updated: string, url: string, last_read_message_index: int, last_read_timestamp: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Conversations/($ConversationSid)/Participants" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing participant in the conversation
#
# POST /v1/Conversations/{ConversationSid}/Participants/{Sid}
# operationId: UpdateConversationParticipant
export def "conversations-participants UpdateConversationParticipant" [
  ConversationSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --DateCreated: string # The date that this resource was created. (format: date-time)
  --DateUpdated: string # The date that this resource was last updated. (format: date-time)
  --Attributes: string # An optional string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified.  **Note** that if the attributes are not set "{}" will be returned.
  --RoleSid: string # The SID of a conversation-level [Role](https://www.twilio.com/docs/conversations/api/role-resource) to assign to the participant.
  --MessagingBindingProxyAddress: string # The address of the Twilio phone number that the participant is in contact with. 'null' value will remove it.
  --MessagingBindingProjectedAddress: string # The address of the Twilio phone number that is used in Group MMS. 'null' value will remove it.
  --Identity: string # A unique string identifier for the conversation participant as [Conversation User](https://www.twilio.com/docs/conversations/api/user-resource). This parameter is non-null if (and only if) the participant is using the Conversations SDK to communicate. Limited to 256 characters.
  --LastReadMessageIndex: int # Index of last “read” message in the [Conversation](https://www.twilio.com/docs/conversations/api/conversation-resource) for the Participant. (nullable)
  --LastReadTimestamp: string # Timestamp of last “read” message in the [Conversation](https://www.twilio.com/docs/conversations/api/conversation-resource) for the Participant.
]: any -> record<account_sid: string, conversation_sid: string, sid: string, identity: string, attributes: string, messaging_binding: any, role_sid: string, date_created: string, date_updated: string, url: string, last_read_message_index: int, last_read_timestamp: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Conversations/($ConversationSid)/Participants/($Sid)")
  let body = {DateCreated: $DateCreated, DateUpdated: $DateUpdated, Attributes: $Attributes, RoleSid: $RoleSid, MessagingBinding.ProxyAddress: $MessagingBindingProxyAddress, MessagingBinding.ProjectedAddress: $MessagingBindingProjectedAddress, Identity: $Identity, LastReadMessageIndex: $LastReadMessageIndex, LastReadTimestamp: $LastReadTimestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove a participant from the conversation
#
# DELETE /v1/Conversations/{ConversationSid}/Participants/{Sid}
# operationId: DeleteConversationParticipant
export def "conversations-participants DeleteConversationParticipant" [
  ConversationSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Conversations/($ConversationSid)/Participants/($Sid)")
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a participant of the conversation
#
# GET /v1/Conversations/{ConversationSid}/Participants/{Sid}
# operationId: FetchConversationParticipant
export def "conversations-participants FetchConversationParticipant" [
  ConversationSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, conversation_sid: string, sid: string, identity: string, attributes: string, messaging_binding: any, role_sid: string, date_created: string, date_updated: string, url: string, last_read_message_index: int, last_read_timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Conversations/($ConversationSid)/Participants/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of all webhooks scoped to the conversation
#
# GET /v1/Conversations/{ConversationSid}/Webhooks
# operationId: ListConversationScopedWebhook
export def "conversations-webhooks ListConversationScopedWebhook" [
  ConversationSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 5, and the maximum is 5. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<webhooks: table<sid: string, account_sid: string, conversation_sid: string, target: string, url: string, configuration: any, date_created: string, date_updated: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Conversations/($ConversationSid)/Webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new webhook scoped to the conversation
#
# POST /v1/Conversations/{ConversationSid}/Webhooks
# operationId: CreateConversationScopedWebhook
export def "conversations-webhooks CreateConversationScopedWebhook" [
  ConversationSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Target: string@Target-completer-1 # The target of this webhook: `webhook`, `studio`, `trigger`
  --ConfigurationUrl: string # The absolute url the webhook request should be sent to.
  --ConfigurationMethod: string@ConfigurationMethod-completer
  --ConfigurationFilters: list # The list of events, firing webhook event for this Conversation.
  --ConfigurationTriggers: list # The list of keywords, firing webhook event for this Conversation.
  --ConfigurationFlowSid: string # The studio flow SID, where the webhook should be sent to.
  --ConfigurationReplayAfter: int # The message index for which and it's successors the webhook will be replayed. Not set by default
]: any -> record<sid: string, account_sid: string, conversation_sid: string, target: string, url: string, configuration: any, date_created: string, date_updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Conversations/($ConversationSid)/Webhooks")
  let body = {Target: $Target, Configuration.Url: $ConfigurationUrl, Configuration.Method: $ConfigurationMethod, Configuration.Filters: $ConfigurationFilters, Configuration.Triggers: $ConfigurationTriggers, Configuration.FlowSid: $ConfigurationFlowSid, Configuration.ReplayAfter: $ConfigurationReplayAfter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Fetch the configuration of a conversation-scoped webhook
#
# GET /v1/Conversations/{ConversationSid}/Webhooks/{Sid}
# operationId: FetchConversationScopedWebhook
export def "conversations-webhooks FetchConversationScopedWebhook" [
  ConversationSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sid: string, account_sid: string, conversation_sid: string, target: string, url: string, configuration: any, date_created: string, date_updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Conversations/($ConversationSid)/Webhooks/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing conversation-scoped webhook
#
# POST /v1/Conversations/{ConversationSid}/Webhooks/{Sid}
# operationId: UpdateConversationScopedWebhook
export def "conversations-webhooks UpdateConversationScopedWebhook" [
  ConversationSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ConfigurationUrl: string # The absolute url the webhook request should be sent to.
  --ConfigurationMethod: string@ConfigurationMethod-completer
  --ConfigurationFilters: list # The list of events, firing webhook event for this Conversation.
  --ConfigurationTriggers: list # The list of keywords, firing webhook event for this Conversation.
  --ConfigurationFlowSid: string # The studio flow SID, where the webhook should be sent to.
]: any -> record<sid: string, account_sid: string, conversation_sid: string, target: string, url: string, configuration: any, date_created: string, date_updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Conversations/($ConversationSid)/Webhooks/($Sid)")
  let body = {Configuration.Url: $ConfigurationUrl, Configuration.Method: $ConfigurationMethod, Configuration.Filters: $ConfigurationFilters, Configuration.Triggers: $ConfigurationTriggers, Configuration.FlowSid: $ConfigurationFlowSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove an existing webhook scoped to the conversation
#
# DELETE /v1/Conversations/{ConversationSid}/Webhooks/{Sid}
# operationId: DeleteConversationScopedWebhook
export def "conversations-webhooks DeleteConversationScopedWebhook" [
  ConversationSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Conversations/($ConversationSid)/Webhooks/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new conversation with the list of participants in your account's default service
#
# POST /v1/ConversationWithParticipants
# operationId: CreateConversationWithParticipants
export def "conversation-with-participants CreateConversationWithParticipants" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --FriendlyName: string # The human-readable name of this conversation, limited to 256 characters. Optional.
  --UniqueName: string # An application-defined string that uniquely identifies the resource. It can be used to address the resource in place of the resource's `sid` in the URL.
  --DateCreated: string # The date that this resource was created. (format: date-time)
  --DateUpdated: string # The date that this resource was last updated. (format: date-time)
  --MessagingServiceSid: string # The unique ID of the [Messaging Service](https://www.twilio.com/docs/messaging/api/service-resource) this conversation belongs to.
  --Attributes: string # An optional string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified.  **Note** that if the attributes are not set "{}" will be returned.
  --State: string@State-completer # Current state of this conversation. Can be either `initializing`, `active`, `inactive` or `closed` and defaults to `active`
  --TimersInactive: string # ISO8601 duration when conversation will be switched to `inactive` state. Minimum value for this timer is 1 minute.
  --TimersClosed: string # ISO8601 duration when conversation will be switched to `closed` state. Minimum value for this timer is 10 minutes.
  --BindingsEmailAddress: string # The default email address that will be used when sending outbound emails in this conversation.
  --BindingsEmailName: string # The default name that will be used when sending outbound emails in this conversation.
  --Participant: list # The participant to be added to the conversation in JSON format. The JSON object attributes are as parameters in [Participant Resource](https://www.twilio.com/docs/conversations/api/conversation-participant-resource). The maximum number of participants that can be added in a single request is 10.
]: any -> record<account_sid: string, chat_service_sid: string, messaging_service_sid: string, sid: string, friendly_name: string, unique_name: string, attributes: string, state: string, date_created: string, date_updated: string, timers: any, links: record, bindings: any, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base "/v1/ConversationWithParticipants")
  let body = {FriendlyName: $FriendlyName, UniqueName: $UniqueName, DateCreated: $DateCreated, DateUpdated: $DateUpdated, MessagingServiceSid: $MessagingServiceSid, Attributes: $Attributes, State: $State, Timers.Inactive: $TimersInactive, Timers.Closed: $TimersClosed, Bindings.Email.Address: $BindingsEmailAddress, Bindings.Email.Name: $BindingsEmailName, Participant: $Participant} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Add a new push notification credential to your account
#
# POST /v1/Credentials
# operationId: CreateCredential
export def "credentials CreateCredential" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Type: string@Type-completer-1 # The type of push-notification service the credential is for. Can be: `fcm`, `gcm`, or `apn`.
  --FriendlyName: string # A descriptive string that you create to describe the new resource. It can be up to 64 characters long.
  --Certificate: string # [APN only] The URL encoded representation of the certificate. For example,  `-----BEGIN CERTIFICATE----- MIIFnTCCBIWgAwIBAgIIAjy9H849+E8wDQYJKoZIhvcNAQEF.....A== -----END CERTIFICATE-----`.
  --PrivateKey: string # [APN only] The URL encoded representation of the private key. For example, `-----BEGIN RSA PRIVATE KEY----- MIIEpQIBAAKCAQEAuyf/lNrH9ck8DmNyo3fG... -----END RSA PRIVATE KEY-----`.
  --Sandbox: string@bool-completer # [APN only] Whether to send the credential to sandbox APNs. Can be `true` to send to sandbox APNs or `false` to send to production.
  --ApiKey: string # [GCM only] The API key for the project that was obtained from the Google Developer console for your GCM Service application credential.
  --Secret: string # [FCM only] The **Server key** of your project from the Firebase console, found under Settings / Cloud messaging.
]: any -> record<sid: string, account_sid: string, friendly_name: string, type: string, sandbox: string, date_created: string, date_updated: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base "/v1/Credentials")
  let body = {Type: $Type, FriendlyName: $FriendlyName, Certificate: $Certificate, PrivateKey: $PrivateKey, Sandbox: $Sandbox, ApiKey: $ApiKey, Secret: $Secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of all push notification credentials on your account
#
# GET /v1/Credentials
# operationId: ListCredential
export def "credentials ListCredential" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 100. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<credentials: table<sid: string, account_sid: string, friendly_name: string, type: string, sandbox: string, date_created: string, date_updated: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Credentials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing push notification credential on your account
#
# POST /v1/Credentials/{Sid}
# operationId: UpdateCredential
export def "credentials UpdateCredential" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Type: string@Type-completer-1 # The type of push-notification service the credential is for. Can be: `fcm`, `gcm`, or `apn`.
  --FriendlyName: string # A descriptive string that you create to describe the new resource. It can be up to 64 characters long.
  --Certificate: string # [APN only] The URL encoded representation of the certificate. For example,  `-----BEGIN CERTIFICATE----- MIIFnTCCBIWgAwIBAgIIAjy9H849+E8wDQYJKoZIhvcNAQEF.....A== -----END CERTIFICATE-----`.
  --PrivateKey: string # [APN only] The URL encoded representation of the private key. For example, `-----BEGIN RSA PRIVATE KEY----- MIIEpQIBAAKCAQEAuyf/lNrH9ck8DmNyo3fG... -----END RSA PRIVATE KEY-----`.
  --Sandbox: string@bool-completer # [APN only] Whether to send the credential to sandbox APNs. Can be `true` to send to sandbox APNs or `false` to send to production.
  --ApiKey: string # [GCM only] The API key for the project that was obtained from the Google Developer console for your GCM Service application credential.
  --Secret: string # [FCM only] The **Server key** of your project from the Firebase console, found under Settings / Cloud messaging.
]: any -> record<sid: string, account_sid: string, friendly_name: string, type: string, sandbox: string, date_created: string, date_updated: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Credentials/($Sid)")
  let body = {Type: $Type, FriendlyName: $FriendlyName, Certificate: $Certificate, PrivateKey: $PrivateKey, Sandbox: $Sandbox, ApiKey: $ApiKey, Secret: $Secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove a push notification credential from your account
#
# DELETE /v1/Credentials/{Sid}
# operationId: DeleteCredential
export def "credentials DeleteCredential" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Credentials/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a push notification credential from your account
#
# GET /v1/Credentials/{Sid}
# operationId: FetchCredential
export def "credentials FetchCredential" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sid: string, account_sid: string, friendly_name: string, type: string, sandbox: string, date_created: string, date_updated: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Credentials/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of all Conversations that this Participant belongs to by identity or by address. Only one parameter should be specified.
#
# GET /v1/ParticipantConversations
# operationId: ListParticipantConversation
export def "participant-conversations ListParticipantConversation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Identity: string # A unique string identifier for the conversation participant as [Conversation User](https://www.twilio.com/docs/conversations/api/user-resource). This parameter is non-null if (and only if) the participant is using the Conversations SDK to communicate. Limited to 256 characters.
  --Address: string # A unique string identifier for the conversation participant who's not a Conversation User. This parameter could be found in messaging_binding.address field of Participant resource. It should be url-encoded.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 50. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<conversations: table<account_sid: string, chat_service_sid: string, participant_sid: string, participant_user_sid: string, participant_identity: string, participant_messaging_binding: any, conversation_sid: string, conversation_unique_name: string, conversation_friendly_name: string, conversation_attributes: string, conversation_date_created: string, conversation_date_updated: string, conversation_created_by: string, conversation_state: string, conversation_timers: any, links: record>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "Identity" $Identity "scalar") (serialize-qp "Address" $Address "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/ParticipantConversations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new user role in your account's default service
#
# POST /v1/Roles
# operationId: CreateRole
export def "roles CreateRole" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  FriendlyName: string # A descriptive string that you create to describe the new resource. It can be up to 64 characters long.
  Type: string@Type-completer-2 # The type of role. Can be: `conversation` for [Conversation](https://www.twilio.com/docs/conversations/api/conversation-resource) roles or `service` for [Conversation Service](https://www.twilio.com/docs/conversations/api/service-resource) roles.
  Permission: list # A permission that you grant to the new role. Only one permission can be granted per parameter. To assign more than one permission, repeat this parameter for each permission value. The values for this parameter depend on the role's `type`.
]: any -> record<sid: string, account_sid: string, chat_service_sid: string, friendly_name: string, type: string, permissions: list<string>, date_created: string, date_updated: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base "/v1/Roles")
  let body = {FriendlyName: $FriendlyName, Type: $Type, Permission: $Permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of all user roles in your account's default service
#
# GET /v1/Roles
# operationId: ListRole
export def "roles ListRole" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 50. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<roles: table<sid: string, account_sid: string, chat_service_sid: string, friendly_name: string, type: string, permissions: list, date_created: string, date_updated: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing user role in your account's default service
#
# POST /v1/Roles/{Sid}
# operationId: UpdateRole
export def "roles UpdateRole" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Permission: list # A permission that you grant to the role. Only one permission can be granted per parameter. To assign more than one permission, repeat this parameter for each permission value. Note that the update action replaces all previously assigned permissions with those defined in the update action. To remove a permission, do not include it in the subsequent update action. The values for this parameter depend on the role's `type`.
]: any -> record<sid: string, account_sid: string, chat_service_sid: string, friendly_name: string, type: string, permissions: list<string>, date_created: string, date_updated: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Roles/($Sid)")
  let body = {Permission: $Permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove a user role from your account's default service
#
# DELETE /v1/Roles/{Sid}
# operationId: DeleteRole
export def "roles DeleteRole" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Roles/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a user role from your account's default service
#
# GET /v1/Roles/{Sid}
# operationId: FetchRole
export def "roles FetchRole" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sid: string, account_sid: string, chat_service_sid: string, friendly_name: string, type: string, permissions: list<string>, date_created: string, date_updated: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Roles/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new conversation service on your account
#
# POST /v1/Services
# operationId: CreateService
export def "services CreateService" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  FriendlyName: string # The human-readable name of this service, limited to 256 characters. Optional.
]: any -> record<account_sid: string, sid: string, friendly_name: string, date_created: string, date_updated: string, url: string, links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base "/v1/Services")
  let body = {FriendlyName: $FriendlyName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of all conversation services on your account
#
# GET /v1/Services
# operationId: ListService
export def "services ListService" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 100. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<services: table<account_sid: string, sid: string, friendly_name: string, date_created: string, date_updated: string, url: string, links: record>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Services" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove a conversation service with all its nested resources from your account
#
# DELETE /v1/Services/{Sid}
# operationId: DeleteService
export def "services DeleteService" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a conversation service from your account
#
# GET /v1/Services/{Sid}
# operationId: FetchService
export def "services FetchService" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, sid: string, friendly_name: string, date_created: string, date_updated: string, url: string, links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove a push notification binding from the conversation service
#
# DELETE /v1/Services/{ChatServiceSid}/Bindings/{Sid}
# operationId: DeleteServiceBinding
export def "services-bindings DeleteServiceBinding" [
  ChatServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Bindings/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a push notification binding from the conversation service
#
# GET /v1/Services/{ChatServiceSid}/Bindings/{Sid}
# operationId: FetchServiceBinding
export def "services-bindings FetchServiceBinding" [
  ChatServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sid: string, account_sid: string, chat_service_sid: string, credential_sid: string, date_created: string, date_updated: string, endpoint: string, identity: string, binding_type: string, message_types: list<string>, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Bindings/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of all push notification bindings in the conversation service
#
# GET /v1/Services/{ChatServiceSid}/Bindings
# operationId: ListServiceBinding
export def "services-bindings ListServiceBinding" [
  ChatServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --BindingType: list # The push technology used by the Binding resources to read.  Can be: `apn`, `gcm`, `fcm`, or `twilsock`.  See [push notification configuration](https://www.twilio.com/docs/chat/push-notification-configuration) for more info.
  --Identity: list # The identity of a [Conversation User](https://www.twilio.com/docs/conversations/api/user-resource) this binding belongs to. See [access tokens](https://www.twilio.com/docs/conversations/create-tokens) for more details.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 100. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<bindings: table<sid: string, account_sid: string, chat_service_sid: string, credential_sid: string, date_created: string, date_updated: string, endpoint: string, identity: string, binding_type: string, message_types: list, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "BindingType" $BindingType "multi") (serialize-qp "Identity" $Identity "multi") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Bindings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch the configuration of a conversation service
#
# GET /v1/Services/{ChatServiceSid}/Configuration
# operationId: FetchServiceConfiguration
export def "services-configuration FetchServiceConfiguration" [
  ChatServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<chat_service_sid: string, default_conversation_creator_role_sid: string, default_conversation_role_sid: string, default_chat_service_role_sid: string, url: string, links: record, reachability_enabled: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Configuration")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update configuration settings of a conversation service
#
# POST /v1/Services/{ChatServiceSid}/Configuration
# operationId: UpdateServiceConfiguration
export def "services-configuration UpdateServiceConfiguration" [
  ChatServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --DefaultConversationCreatorRoleSid: string # The conversation-level role assigned to a conversation creator when they join a new conversation. See [Conversation Role](https://www.twilio.com/docs/conversations/api/role-resource) for more info about roles.
  --DefaultConversationRoleSid: string # The conversation-level role assigned to users when they are added to a conversation. See [Conversation Role](https://www.twilio.com/docs/conversations/api/role-resource) for more info about roles.
  --DefaultChatServiceRoleSid: string # The service-level role assigned to users when they are added to the service. See [Conversation Role](https://www.twilio.com/docs/conversations/api/role-resource) for more info about roles.
  --ReachabilityEnabled: string@bool-completer # Whether the [Reachability Indicator](https://www.twilio.com/docs/conversations/reachability) is enabled for this Conversations Service. The default is `false`.
]: any -> record<chat_service_sid: string, default_conversation_creator_role_sid: string, default_conversation_role_sid: string, default_chat_service_role_sid: string, url: string, links: record, reachability_enabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Configuration")
  let body = {DefaultConversationCreatorRoleSid: $DefaultConversationCreatorRoleSid, DefaultConversationRoleSid: $DefaultConversationRoleSid, DefaultChatServiceRoleSid: $DefaultChatServiceRoleSid, ReachabilityEnabled: $ReachabilityEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Create a new conversation in your service
#
# POST /v1/Services/{ChatServiceSid}/Conversations
# operationId: CreateServiceConversation
export def "services-conversations CreateServiceConversation" [
  ChatServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --FriendlyName: string # The human-readable name of this conversation, limited to 256 characters. Optional.
  --UniqueName: string # An application-defined string that uniquely identifies the resource. It can be used to address the resource in place of the resource's `sid` in the URL.
  --Attributes: string # An optional string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified.  **Note** that if the attributes are not set "{}" will be returned.
  --MessagingServiceSid: string # The unique ID of the [Messaging Service](https://www.twilio.com/docs/messaging/api/service-resource) this conversation belongs to.
  --DateCreated: string # The date that this resource was created. (format: date-time)
  --DateUpdated: string # The date that this resource was last updated. (format: date-time)
  --State: string@State-completer # Current state of this conversation. Can be either `initializing`, `active`, `inactive` or `closed` and defaults to `active`
  --TimersInactive: string # ISO8601 duration when conversation will be switched to `inactive` state. Minimum value for this timer is 1 minute.
  --TimersClosed: string # ISO8601 duration when conversation will be switched to `closed` state. Minimum value for this timer is 10 minutes.
  --BindingsEmailAddress: string # The default email address that will be used when sending outbound emails in this conversation.
  --BindingsEmailName: string # The default name that will be used when sending outbound emails in this conversation.
]: any -> record<account_sid: string, chat_service_sid: string, messaging_service_sid: string, sid: string, friendly_name: string, unique_name: string, attributes: string, state: string, date_created: string, date_updated: string, timers: any, url: string, links: record, bindings: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Conversations")
  let body = {FriendlyName: $FriendlyName, UniqueName: $UniqueName, Attributes: $Attributes, MessagingServiceSid: $MessagingServiceSid, DateCreated: $DateCreated, DateUpdated: $DateUpdated, State: $State, Timers.Inactive: $TimersInactive, Timers.Closed: $TimersClosed, Bindings.Email.Address: $BindingsEmailAddress, Bindings.Email.Name: $BindingsEmailName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of conversations in your service
#
# GET /v1/Services/{ChatServiceSid}/Conversations
# operationId: ListServiceConversation
export def "services-conversations ListServiceConversation" [
  ChatServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --StartDate: string # Specifies the beginning of the date range for filtering Conversations based on their creation date. Conversations that were created on or after this date will be included in the results. The date must be in ISO8601 format, specifically starting at the beginning of the specified date (YYYY-MM-DDT00:00:00Z), for precise filtering. This parameter can be combined with other filters. If this filter is used, the returned list is sorted by latest conversation creation date in descending order.
  --EndDate: string # Defines the end of the date range for filtering conversations by their creation date. Only conversations that were created on or before this date will appear in the results.  The date must be in ISO8601 format, specifically capturing up to the end of the specified date (YYYY-MM-DDT23:59:59Z), to ensure that conversations from the entire end day are included. This parameter can be combined with other filters. If this filter is used, the returned list is sorted by latest conversation creation date in descending order.
  --State: string@State-completer # State for sorting and filtering list of Conversations. Can be `active`, `inactive` or `closed`
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 100. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<conversations: table<account_sid: string, chat_service_sid: string, messaging_service_sid: string, sid: string, friendly_name: string, unique_name: string, attributes: string, state: string, date_created: string, date_updated: string, timers: any, url: string, links: record, bindings: any>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "StartDate" $StartDate "scalar") (serialize-qp "EndDate" $EndDate "scalar") (serialize-qp "State" $State "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Conversations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing conversation in your service
#
# POST /v1/Services/{ChatServiceSid}/Conversations/{Sid}
# operationId: UpdateServiceConversation
export def "services-conversations UpdateServiceConversation" [
  ChatServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --FriendlyName: string # The human-readable name of this conversation, limited to 256 characters. Optional.
  --DateCreated: string # The date that this resource was created. (format: date-time)
  --DateUpdated: string # The date that this resource was last updated. (format: date-time)
  --Attributes: string # An optional string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified.  **Note** that if the attributes are not set "{}" will be returned.
  --MessagingServiceSid: string # The unique ID of the [Messaging Service](https://www.twilio.com/docs/messaging/api/service-resource) this conversation belongs to.
  --State: string@State-completer # Current state of this conversation. Can be either `initializing`, `active`, `inactive` or `closed` and defaults to `active`
  --TimersInactive: string # ISO8601 duration when conversation will be switched to `inactive` state. Minimum value for this timer is 1 minute.
  --TimersClosed: string # ISO8601 duration when conversation will be switched to `closed` state. Minimum value for this timer is 10 minutes.
  --UniqueName: string # An application-defined string that uniquely identifies the resource. It can be used to address the resource in place of the resource's `sid` in the URL.
  --BindingsEmailAddress: string # The default email address that will be used when sending outbound emails in this conversation.
  --BindingsEmailName: string # The default name that will be used when sending outbound emails in this conversation.
]: any -> record<account_sid: string, chat_service_sid: string, messaging_service_sid: string, sid: string, friendly_name: string, unique_name: string, attributes: string, state: string, date_created: string, date_updated: string, timers: any, url: string, links: record, bindings: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Conversations/($Sid)")
  let body = {FriendlyName: $FriendlyName, DateCreated: $DateCreated, DateUpdated: $DateUpdated, Attributes: $Attributes, MessagingServiceSid: $MessagingServiceSid, State: $State, Timers.Inactive: $TimersInactive, Timers.Closed: $TimersClosed, UniqueName: $UniqueName, Bindings.Email.Address: $BindingsEmailAddress, Bindings.Email.Name: $BindingsEmailName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove a conversation from your service
#
# DELETE /v1/Services/{ChatServiceSid}/Conversations/{Sid}
# operationId: DeleteServiceConversation
export def "services-conversations DeleteServiceConversation" [
  ChatServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Conversations/($Sid)")
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a conversation from your service
#
# GET /v1/Services/{ChatServiceSid}/Conversations/{Sid}
# operationId: FetchServiceConversation
export def "services-conversations FetchServiceConversation" [
  ChatServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, chat_service_sid: string, messaging_service_sid: string, sid: string, friendly_name: string, unique_name: string, attributes: string, state: string, date_created: string, date_updated: string, timers: any, url: string, links: record, bindings: any> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Conversations/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a new message to the conversation in a specific service
#
# POST /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Messages
# operationId: CreateServiceConversationMessage
export def "services-conversations-messages CreateServiceConversationMessage" [
  ChatServiceSid: string
  ConversationSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --Author: string # The channel specific identifier of the message's author. Defaults to `system`.
  --Body: string # The content of the message, can be up to 1,600 characters long.
  --DateCreated: string # The date that this resource was created. (format: date-time)
  --DateUpdated: string # The date that this resource was last updated. `null` if the message has not been edited. (format: date-time)
  --Attributes: string # A string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified.  **Note** that if the attributes are not set "{}" will be returned.
  --MediaSid: string # The Media SID to be attached to the new Message.
  --ContentSid: string # The unique ID of the multi-channel [Rich Content](https://www.twilio.com/docs/content) template, required for template-generated messages.  **Note** that if this field is set, `Body` and `MediaSid` parameters are ignored.
  --ContentVariables: string # A structurally valid JSON string that contains values to resolve Rich Content template variables.
  --Subject: string # The subject of the message, can be up to 256 characters long.
]: any -> record<account_sid: string, chat_service_sid: string, conversation_sid: string, sid: string, index: int, author: string, body: string, media: list<any>, attributes: string, participant_sid: string, date_created: string, date_updated: string, delivery: any, url: string, links: record, content_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Conversations/($ConversationSid)/Messages")
  let body = {Author: $Author, Body: $Body, DateCreated: $DateCreated, DateUpdated: $DateUpdated, Attributes: $Attributes, MediaSid: $MediaSid, ContentSid: $ContentSid, ContentVariables: $ContentVariables, Subject: $Subject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of all messages in the conversation
#
# GET /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Messages
# operationId: ListServiceConversationMessage
export def "services-conversations-messages ListServiceConversationMessage" [
  ChatServiceSid: string
  ConversationSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Order: string@Order-completer # The sort order of the returned messages. Can be: `asc` (ascending) or `desc` (descending), with `asc` as the default.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 100. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<messages: table<account_sid: string, chat_service_sid: string, conversation_sid: string, sid: string, index: int, author: string, body: string, media: list, attributes: string, participant_sid: string, date_created: string, date_updated: string, delivery: any, url: string, links: record, content_sid: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "Order" $Order "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Conversations/($ConversationSid)/Messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing message in the conversation
#
# POST /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Messages/{Sid}
# operationId: UpdateServiceConversationMessage
export def "services-conversations-messages UpdateServiceConversationMessage" [
  ChatServiceSid: string
  ConversationSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --Author: string # The channel specific identifier of the message's author. Defaults to `system`.
  --Body: string # The content of the message, can be up to 1,600 characters long.
  --DateCreated: string # The date that this resource was created. (format: date-time)
  --DateUpdated: string # The date that this resource was last updated. `null` if the message has not been edited. (format: date-time)
  --Attributes: string # A string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified.  **Note** that if the attributes are not set "{}" will be returned.
  --Subject: string # The subject of the message, can be up to 256 characters long.
]: any -> record<account_sid: string, chat_service_sid: string, conversation_sid: string, sid: string, index: int, author: string, body: string, media: list<any>, attributes: string, participant_sid: string, date_created: string, date_updated: string, delivery: any, url: string, links: record, content_sid: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Conversations/($ConversationSid)/Messages/($Sid)")
  let body = {Author: $Author, Body: $Body, DateCreated: $DateCreated, DateUpdated: $DateUpdated, Attributes: $Attributes, Subject: $Subject} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove a message from the conversation
#
# DELETE /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Messages/{Sid}
# operationId: DeleteServiceConversationMessage
export def "services-conversations-messages DeleteServiceConversationMessage" [
  ChatServiceSid: string
  ConversationSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Conversations/($ConversationSid)/Messages/($Sid)")
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a message from the conversation
#
# GET /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Messages/{Sid}
# operationId: FetchServiceConversationMessage
export def "services-conversations-messages FetchServiceConversationMessage" [
  ChatServiceSid: string
  ConversationSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, chat_service_sid: string, conversation_sid: string, sid: string, index: int, author: string, body: string, media: list<any>, attributes: string, participant_sid: string, date_created: string, date_updated: string, delivery: any, url: string, links: record, content_sid: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Conversations/($ConversationSid)/Messages/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch the delivery and read receipts of the conversation message
#
# GET /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Messages/{MessageSid}/Receipts/{Sid}
# operationId: FetchServiceConversationMessageReceipt
export def "services-conversations-messages-receipts FetchServiceConversationMessageReceipt" [
  ChatServiceSid: string
  ConversationSid: string
  MessageSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, chat_service_sid: string, conversation_sid: string, message_sid: string, sid: string, channel_message_sid: string, participant_sid: string, status: string, error_code: int, date_created: string, date_updated: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Conversations/($ConversationSid)/Messages/($MessageSid)/Receipts/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of all delivery and read receipts of the conversation message
#
# GET /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Messages/{MessageSid}/Receipts
# operationId: ListServiceConversationMessageReceipt
export def "services-conversations-messages-receipts ListServiceConversationMessageReceipt" [
  ChatServiceSid: string
  ConversationSid: string
  MessageSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 50. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<delivery_receipts: table<account_sid: string, chat_service_sid: string, conversation_sid: string, message_sid: string, sid: string, channel_message_sid: string, participant_sid: string, status: string, error_code: int, date_created: string, date_updated: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Conversations/($ConversationSid)/Messages/($MessageSid)/Receipts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a new participant to the conversation in a specific service
#
# POST /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Participants
# operationId: CreateServiceConversationParticipant
export def "services-conversations-participants CreateServiceConversationParticipant" [
  ChatServiceSid: string
  ConversationSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --Identity: string # A unique string identifier for the conversation participant as [Conversation User](https://www.twilio.com/docs/conversations/api/user-resource). This parameter is non-null if (and only if) the participant is using the [Conversation SDK](https://www.twilio.com/docs/conversations/sdk-overview) to communicate. Limited to 256 characters.
  --MessagingBindingAddress: string # The address of the participant's device, e.g. a phone or WhatsApp number. Together with the Proxy address, this determines a participant uniquely. This field (with `proxy_address`) is only null when the participant is interacting from an SDK endpoint (see the `identity` field).
  --MessagingBindingProxyAddress: string # The address of the Twilio phone number (or WhatsApp number) that the participant is in contact with. This field, together with participant address, is only null when the participant is interacting from an SDK endpoint (see the `identity` field).
  --DateCreated: string # The date on which this resource was created. (format: date-time)
  --DateUpdated: string # The date on which this resource was last updated. (format: date-time)
  --Attributes: string # An optional string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified.  **Note** that if the attributes are not set `{}` will be returned.
  --MessagingBindingProjectedAddress: string # The address of the Twilio phone number that is used in Group MMS.
  --RoleSid: string # The SID of a conversation-level [Role](https://www.twilio.com/docs/conversations/api/role-resource) to assign to the participant.
]: any -> record<account_sid: string, chat_service_sid: string, conversation_sid: string, sid: string, identity: string, attributes: string, messaging_binding: any, role_sid: string, date_created: string, date_updated: string, url: string, last_read_message_index: int, last_read_timestamp: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Conversations/($ConversationSid)/Participants")
  let body = {Identity: $Identity, MessagingBinding.Address: $MessagingBindingAddress, MessagingBinding.ProxyAddress: $MessagingBindingProxyAddress, DateCreated: $DateCreated, DateUpdated: $DateUpdated, Attributes: $Attributes, MessagingBinding.ProjectedAddress: $MessagingBindingProjectedAddress, RoleSid: $RoleSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of all participants of the conversation
#
# GET /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Participants
# operationId: ListServiceConversationParticipant
export def "services-conversations-participants ListServiceConversationParticipant" [
  ChatServiceSid: string
  ConversationSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 100. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<participants: table<account_sid: string, chat_service_sid: string, conversation_sid: string, sid: string, identity: string, attributes: string, messaging_binding: any, role_sid: string, date_created: string, date_updated: string, url: string, last_read_message_index: int, last_read_timestamp: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Conversations/($ConversationSid)/Participants" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing participant in the conversation
#
# POST /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Participants/{Sid}
# operationId: UpdateServiceConversationParticipant
export def "services-conversations-participants UpdateServiceConversationParticipant" [
  ChatServiceSid: string
  ConversationSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --DateCreated: string # The date on which this resource was created. (format: date-time)
  --DateUpdated: string # The date on which this resource was last updated. (format: date-time)
  --Identity: string # A unique string identifier for the conversation participant as [Conversation User](https://www.twilio.com/docs/conversations/api/user-resource). This parameter is non-null if (and only if) the participant is using the [Conversation SDK](https://www.twilio.com/docs/conversations/sdk-overview) to communicate. Limited to 256 characters.
  --Attributes: string # An optional string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified.  **Note** that if the attributes are not set `{}` will be returned.
  --RoleSid: string # The SID of a conversation-level [Role](https://www.twilio.com/docs/conversations/api/role-resource) to assign to the participant.
  --MessagingBindingProxyAddress: string # The address of the Twilio phone number that the participant is in contact with. 'null' value will remove it.
  --MessagingBindingProjectedAddress: string # The address of the Twilio phone number that is used in Group MMS. 'null' value will remove it.
  --LastReadMessageIndex: int # Index of last “read” message in the [Conversation](https://www.twilio.com/docs/conversations/api/conversation-resource) for the Participant. (nullable)
  --LastReadTimestamp: string # Timestamp of last “read” message in the [Conversation](https://www.twilio.com/docs/conversations/api/conversation-resource) for the Participant.
]: any -> record<account_sid: string, chat_service_sid: string, conversation_sid: string, sid: string, identity: string, attributes: string, messaging_binding: any, role_sid: string, date_created: string, date_updated: string, url: string, last_read_message_index: int, last_read_timestamp: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Conversations/($ConversationSid)/Participants/($Sid)")
  let body = {DateCreated: $DateCreated, DateUpdated: $DateUpdated, Identity: $Identity, Attributes: $Attributes, RoleSid: $RoleSid, MessagingBinding.ProxyAddress: $MessagingBindingProxyAddress, MessagingBinding.ProjectedAddress: $MessagingBindingProjectedAddress, LastReadMessageIndex: $LastReadMessageIndex, LastReadTimestamp: $LastReadTimestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove a participant from the conversation
#
# DELETE /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Participants/{Sid}
# operationId: DeleteServiceConversationParticipant
export def "services-conversations-participants DeleteServiceConversationParticipant" [
  ChatServiceSid: string
  ConversationSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Conversations/($ConversationSid)/Participants/($Sid)")
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a participant of the conversation
#
# GET /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Participants/{Sid}
# operationId: FetchServiceConversationParticipant
export def "services-conversations-participants FetchServiceConversationParticipant" [
  ChatServiceSid: string
  ConversationSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, chat_service_sid: string, conversation_sid: string, sid: string, identity: string, attributes: string, messaging_binding: any, role_sid: string, date_created: string, date_updated: string, url: string, last_read_message_index: int, last_read_timestamp: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Conversations/($ConversationSid)/Participants/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new webhook scoped to the conversation in a specific service
#
# POST /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Webhooks
# operationId: CreateServiceConversationScopedWebhook
export def "services-conversations-webhooks CreateServiceConversationScopedWebhook" [
  ChatServiceSid: string
  ConversationSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Target: string@Target-completer-1 # The target of this webhook: `webhook`, `studio`, `trigger`
  --ConfigurationUrl: string # The absolute url the webhook request should be sent to.
  --ConfigurationMethod: string@ConfigurationMethod-completer
  --ConfigurationFilters: list # The list of events, firing webhook event for this Conversation.
  --ConfigurationTriggers: list # The list of keywords, firing webhook event for this Conversation.
  --ConfigurationFlowSid: string # The studio flow SID, where the webhook should be sent to.
  --ConfigurationReplayAfter: int # The message index for which and it's successors the webhook will be replayed. Not set by default
]: any -> record<sid: string, account_sid: string, chat_service_sid: string, conversation_sid: string, target: string, url: string, configuration: any, date_created: string, date_updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Conversations/($ConversationSid)/Webhooks")
  let body = {Target: $Target, Configuration.Url: $ConfigurationUrl, Configuration.Method: $ConfigurationMethod, Configuration.Filters: $ConfigurationFilters, Configuration.Triggers: $ConfigurationTriggers, Configuration.FlowSid: $ConfigurationFlowSid, Configuration.ReplayAfter: $ConfigurationReplayAfter} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of all webhooks scoped to the conversation
#
# GET /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Webhooks
# operationId: ListServiceConversationScopedWebhook
export def "services-conversations-webhooks ListServiceConversationScopedWebhook" [
  ChatServiceSid: string
  ConversationSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 5, and the maximum is 5. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<webhooks: table<sid: string, account_sid: string, chat_service_sid: string, conversation_sid: string, target: string, url: string, configuration: any, date_created: string, date_updated: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Conversations/($ConversationSid)/Webhooks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing conversation-scoped webhook
#
# POST /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Webhooks/{Sid}
# operationId: UpdateServiceConversationScopedWebhook
export def "services-conversations-webhooks UpdateServiceConversationScopedWebhook" [
  ChatServiceSid: string
  ConversationSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --ConfigurationUrl: string # The absolute url the webhook request should be sent to.
  --ConfigurationMethod: string@ConfigurationMethod-completer
  --ConfigurationFilters: list # The list of events, firing webhook event for this Conversation.
  --ConfigurationTriggers: list # The list of keywords, firing webhook event for this Conversation.
  --ConfigurationFlowSid: string # The studio flow SID, where the webhook should be sent to.
]: any -> record<sid: string, account_sid: string, chat_service_sid: string, conversation_sid: string, target: string, url: string, configuration: any, date_created: string, date_updated: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Conversations/($ConversationSid)/Webhooks/($Sid)")
  let body = {Configuration.Url: $ConfigurationUrl, Configuration.Method: $ConfigurationMethod, Configuration.Filters: $ConfigurationFilters, Configuration.Triggers: $ConfigurationTriggers, Configuration.FlowSid: $ConfigurationFlowSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove an existing webhook scoped to the conversation
#
# DELETE /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Webhooks/{Sid}
# operationId: DeleteServiceConversationScopedWebhook
export def "services-conversations-webhooks DeleteServiceConversationScopedWebhook" [
  ChatServiceSid: string
  ConversationSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Conversations/($ConversationSid)/Webhooks/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch the configuration of a conversation-scoped webhook
#
# GET /v1/Services/{ChatServiceSid}/Conversations/{ConversationSid}/Webhooks/{Sid}
# operationId: FetchServiceConversationScopedWebhook
export def "services-conversations-webhooks FetchServiceConversationScopedWebhook" [
  ChatServiceSid: string
  ConversationSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sid: string, account_sid: string, chat_service_sid: string, conversation_sid: string, target: string, url: string, configuration: any, date_created: string, date_updated: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Conversations/($ConversationSid)/Webhooks/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new conversation with the list of participants in your account's default service
#
# POST /v1/Services/{ChatServiceSid}/ConversationWithParticipants
# operationId: CreateServiceConversationWithParticipants
export def "services-conversation-with-participants CreateServiceConversationWithParticipants" [
  ChatServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --FriendlyName: string # The human-readable name of this conversation, limited to 256 characters. Optional.
  --UniqueName: string # An application-defined string that uniquely identifies the resource. It can be used to address the resource in place of the resource's `sid` in the URL.
  --DateCreated: string # The date that this resource was created. (format: date-time)
  --DateUpdated: string # The date that this resource was last updated. (format: date-time)
  --MessagingServiceSid: string # The unique ID of the [Messaging Service](https://www.twilio.com/docs/messaging/api/service-resource) this conversation belongs to.
  --Attributes: string # An optional string metadata field you can use to store any data you wish. The string value must contain structurally valid JSON if specified.  **Note** that if the attributes are not set "{}" will be returned.
  --State: string@State-completer # Current state of this conversation. Can be either `initializing`, `active`, `inactive` or `closed` and defaults to `active`
  --TimersInactive: string # ISO8601 duration when conversation will be switched to `inactive` state. Minimum value for this timer is 1 minute.
  --TimersClosed: string # ISO8601 duration when conversation will be switched to `closed` state. Minimum value for this timer is 10 minutes.
  --BindingsEmailAddress: string # The default email address that will be used when sending outbound emails in this conversation.
  --BindingsEmailName: string # The default name that will be used when sending outbound emails in this conversation.
  --Participant: list # The participant to be added to the conversation in JSON format. The JSON object attributes are as parameters in [Participant Resource](https://www.twilio.com/docs/conversations/api/conversation-participant-resource). The maximum number of participants that can be added in a single request is 10.
]: any -> record<account_sid: string, chat_service_sid: string, messaging_service_sid: string, sid: string, friendly_name: string, unique_name: string, attributes: string, state: string, date_created: string, date_updated: string, timers: any, links: record, bindings: any, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/ConversationWithParticipants")
  let body = {FriendlyName: $FriendlyName, UniqueName: $UniqueName, DateCreated: $DateCreated, DateUpdated: $DateUpdated, MessagingServiceSid: $MessagingServiceSid, Attributes: $Attributes, State: $State, Timers.Inactive: $TimersInactive, Timers.Closed: $TimersClosed, Bindings.Email.Address: $BindingsEmailAddress, Bindings.Email.Name: $BindingsEmailName, Participant: $Participant} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Update push notification service settings
#
# POST /v1/Services/{ChatServiceSid}/Configuration/Notifications
# operationId: UpdateServiceNotification
export def "services-configuration-notifications UpdateServiceNotification" [
  ChatServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --LogEnabled: string@bool-completer # Weather the notification logging is enabled.
  --NewMessageEnabled: string@bool-completer # Whether to send a notification when a new message is added to a conversation. The default is `false`.
  --NewMessageTemplate: string # The template to use to create the notification text displayed when a new message is added to a conversation and `new_message.enabled` is `true`.
  --NewMessageSound: string # The name of the sound to play when a new message is added to a conversation and `new_message.enabled` is `true`.
  --NewMessageBadgeCountEnabled: string@bool-completer # Whether the new message badge is enabled. The default is `false`.
  --AddedToConversationEnabled: string@bool-completer # Whether to send a notification when a participant is added to a conversation. The default is `false`.
  --AddedToConversationTemplate: string # The template to use to create the notification text displayed when a participant is added to a conversation and `added_to_conversation.enabled` is `true`.
  --AddedToConversationSound: string # The name of the sound to play when a participant is added to a conversation and `added_to_conversation.enabled` is `true`.
  --RemovedFromConversationEnabled: string@bool-completer # Whether to send a notification to a user when they are removed from a conversation. The default is `false`.
  --RemovedFromConversationTemplate: string # The template to use to create the notification text displayed to a user when they are removed from a conversation and `removed_from_conversation.enabled` is `true`.
  --RemovedFromConversationSound: string # The name of the sound to play to a user when they are removed from a conversation and `removed_from_conversation.enabled` is `true`.
  --NewMessageWithMediaEnabled: string@bool-completer # Whether to send a notification when a new message with media/file attachments is added to a conversation. The default is `false`.
  --NewMessageWithMediaTemplate: string # The template to use to create the notification text displayed when a new message with media/file attachments is added to a conversation and `new_message.attachments.enabled` is `true`.
]: any -> record<account_sid: string, chat_service_sid: string, new_message: any, added_to_conversation: any, removed_from_conversation: any, log_enabled: bool, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Configuration/Notifications")
  let body = {LogEnabled: $LogEnabled, NewMessage.Enabled: $NewMessageEnabled, NewMessage.Template: $NewMessageTemplate, NewMessage.Sound: $NewMessageSound, NewMessage.BadgeCountEnabled: $NewMessageBadgeCountEnabled, AddedToConversation.Enabled: $AddedToConversationEnabled, AddedToConversation.Template: $AddedToConversationTemplate, AddedToConversation.Sound: $AddedToConversationSound, RemovedFromConversation.Enabled: $RemovedFromConversationEnabled, RemovedFromConversation.Template: $RemovedFromConversationTemplate, RemovedFromConversation.Sound: $RemovedFromConversationSound, NewMessage.WithMedia.Enabled: $NewMessageWithMediaEnabled, NewMessage.WithMedia.Template: $NewMessageWithMediaTemplate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Fetch push notification service settings
#
# GET /v1/Services/{ChatServiceSid}/Configuration/Notifications
# operationId: FetchServiceNotification
export def "services-configuration-notifications FetchServiceNotification" [
  ChatServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, chat_service_sid: string, new_message: any, added_to_conversation: any, removed_from_conversation: any, log_enabled: bool, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Configuration/Notifications")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of all Conversations that this Participant belongs to by identity or by address. Only one parameter should be specified.
#
# GET /v1/Services/{ChatServiceSid}/ParticipantConversations
# operationId: ListServiceParticipantConversation
export def "services-participant-conversations ListServiceParticipantConversation" [
  ChatServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Identity: string # A unique string identifier for the conversation participant as [Conversation User](https://www.twilio.com/docs/conversations/api/user-resource). This parameter is non-null if (and only if) the participant is using the Conversations SDK to communicate. Limited to 256 characters.
  --Address: string # A unique string identifier for the conversation participant who's not a Conversation User. This parameter could be found in messaging_binding.address field of Participant resource. It should be url-encoded.
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 50. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<conversations: table<account_sid: string, chat_service_sid: string, participant_sid: string, participant_user_sid: string, participant_identity: string, participant_messaging_binding: any, conversation_sid: string, conversation_unique_name: string, conversation_friendly_name: string, conversation_attributes: string, conversation_date_created: string, conversation_date_updated: string, conversation_created_by: string, conversation_state: string, conversation_timers: any, links: record>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "Identity" $Identity "scalar") (serialize-qp "Address" $Address "scalar") (serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/ParticipantConversations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new user role in your service
#
# POST /v1/Services/{ChatServiceSid}/Roles
# operationId: CreateServiceRole
export def "services-roles CreateServiceRole" [
  ChatServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  FriendlyName: string # A descriptive string that you create to describe the new resource. It can be up to 64 characters long.
  Type: string@Type-completer-2 # The type of role. Can be: `conversation` for [Conversation](https://www.twilio.com/docs/conversations/api/conversation-resource) roles or `service` for [Conversation Service](https://www.twilio.com/docs/conversations/api/service-resource) roles.
  Permission: list # A permission that you grant to the new role. Only one permission can be granted per parameter. To assign more than one permission, repeat this parameter for each permission value. The values for this parameter depend on the role's `type`.
]: any -> record<sid: string, account_sid: string, chat_service_sid: string, friendly_name: string, type: string, permissions: list<string>, date_created: string, date_updated: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Roles")
  let body = {FriendlyName: $FriendlyName, Type: $Type, Permission: $Permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of all user roles in your service
#
# GET /v1/Services/{ChatServiceSid}/Roles
# operationId: ListServiceRole
export def "services-roles ListServiceRole" [
  ChatServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 50. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<roles: table<sid: string, account_sid: string, chat_service_sid: string, friendly_name: string, type: string, permissions: list, date_created: string, date_updated: string, url: string>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Roles" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing user role in your service
#
# POST /v1/Services/{ChatServiceSid}/Roles/{Sid}
# operationId: UpdateServiceRole
export def "services-roles UpdateServiceRole" [
  ChatServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  Permission: list # A permission that you grant to the role. Only one permission can be granted per parameter. To assign more than one permission, repeat this parameter for each permission value. Note that the update action replaces all previously assigned permissions with those defined in the update action. To remove a permission, do not include it in the subsequent update action. The values for this parameter depend on the role's `type`.
]: any -> record<sid: string, account_sid: string, chat_service_sid: string, friendly_name: string, type: string, permissions: list<string>, date_created: string, date_updated: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Roles/($Sid)")
  let body = {Permission: $Permission} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove a user role from your service
#
# DELETE /v1/Services/{ChatServiceSid}/Roles/{Sid}
# operationId: DeleteServiceRole
export def "services-roles DeleteServiceRole" [
  ChatServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Roles/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a user role from your service
#
# GET /v1/Services/{ChatServiceSid}/Roles/{Sid}
# operationId: FetchServiceRole
export def "services-roles FetchServiceRole" [
  ChatServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sid: string, account_sid: string, chat_service_sid: string, friendly_name: string, type: string, permissions: list<string>, date_created: string, date_updated: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Roles/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a new conversation user to your service
#
# POST /v1/Services/{ChatServiceSid}/Users
# operationId: CreateServiceUser
export def "services-users CreateServiceUser" [
  ChatServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  Identity: string # The application-defined string that uniquely identifies the resource's User within the [Conversation Service](https://www.twilio.com/docs/conversations/api/service-resource). This value is often a username or an email address, and is case-sensitive.
  --FriendlyName: string # The string that you assigned to describe the resource.
  --Attributes: string # The JSON Object string that stores application-specific data. If attributes have not been set, `{}` is returned.
  --RoleSid: string # The SID of a service-level [Role](https://www.twilio.com/docs/conversations/api/role-resource) to assign to the user.
]: any -> record<sid: string, account_sid: string, chat_service_sid: string, role_sid: string, identity: string, friendly_name: string, attributes: string, is_online: bool, is_notifiable: bool, date_created: string, date_updated: string, url: string, links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Users")
  let body = {Identity: $Identity, FriendlyName: $FriendlyName, Attributes: $Attributes, RoleSid: $RoleSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of all conversation users in your service
#
# GET /v1/Services/{ChatServiceSid}/Users
# operationId: ListServiceUser
export def "services-users ListServiceUser" [
  ChatServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 50. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<users: table<sid: string, account_sid: string, chat_service_sid: string, role_sid: string, identity: string, friendly_name: string, attributes: string, is_online: bool, is_notifiable: bool, date_created: string, date_updated: string, url: string, links: record>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing conversation user in your service
#
# POST /v1/Services/{ChatServiceSid}/Users/{Sid}
# operationId: UpdateServiceUser
export def "services-users UpdateServiceUser" [
  ChatServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --FriendlyName: string # The string that you assigned to describe the resource.
  --Attributes: string # The JSON Object string that stores application-specific data. If attributes have not been set, `{}` is returned.
  --RoleSid: string # The SID of a service-level [Role](https://www.twilio.com/docs/conversations/api/role-resource) to assign to the user.
]: any -> record<sid: string, account_sid: string, chat_service_sid: string, role_sid: string, identity: string, friendly_name: string, attributes: string, is_online: bool, is_notifiable: bool, date_created: string, date_updated: string, url: string, links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Users/($Sid)")
  let body = {FriendlyName: $FriendlyName, Attributes: $Attributes, RoleSid: $RoleSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove a conversation user from your service
#
# DELETE /v1/Services/{ChatServiceSid}/Users/{Sid}
# operationId: DeleteServiceUser
export def "services-users DeleteServiceUser" [
  ChatServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Users/($Sid)")
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a conversation user from your service
#
# GET /v1/Services/{ChatServiceSid}/Users/{Sid}
# operationId: FetchServiceUser
export def "services-users FetchServiceUser" [
  ChatServiceSid: string
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sid: string, account_sid: string, chat_service_sid: string, role_sid: string, identity: string, friendly_name: string, attributes: string, is_online: bool, is_notifiable: bool, date_created: string, date_updated: string, url: string, links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Users/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a specific User Conversation.
#
# POST /v1/Services/{ChatServiceSid}/Users/{UserSid}/Conversations/{ConversationSid}
# operationId: UpdateServiceUserConversation
export def "services-users-conversations UpdateServiceUserConversation" [
  ChatServiceSid: string
  UserSid: string
  ConversationSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --NotificationLevel: string@NotificationLevel-completer # The Notification Level of this User Conversation. One of `default` or `muted`.
  --LastReadTimestamp: string # The date of the last message read in conversation by the user, given in ISO 8601 format. (format: date-time)
  --LastReadMessageIndex: int # The index of the last Message in the Conversation that the Participant has read. (nullable)
]: any -> record<account_sid: string, chat_service_sid: string, conversation_sid: string, unread_messages_count: int, last_read_message_index: int, participant_sid: string, user_sid: string, friendly_name: string, conversation_state: string, timers: any, attributes: string, date_created: string, date_updated: string, created_by: string, notification_level: string, unique_name: string, url: string, links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Users/($UserSid)/Conversations/($ConversationSid)")
  let body = {NotificationLevel: $NotificationLevel, LastReadTimestamp: $LastReadTimestamp, LastReadMessageIndex: $LastReadMessageIndex} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a specific User Conversation.
#
# DELETE /v1/Services/{ChatServiceSid}/Users/{UserSid}/Conversations/{ConversationSid}
# operationId: DeleteServiceUserConversation
export def "services-users-conversations DeleteServiceUserConversation" [
  ChatServiceSid: string
  UserSid: string
  ConversationSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Users/($UserSid)/Conversations/($ConversationSid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a specific User Conversation.
#
# GET /v1/Services/{ChatServiceSid}/Users/{UserSid}/Conversations/{ConversationSid}
# operationId: FetchServiceUserConversation
export def "services-users-conversations FetchServiceUserConversation" [
  ChatServiceSid: string
  UserSid: string
  ConversationSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, chat_service_sid: string, conversation_sid: string, unread_messages_count: int, last_read_message_index: int, participant_sid: string, user_sid: string, friendly_name: string, conversation_state: string, timers: any, attributes: string, date_created: string, date_updated: string, created_by: string, notification_level: string, unique_name: string, url: string, links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Users/($UserSid)/Conversations/($ConversationSid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of all User Conversations for the User.
#
# GET /v1/Services/{ChatServiceSid}/Users/{UserSid}/Conversations
# operationId: ListServiceUserConversation
export def "services-users-conversations ListServiceUserConversation" [
  ChatServiceSid: string
  UserSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 50. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<conversations: table<account_sid: string, chat_service_sid: string, conversation_sid: string, unread_messages_count: int, last_read_message_index: int, participant_sid: string, user_sid: string, friendly_name: string, conversation_state: string, timers: any, attributes: string, date_created: string, date_updated: string, created_by: string, notification_level: string, unique_name: string, url: string, links: record>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Users/($UserSid)/Conversations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a specific Webhook.
#
# POST /v1/Services/{ChatServiceSid}/Configuration/Webhooks
# operationId: UpdateServiceWebhookConfiguration
export def "services-configuration-webhooks UpdateServiceWebhookConfiguration" [
  ChatServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PreWebhookUrl: string # The absolute url the pre-event webhook request should be sent to. (format: uri)
  --PostWebhookUrl: string # The absolute url the post-event webhook request should be sent to. (format: uri)
  --Filters: list # The list of events that your configured webhook targets will receive. Events not configured here will not fire. Possible values are `onParticipantAdd`, `onParticipantAdded`, `onDeliveryUpdated`, `onConversationUpdated`, `onConversationRemove`, `onParticipantRemove`, `onConversationUpdate`, `onMessageAdd`, `onMessageRemoved`, `onParticipantUpdated`, `onConversationAdded`, `onMessageAdded`, `onConversationAdd`, `onConversationRemoved`, `onParticipantUpdate`, `onMessageRemove`, `onMessageUpdated`, `onParticipantRemoved`, `onMessageUpdate` or `onConversationStateUpdated`.
  --Method: string # The HTTP method to be used when sending a webhook request. One of `GET` or `POST`.
]: any -> record<account_sid: string, chat_service_sid: string, pre_webhook_url: string, post_webhook_url: string, filters: list<string>, method: string, url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Configuration/Webhooks")
  let body = {PreWebhookUrl: $PreWebhookUrl, PostWebhookUrl: $PostWebhookUrl, Filters: $Filters, Method: $Method} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Fetch a specific service webhook configuration.
#
# GET /v1/Services/{ChatServiceSid}/Configuration/Webhooks
# operationId: FetchServiceWebhookConfiguration
export def "services-configuration-webhooks FetchServiceWebhookConfiguration" [
  ChatServiceSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, chat_service_sid: string, pre_webhook_url: string, post_webhook_url: string, filters: list<string>, method: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Services/($ChatServiceSid)/Configuration/Webhooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a new conversation user to your account's default service
#
# POST /v1/Users
# operationId: CreateUser
export def "users CreateUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  Identity: string # The application-defined string that uniquely identifies the resource's User within the [Conversation Service](https://www.twilio.com/docs/conversations/api/service-resource). This value is often a username or an email address, and is case-sensitive.
  --FriendlyName: string # The string that you assigned to describe the resource.
  --Attributes: string # The JSON Object string that stores application-specific data. If attributes have not been set, `{}` is returned.
  --RoleSid: string # The SID of a service-level [Role](https://www.twilio.com/docs/conversations/api/role-resource) to assign to the user.
]: any -> record<sid: string, account_sid: string, chat_service_sid: string, role_sid: string, identity: string, friendly_name: string, attributes: string, is_online: bool, is_notifiable: bool, date_created: string, date_updated: string, url: string, links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base "/v1/Users")
  let body = {Identity: $Identity, FriendlyName: $FriendlyName, Attributes: $Attributes, RoleSid: $RoleSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Retrieve a list of all conversation users in your account's default service
#
# GET /v1/Users
# operationId: ListUser
export def "users ListUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 50. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<users: table<sid: string, account_sid: string, chat_service_sid: string, role_sid: string, identity: string, friendly_name: string, attributes: string, is_online: bool, is_notifiable: bool, date_created: string, date_updated: string, url: string, links: record>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/Users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing conversation user in your account's default service
#
# POST /v1/Users/{Sid}
# operationId: UpdateUser
export def "users UpdateUser" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
  --FriendlyName: string # The string that you assigned to describe the resource.
  --Attributes: string # The JSON Object string that stores application-specific data. If attributes have not been set, `{}` is returned.
  --RoleSid: string # The SID of a service-level [Role](https://www.twilio.com/docs/conversations/api/role-resource) to assign to the user.
]: any -> record<sid: string, account_sid: string, chat_service_sid: string, role_sid: string, identity: string, friendly_name: string, attributes: string, is_online: bool, is_notifiable: bool, date_created: string, date_updated: string, url: string, links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Users/($Sid)")
  let body = {FriendlyName: $FriendlyName, Attributes: $Attributes, RoleSid: $RoleSid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Remove a conversation user from your account's default service
#
# DELETE /v1/Users/{Sid}
# operationId: DeleteUser
export def "users DeleteUser" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Twilio-Webhook-Enabled: string@X-Twilio-Webhook-Enabled-completer # The X-Twilio-Webhook-Enabled HTTP request header
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Users/($Sid)")
  let extra_headers = {"X-Twilio-Webhook-Enabled": $X_Twilio_Webhook_Enabled} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a conversation user from your account's default service
#
# GET /v1/Users/{Sid}
# operationId: FetchUser
export def "users FetchUser" [
  Sid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<sid: string, account_sid: string, chat_service_sid: string, role_sid: string, identity: string, friendly_name: string, attributes: string, is_online: bool, is_notifiable: bool, date_created: string, date_updated: string, url: string, links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Users/($Sid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a specific User Conversation.
#
# POST /v1/Users/{UserSid}/Conversations/{ConversationSid}
# operationId: UpdateUserConversation
export def "users-conversations UpdateUserConversation" [
  UserSid: string
  ConversationSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --NotificationLevel: string@NotificationLevel-completer # The Notification Level of this User Conversation. One of `default` or `muted`.
  --LastReadTimestamp: string # The date of the last message read in conversation by the user, given in ISO 8601 format. (format: date-time)
  --LastReadMessageIndex: int # The index of the last Message in the Conversation that the Participant has read. (nullable)
]: any -> record<account_sid: string, chat_service_sid: string, conversation_sid: string, unread_messages_count: int, last_read_message_index: int, participant_sid: string, user_sid: string, friendly_name: string, conversation_state: string, timers: any, attributes: string, date_created: string, date_updated: string, created_by: string, notification_level: string, unique_name: string, url: string, links: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Users/($UserSid)/Conversations/($ConversationSid)")
  let body = {NotificationLevel: $NotificationLevel, LastReadTimestamp: $LastReadTimestamp, LastReadMessageIndex: $LastReadMessageIndex} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/x-www-form-urlencoded" $body
}

# Delete a specific User Conversation.
#
# DELETE /v1/Users/{UserSid}/Conversations/{ConversationSid}
# operationId: DeleteUserConversation
export def "users-conversations DeleteUserConversation" [
  UserSid: string
  ConversationSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Users/($UserSid)/Conversations/($ConversationSid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch a specific User Conversation.
#
# GET /v1/Users/{UserSid}/Conversations/{ConversationSid}
# operationId: FetchUserConversation
export def "users-conversations FetchUserConversation" [
  UserSid: string
  ConversationSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<account_sid: string, chat_service_sid: string, conversation_sid: string, unread_messages_count: int, last_read_message_index: int, participant_sid: string, user_sid: string, friendly_name: string, conversation_state: string, timers: any, attributes: string, date_created: string, date_updated: string, created_by: string, notification_level: string, unique_name: string, url: string, links: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let full_url = (build-url $base $"/v1/Users/($UserSid)/Conversations/($ConversationSid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a list of all User Conversations for the User.
#
# GET /v1/Users/{UserSid}/Conversations
# operationId: ListUserConversation
export def "users-conversations ListUserConversation" [
  UserSid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --PageSize: int # How many resources to return in each list page. The default is 50, and the maximum is 50. (format: int64)
  --Page: int # The page index. This value is simply for client state.
  --PageToken: string # The page token. This is provided by the API.
]: nothing -> record<conversations: table<account_sid: string, chat_service_sid: string, conversation_sid: string, unread_messages_count: int, last_read_message_index: int, participant_sid: string, user_sid: string, friendly_name: string, conversation_state: string, timers: any, attributes: string, date_created: string, date_updated: string, created_by: string, notification_level: string, unique_name: string, url: string, links: record>, meta: record<first_page_url: string, key: string, next_page_url: string, page: int, page_size: int, previous_page_url: string, url: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default "https://conversations.twilio.com")
  let qp = [(serialize-qp "PageSize" $PageSize "scalar") (serialize-qp "Page" $Page "scalar") (serialize-qp "PageToken" $PageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/Users/($UserSid)/Conversations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
