# Auto-generated client for Novu API v3.17.1
# Source: https://api.novu.co/openapi.json
# Auth: --token flag or $env.NOVU_API_TOKEN

const BASE_URL = "https://api.novu.co"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o NOVU_API_TOKEN | default "" }
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://api.novu.co" "https://eu.api.novu.co"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def orderDirection-completer [] { ["ASC" "DESC"] }
def type-completer [] { ["agent" "webhook"] }
def channel-completer [] { ["chat" "email" "in_app" "push" "sms"] }
def kind-completer [] { ["agent" "delivery"] }
def mode-completer [] { ["connect" "link_user"] }
def connectionMode-completer [] { ["shared" "subscriber"] }
def providerId-completer [] { ["apns" "appio" "chat-webhook" "discord" "expo" "fcm" "getstream" "grafana-on-call" "mattermost" "msteams" "novu-slack" "one-signal" "push-webhook" "pusher-beams" "pushpad" "rocket-chat" "ryver" "slack" "telegram" "whatsapp-business" "zulip"] }
def markAs-completer [] { ["read" "seen" "unread" "unseen"] }
def status-completer [] { ["done" "pending"] }
def criticality-completer [] { ["all" "critical" "nonCritical"] }
def source-completer [] { ["dashboard"] }
def orderBy-completer [] { ["createdAt" "name" "updatedAt"] }
def type-completer-1 [] { ["string"] }
def source-completer-1 [] { ["ai" "bridge" "dashboard" "dropdown" "editor" "empty_state" "notification_directory" "onboarding_digest_demo" "onboarding_get_started" "onboarding_in_app" "template_store"] }
def severity-completer [] { ["high" "low" "medium" "none"] }
def orderBy-completer-1 [] { ["createdAt" "lastTriggeredAt" "name" "updatedAt"] }
def origin-completer [] { ["external" "novu-cloud" "novu-cloud-v1"] }
def providerId-completer-1 [] { ["africas-talking" "afro-message" "anthropic" "anthropic-aws" "apns" "appio" "azure-sms" "bandwidth" "braze" "brevo-sms" "bulk-sms" "burst-sms" "chat-webhook" "clickatell" "clicksend" "cm-telecom" "discord" "eazy-sms" "email-webhook" "emailjs" "expo" "fcm" "firetext" "forty-six-elks" "generic-sms" "getstream" "grafana-on-call" "gupshup" "imedia" "infobip-email" "infobip-sms" "isend-sms" "isendpro-sms" "kannel" "mailersend" "mailgun" "mailjet" "mailtrap" "mandrill" "maqsam" "mattermost" "messagebird" "mobishastra" "msteams" "netcore" "nexmo" "nodemailer" "novu" "novu-anthropic" "novu-email" "novu-email-agent" "novu-slack" "novu-sms" "one-signal" "outlook365" "plivo" "plunk" "postmark" "push-webhook" "pusher-beams" "pushpad" "resend" "ring-central" "rocket-chat" "ryver" "sendchamp" "sendgrid" "sendinblue" "ses" "simpletexting" "sinch" "slack" "sms-central" "sms77" "smsmode" "sns" "sparkpost" "telegram" "telnyx" "termii" "twilio" "unifonic" "whatsapp-business" "zulip"] }
def type-completer-2 [] { ["ms_teams_channel" "ms_teams_user" "phone" "slack_channel" "slack_user" "telegram_chat" "webhook"] }
def resourceType-completer [] { ["layout" "workflow"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "environments createEnvironment" } } | get name | first)
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

# Create an environment
#
# POST /v1/environments
# operationId: EnvironmentsControllerV1_createEnvironment
export def "environments createEnvironment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the environment to be created (e.g. Production Environment)
  --parentId: string # MongoDB ObjectId of the parent environment (optional) (e.g. 60d5ecb8b3b3a30015f3e1a1)
  color: string # Hex color code for the environment (e.g. #3498db)
]: any -> record<data: record<_id: string, name: string, _organizationId: string, identifier: string, type: string, apiKeys: list<record>, _parentId: string, slug: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/environments")
  let body = {name: $name, parentId: $parentId, color: $color} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all environments
#
# GET /v1/environments
# operationId: EnvironmentsControllerV1_listMyEnvironments
export def "environments listMyEnvironments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<_id: string, name: string, _organizationId: string, identifier: string, type: string, apiKeys: list, _parentId: string, slug: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/environments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an environment
#
# PUT /v1/environments/{environmentId}
# operationId: EnvironmentsControllerV1_updateMyEnvironment
# --dns shape: {inboundParseDomain?: string}
# --bridge shape: {url?: string}
export def "environments updateMyEnvironment" [
  environmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --identifier: string
  --parentId: string
  --color: string
  --dns: record # shape: {inboundParseDomain?: string}
  --bridge: record # shape: {url?: string}
]: any -> record<data: record<_id: string, name: string, _organizationId: string, identifier: string, type: string, apiKeys: list<record>, _parentId: string, slug: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/environments/($environmentId)")
  let body = {name: $name, identifier: $identifier, parentId: $parentId, color: $color, dns: $dns, bridge: $bridge} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an environment
#
# DELETE /v1/environments/{environmentId}
# operationId: EnvironmentsControllerV1_deleteEnvironment
export def "environments delete" [
  environmentId: string
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
  let full_url = (build-url $base $"/v1/environments/($environmentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trigger event
#
# POST /v1/events/trigger
# operationId: EventsController_trigger
export def "events-trigger trigger" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The trigger identifier of the workflow you wish to send. This identifier can be found on the workflow page. (e.g. workflow_identifier)
  --payload: record # The payload object is used to pass additional custom information that could be      used to render the workflow, or perform routing rules based on it.        This data will also be available when fetching the notifications feed from the API to display certain parts of the UI. (e.g. {comment_id: string, post: {text: string}})
  --overrides: any # This could be used to override provider specific configurations (e.g. {fcm: {data: {key: value}}})
  --body-to: any # The recipients list of people who will receive the notification. Maximum number of recipients can be 100.
  --transactionId: string # A unique identifier for deduplication. If the same **transactionId** is sent again,        the trigger is ignored. Useful to prevent duplicate notifications. The retention period depends on your billing tier.
  --actor: any # It is used to display the Avatar of the provided actor's subscriber id or actor object.     If a new actor object is provided, we will create a new subscriber in our system
  --tenant: any # It is used to specify a tenant context during trigger event.     Existing tenants will be updated with the provided details.
  --context: record
]: any -> record<data: record<acknowledged: bool, status: string, error: list<string>, transactionId: string, activityFeedLink: string, jobData: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/events/trigger")
  let body = {name: $name, payload: $payload, overrides: $overrides, to: $body_to, transactionId: $transactionId, actor: $actor, tenant: $tenant, context: $context} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk trigger event
#
# POST /v1/events/trigger/bulk
# operationId: EventsController_triggerBulk
# --events item shape: {name: string, payload?: record, overrides?: any, to: any, transactionId?: string, actor?: any, tenant?: any, context?: record}
export def "events-trigger-bulk triggerBulk" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  events: list # item shape: {name: string, payload?: record, overrides?: any, to: any, transactionId?: string, actor?: any, tenant?: any, context?: record}
]: any -> record<data: table<acknowledged: bool, status: string, error: list, transactionId: string, activityFeedLink: string, jobData: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/events/trigger/bulk")
  let body = {events: $events} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Broadcast event to all
#
# POST /v1/events/trigger/broadcast
# operationId: EventsController_broadcastEventToAll
export def "events-trigger-broadcast broadcastEventToAll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The trigger identifier associated for the template you wish to send. This identifier can be found on the template page.
  payload: record # The payload object is used to pass additional information that      could be used to render the template, or perform routing rules based on it.        For In-App channel, payload data are also available in <Inbox /> (e.g. {comment_id: string, post: {text: string}})
  --overrides: any # This could be used to override provider specific configurations (e.g. {fcm: {data: {key: value}}})
  --transactionId: string # A unique identifier for this transaction, we will generated a UUID if not provided.
  --actor: any # It is used to display the Avatar of the provided actor's subscriber id or actor object.     If a new actor object is provided, we will create a new subscriber in our system     
  --tenant: any # It is used to specify a tenant context during trigger event.     If a new tenant object is provided, we will create a new tenant.     
  --context: record
]: any -> record<data: record<acknowledged: bool, status: string, error: list<string>, transactionId: string, activityFeedLink: string, jobData: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/events/trigger/broadcast")
  let body = {name: $name, payload: $payload, overrides: $overrides, transactionId: $transactionId, actor: $actor, tenant: $tenant, context: $context} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Cancel triggered event
#
# DELETE /v1/events/trigger/{transactionId}
# operationId: EventsController_cancel
export def "events-trigger cancel" [
  transactionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> bool {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/events/trigger/($transactionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all events
#
# GET /v1/notifications
# operationId: NotificationsController_listNotifications
@deprecated --flag search
export def "notifications listNotifications" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --channels: list # Array of channel types
  --templates: list # Array of template IDs or a single template ID
  --emails: list # Array of email addresses or a single email address
  --search: string # Search term (deprecated) (DEPRECATED)
  --subscriberIds: list # Array of subscriber IDs or a single subscriber ID
  --severity: list # Array of severity levels or a single severity level
  --page: float # Page number for pagination (default: 0)
  --limit: float # Limit for pagination (default: 10)
  --transactionId: string # The transaction ID to filter by
  --topicKey: string # Topic Key for filtering notifications by topic
  --subscriptionId: string # Subscription ID for filtering notifications by subscription
  --contextKeys: list # Filter by exact context keys, order insensitive (format: "type:id")
  --after: string # Date filter for records after this timestamp. Defaults to earliest date allowed by subscription plan
  --before: string # Date filter for records before this timestamp. Defaults to current time of request (now)
]: nothing -> record<hasMore: bool, data: table<_id: string, _environmentId: string, _organizationId: string, _subscriberId: string, transactionId: string, _templateId: string, _digestedNotificationId: string, createdAt: string, updatedAt: string, channels: list, subscriber: record, template: record, jobs: list, payload: record, tags: list, controls: record, to: record, topics: list, severity: string, critical: bool, contextKeys: list>, pageSize: float, page: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "channels" $channels "multi") (serialize-qp "templates" $templates "multi") (serialize-qp "emails" $emails "multi") (serialize-qp "search" $search "scalar") (serialize-qp "subscriberIds" $subscriberIds "multi") (serialize-qp "severity" $severity "multi") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "transactionId" $transactionId "scalar") (serialize-qp "topicKey" $topicKey "scalar") (serialize-qp "subscriptionId" $subscriptionId "scalar") (serialize-qp "contextKeys" $contextKeys "multi") (serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/notifications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve an event
#
# GET /v1/notifications/{notificationId}
# operationId: NotificationsController_getNotification
export def "notifications get" [
  notificationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<_id: string, _environmentId: string, _organizationId: string, _subscriberId: string, transactionId: string, _templateId: string, _digestedNotificationId: string, createdAt: string, updatedAt: string, channels: list<string>, subscriber: record<firstName: string, subscriberId: string, _id: string, lastName: string, email: string, phone: string>, template: record<_id: string, name: string, origin: string, triggers: list>, jobs: list<record>, payload: record, tags: list<string>, controls: record, to: record, topics: list<record>, severity: string, critical: bool, contextKeys: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/notifications/($notificationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List domains for an environment
#
# GET /v1/domains
# operationId: DomainsController_listDomains
export def "domains listDomains" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string # Cursor for pagination indicating the starting point after which to fetch results.
  --before: string # Cursor for pagination indicating the ending point before which to fetch results.
  --limit: float # Limit the number of items to return (e.g. 10)
  --orderDirection: string@orderDirection-completer # Direction of sorting
  --orderBy: string # Field to order by
  --includeCursor: string@bool-completer # Include cursor item in response
  --name: string # Domain name to filter results by.
]: nothing -> record<data: record<data: list<record>, next: string, previous: string, totalCount: float, totalCountCapped: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "orderDirection" $orderDirection "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "includeCursor" $includeCursor "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/domains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a domain
#
# POST /v1/domains
# operationId: DomainsController_createDomain
export def "domains createDomain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The domain name (e.g. "recent.dev")
  --data: record # Optional string key-value metadata (max 10 keys, 500 characters total for keys+values).
]: any -> record<data: record<_id: string, name: string, status: string, mxRecordConfigured: bool, dnsProvider: string, _environmentId: string, _organizationId: string, createdAt: string, updatedAt: string, expectedDnsRecords: list<record>, data: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/domains")
  let body = {name: $name, data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a domain by name
#
# GET /v1/domains/{domain}
# operationId: DomainsController_getDomain
export def "domains get" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<_id: string, name: string, status: string, mxRecordConfigured: bool, dnsProvider: string, _environmentId: string, _organizationId: string, createdAt: string, updatedAt: string, expectedDnsRecords: list<record>, data: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/domains/($domain)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a domain
#
# PATCH /v1/domains/{domain}
# operationId: DomainsController_updateDomain
export def "domains updateDomain" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --data: record # Replaces domain metadata when provided (max 10 keys, 500 characters total for keys+values).
]: any -> record<data: record<_id: string, name: string, status: string, mxRecordConfigured: bool, dnsProvider: string, _environmentId: string, _organizationId: string, createdAt: string, updatedAt: string, expectedDnsRecords: list<record>, data: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/domains/($domain)")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a domain
#
# DELETE /v1/domains/{domain}
# operationId: DomainsController_deleteDomain
export def "domains delete" [
  domain: string
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
  let full_url = (build-url $base $"/v1/domains/($domain)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verify a domain
#
# POST /v1/domains/{domain}/verify
# operationId: DomainsController_verifyDomain
export def "domains-verify verifyDomain" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<_id: string, name: string, status: string, mxRecordConfigured: bool, dnsProvider: string, _environmentId: string, _organizationId: string, createdAt: string, updatedAt: string, expectedDnsRecords: list<record>, data: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/domains/($domain)/verify")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Diagnose inbound DNS for a domain
#
# POST /v1/domains/{domain}/diagnose
# operationId: DomainsController_diagnoseDomain
export def "domains-diagnose diagnoseDomain" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<ok: bool, runAt: string, checks: list<record>, issues: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/domains/($domain)/diagnose")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List routes for a domain
#
# GET /v1/domains/{domain}/routes
# operationId: DomainsController_listDomainRoutes
export def "domains-routes listDomainRoutes" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string # Cursor for pagination indicating the starting point after which to fetch results.
  --before: string # Cursor for pagination indicating the ending point before which to fetch results.
  --limit: float # Limit the number of items to return (e.g. 10)
  --orderDirection: string@orderDirection-completer # Direction of sorting
  --orderBy: string # Field to order by
  --includeCursor: string@bool-completer # Include cursor item in response
  --agentId: string # Agent identifier to filter routes by.
]: nothing -> record<data: record<data: list<record>, next: string, previous: string, totalCount: float, totalCountCapped: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "orderDirection" $orderDirection "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "includeCursor" $includeCursor "scalar") (serialize-qp "agentId" $agentId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/domains/($domain)/routes" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a route
#
# POST /v1/domains/{domain}/routes
# operationId: DomainsController_createDomainRoute
export def "domains-routes createDomainRoute" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  address: string # Inbox address local part (e.g. "support", "*")
  --agentId: string # Agent identifier; required when type is agent, unused for webhook
  type: string@type-completer
  --data: record # Optional string key-value metadata (max 10 keys, 500 characters total for keys+values).
]: any -> record<data: record<_id: string, _domainId: string, address: string, agentId: string, type: string, _environmentId: string, _organizationId: string, createdAt: string, updatedAt: string, data: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/domains/($domain)/routes")
  let body = {address: $address, agentId: $agentId, type: $type, data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a route by address
#
# GET /v1/domains/{domain}/routes/{address}
# operationId: DomainsController_getDomainRoute
export def "domains-routes get" [
  domain: string
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<_id: string, _domainId: string, address: string, agentId: string, type: string, _environmentId: string, _organizationId: string, createdAt: string, updatedAt: string, data: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/domains/($domain)/routes/($address)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a route
#
# PATCH /v1/domains/{domain}/routes/{address}
# operationId: DomainsController_updateDomainRoute
export def "domains-routes updateDomainRoute" [
  domain: string
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --agentId: string # Agent identifier; required when type is agent, ignored when type is webhook.
  --type: string@type-completer
  --data: record # Replaces route metadata when provided (max 10 keys, 500 characters total for keys+values).
]: any -> record<data: record<_id: string, _domainId: string, address: string, agentId: string, type: string, _environmentId: string, _organizationId: string, createdAt: string, updatedAt: string, data: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/domains/($domain)/routes/($address)")
  let body = {agentId: $agentId, type: $type, data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a route
#
# DELETE /v1/domains/{domain}/routes/{address}
# operationId: DomainsController_deleteDomainRoute
export def "domains-routes delete" [
  domain: string
  address: string
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
  let full_url = (build-url $base $"/v1/domains/($domain)/routes/($address)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Test an inbound route
#
# POST /v1/domains/{domain}/routes/{address}/test
# operationId: DomainsController_testDomainRoute
# --from shape: {address: string, name?: string}
export def "domains-routes-test testDomainRoute" [
  domain: string
  address: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body-from: record # shape: {address: string, name?: string}
  subject: string
  --text: string
  --html: string
  --dryRun: string@bool-completer # When true, returns the payload that would be delivered without invoking outbound webhooks or the agent HTTP endpoint.
]: any -> record<data: record<matched: bool, dryRun: bool, domainStatus: string, mxRecordConfigured: bool, type: string, wouldDeliverTo: string, payload: record, webhook: record<skipped: bool, latencyMs: float>, agent: record<agentId: string, httpStatus: float, agentReply: record, latencyMs: float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/domains/($domain)/routes/($address)/test")
  let body = {from: $body_from, subject: $subject, text: $text, html: $html, dryRun: $dryRun} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve auto-configuration availability
#
# GET /v1/domains/{domain}/auto-configure
# operationId: DomainsController_getDomainAutoConfigure
export def "domains-auto-configure get" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<available: bool, providerName: string, providerId: string, reason: string, reasonCode: string, manualRecords: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/domains/($domain)/auto-configure")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Start DNS auto-configuration
#
# POST /v1/domains/{domain}/auto-configure/start
# operationId: DomainsController_startDomainAutoConfigure
export def "domains-auto-configure-start startDomainAutoConfigure" [
  domain: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --redirectUri: string # Dashboard URL to return to after the DNS provider consent flow completes.
]: any -> record<data: record<applyUrl: string, providerName: string, redirectUri: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/domains/($domain)/auto-configure/start")
  let body = {redirectUri: $redirectUri} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all integrations
#
# GET /v1/integrations
# operationId: IntegrationsController_listIntegrations
export def "integrations listIntegrations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<_id: string, _environmentId: string, _organizationId: string, name: string, identifier: string, providerId: string, channel: string, kind: string, credentials: record<apiKey: string, user: string, secretKey: string, domain: string, password: string, host: string, port: string, secure: bool, region: string, accountSid: string, messageProfileId: string, token: string, from: string, senderName: string, projectName: string, applicationId: string, clientId: string, requireTls: bool, ignoreTls: bool, tlsOptions: record, baseUrl: string, webhookUrl: string, redirectUrl: string, hmac: bool, serviceAccount: string, ipPoolName: string, apiKeyRequestHeader: string, secretKeyRequestHeader: string, idPath: string, datePath: string, apiToken: string, authenticateByToken: bool, authenticationTokenKey: string, instanceId: string, alertUid: string, title: string, imageUrl: string, state: string, externalLink: string, channelId: string, phoneNumberIdentification: string, accessKey: string, appSid: string, senderId: string, tenantId: string, AppIOBaseUrl: string, signingSecret: string, outboundIntegrationId: string, useFromAddressOverride: bool, fromAddressOverride: string, emailSlugPrefix: string, externalEnvironmentId: string, externalVaultId: string, externalWorkspaceId: string>, configurations: record<inboundWebhookEnabled: bool, inboundWebhookSigningKey: string>, active: bool, deleted: bool, deletedAt: string, deletedBy: string, primary: bool, conditions: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/integrations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an integration
#
# POST /v1/integrations
# operationId: IntegrationsController_createIntegration
# --conditions item shape: {isNegated: bool, type: "BOOLEAN"|"TEXT"|"DATE"|"NUMBER"|"STATEMENT"|"LIST"|"MULTI_LIST"|"GROUP", value: "AND"|"OR", children: list}
export def "integrations createIntegration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the integration
  --identifier: string # The unique identifier for the integration
  --environmentId: string # The ID of the associated environment (format: uuid)
  --providerId: string # The provider ID for the integration
  --channel: string@channel-completer # The channel type for the integration. Not required for agent-kind integrations.
  --kind: string@kind-completer # Distinguishes delivery integrations from agent-runtime integrations. Defaults to "delivery". Agent integrations do not require a channel.
  --credentials: any # The credentials for the integration
  --active: string@bool-completer # If the integration is active, the validation on the credentials field will run
  --check: string@bool-completer # Flag to check the integration status
  --conditions: list # Conditions for the integration — item shape: {isNegated: bool, type: "BOOLEAN"|"TEXT"|"DATE"|"NUMBER"|"STATEMENT"|"LIST"|"MULTI_LIST"|"GROUP", value: "AND"|"OR", children: list}
  --configurations: record # Configurations for the integration
]: any -> record<data: record<_id: string, _environmentId: string, _organizationId: string, name: string, identifier: string, providerId: string, channel: string, kind: string, credentials: record<apiKey: string, user: string, secretKey: string, domain: string, password: string, host: string, port: string, secure: bool, region: string, accountSid: string, messageProfileId: string, token: string, from: string, senderName: string, projectName: string, applicationId: string, clientId: string, requireTls: bool, ignoreTls: bool, tlsOptions: record, baseUrl: string, webhookUrl: string, redirectUrl: string, hmac: bool, serviceAccount: string, ipPoolName: string, apiKeyRequestHeader: string, secretKeyRequestHeader: string, idPath: string, datePath: string, apiToken: string, authenticateByToken: bool, authenticationTokenKey: string, instanceId: string, alertUid: string, title: string, imageUrl: string, state: string, externalLink: string, channelId: string, phoneNumberIdentification: string, accessKey: string, appSid: string, senderId: string, tenantId: string, AppIOBaseUrl: string, signingSecret: string, outboundIntegrationId: string, useFromAddressOverride: bool, fromAddressOverride: string, emailSlugPrefix: string, externalEnvironmentId: string, externalVaultId: string, externalWorkspaceId: string>, configurations: record<inboundWebhookEnabled: bool, inboundWebhookSigningKey: string>, active: bool, deleted: bool, deletedAt: string, deletedBy: string, primary: bool, conditions: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/integrations")
  let body = {name: $name, identifier: $identifier, _environmentId: $environmentId, providerId: $providerId, channel: $channel, kind: $kind, credentials: $credentials, active: $active, check: $check, conditions: $conditions, configurations: $configurations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List active integrations
#
# GET /v1/integrations/active
# operationId: IntegrationsController_getActiveIntegrations
export def "integrations-active get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> table<_id: string, _environmentId: string, _organizationId: string, name: string, identifier: string, providerId: string, channel: string, kind: string, credentials: record<apiKey: string, user: string, secretKey: string, domain: string, password: string, host: string, port: string, secure: bool, region: string, accountSid: string, messageProfileId: string, token: string, from: string, senderName: string, projectName: string, applicationId: string, clientId: string, requireTls: bool, ignoreTls: bool, tlsOptions: record, baseUrl: string, webhookUrl: string, redirectUrl: string, hmac: bool, serviceAccount: string, ipPoolName: string, apiKeyRequestHeader: string, secretKeyRequestHeader: string, idPath: string, datePath: string, apiToken: string, authenticateByToken: bool, authenticationTokenKey: string, instanceId: string, alertUid: string, title: string, imageUrl: string, state: string, externalLink: string, channelId: string, phoneNumberIdentification: string, accessKey: string, appSid: string, senderId: string, tenantId: string, AppIOBaseUrl: string, signingSecret: string, outboundIntegrationId: string, useFromAddressOverride: bool, fromAddressOverride: string, emailSlugPrefix: string, externalEnvironmentId: string, externalVaultId: string, externalWorkspaceId: string>, configurations: record<inboundWebhookEnabled: bool, inboundWebhookSigningKey: string>, active: bool, deleted: bool, deletedAt: string, deletedBy: string, primary: bool, conditions: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/integrations/active")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an integration
#
# PUT /v1/integrations/{integrationId}
# operationId: IntegrationsController_updateIntegrationById
# --credentials shape: {apiKey?: string, user?: string, secretKey?: string, domain?: string, password?: string, host?: string, port?: string, secure?: bool, region?: string, accountSid?: string, messageProfileId?: string, token?: string, from?: string, senderName?: string, projectName?: string, applicationId?: string, clientId?: string, requireTls?: bool, ignoreTls?: bool, tlsOptions?: record, baseUrl?: string, webhookUrl?: string, redirectUrl?: string, hmac?: bool, serviceAccount?: string, ipPoolName?: string, apiKeyRequestHeader?: string, secretKeyRequestHeader?: string, idPath?: string, datePath?: string, apiToken?: string, authenticateByToken?: bool, authenticationTokenKey?: string, instanceId?: string, alertUid?: string, title?: string, imageUrl?: string, state?: string, externalLink?: string, channelId?: string, phoneNumberIdentification?: string, accessKey?: string, appSid?: string, senderId?: string, tenantId?: string, AppIOBaseUrl?: string, signingSecret?: string, outboundIntegrationId?: string, useFromAddressOverride?: bool, fromAddressOverride?: string, emailSlugPrefix?: string, externalEnvironmentId?: string, externalVaultId?: string, externalWorkspaceId?: string}
# --conditions item shape: {isNegated: bool, type: "BOOLEAN"|"TEXT"|"DATE"|"NUMBER"|"STATEMENT"|"LIST"|"MULTI_LIST"|"GROUP", value: "AND"|"OR", children: list}
export def "integrations updateIntegrationById" [
  integrationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string
  --identifier: string
  --environmentId: string
  --active: string@bool-completer # If the integration is active the validation on the credentials field will run
  --credentials: record # shape: {apiKey?: string, user?: string, secretKey?: string, domain?: string, password?: string, host?: string, port?: string, secure?: bool, region?: string, accountSid?: string, messageProfileId?: string, token?: string, from?: string, senderName?: string, projectName?: string, applicationId?: string, clientId?: string, requireTls?: bool, ignoreTls?: bool, tlsOptions?: record, baseUrl?: string, webhookUrl?: string, redirectUrl?: string, hmac?: bool, serviceAccount?: string, ipPoolName?: string, apiKeyRequestHeader?: string, secretKeyRequestHeader?: string, idPath?: string, datePath?: string, apiToken?: string, authenticateByToken?: bool, authenticationTokenKey?: string, instanceId?: string, alertUid?: string, title?: string, imageUrl?: string, state?: string, externalLink?: string, channelId?: string, phoneNumberIdentification?: string, accessKey?: string, appSid?: string, senderId?: string, tenantId?: string, AppIOBaseUrl?: string, signingSecret?: string, outboundIntegrationId?: string, useFromAddressOverride?: bool, fromAddressOverride?: string, emailSlugPrefix?: string, externalEnvironmentId?: string, externalVaultId?: string, externalWorkspaceId?: string}
  --check: string@bool-completer
  --conditions: list # item shape: {isNegated: bool, type: "BOOLEAN"|"TEXT"|"DATE"|"NUMBER"|"STATEMENT"|"LIST"|"MULTI_LIST"|"GROUP", value: "AND"|"OR", children: list}
  --configurations: record # Configurations for the integration
]: any -> record<data: record<_id: string, _environmentId: string, _organizationId: string, name: string, identifier: string, providerId: string, channel: string, kind: string, credentials: record<apiKey: string, user: string, secretKey: string, domain: string, password: string, host: string, port: string, secure: bool, region: string, accountSid: string, messageProfileId: string, token: string, from: string, senderName: string, projectName: string, applicationId: string, clientId: string, requireTls: bool, ignoreTls: bool, tlsOptions: record, baseUrl: string, webhookUrl: string, redirectUrl: string, hmac: bool, serviceAccount: string, ipPoolName: string, apiKeyRequestHeader: string, secretKeyRequestHeader: string, idPath: string, datePath: string, apiToken: string, authenticateByToken: bool, authenticationTokenKey: string, instanceId: string, alertUid: string, title: string, imageUrl: string, state: string, externalLink: string, channelId: string, phoneNumberIdentification: string, accessKey: string, appSid: string, senderId: string, tenantId: string, AppIOBaseUrl: string, signingSecret: string, outboundIntegrationId: string, useFromAddressOverride: bool, fromAddressOverride: string, emailSlugPrefix: string, externalEnvironmentId: string, externalVaultId: string, externalWorkspaceId: string>, configurations: record<inboundWebhookEnabled: bool, inboundWebhookSigningKey: string>, active: bool, deleted: bool, deletedAt: string, deletedBy: string, primary: bool, conditions: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/integrations/($integrationId)")
  let body = {name: $name, identifier: $identifier, _environmentId: $environmentId, active: $active, credentials: $credentials, check: $check, conditions: $conditions, configurations: $configurations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an integration
#
# DELETE /v1/integrations/{integrationId}
# operationId: IntegrationsController_removeIntegration
export def "integrations removeIntegration" [
  integrationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<_id: string, _environmentId: string, _organizationId: string, name: string, identifier: string, providerId: string, channel: string, kind: string, credentials: record, configurations: record, active: bool, deleted: bool, deletedAt: string, deletedBy: string, primary: bool, conditions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/integrations/($integrationId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Auto-configure an integration for inbound webhooks
#
# POST /v1/integrations/{integrationId}/auto-configure
# operationId: IntegrationsController_autoConfigureIntegration
export def "integrations-auto-configure autoConfigureIntegration" [
  integrationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<success: bool, message: string, integration: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/integrations/($integrationId)/auto-configure")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update integration as primary
#
# POST /v1/integrations/{integrationId}/set-primary
# operationId: IntegrationsController_setIntegrationAsPrimary
export def "integrations-set-primary setIntegrationAsPrimary" [
  integrationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<_id: string, _environmentId: string, _organizationId: string, name: string, identifier: string, providerId: string, channel: string, kind: string, credentials: record<apiKey: string, user: string, secretKey: string, domain: string, password: string, host: string, port: string, secure: bool, region: string, accountSid: string, messageProfileId: string, token: string, from: string, senderName: string, projectName: string, applicationId: string, clientId: string, requireTls: bool, ignoreTls: bool, tlsOptions: record, baseUrl: string, webhookUrl: string, redirectUrl: string, hmac: bool, serviceAccount: string, ipPoolName: string, apiKeyRequestHeader: string, secretKeyRequestHeader: string, idPath: string, datePath: string, apiToken: string, authenticateByToken: bool, authenticationTokenKey: string, instanceId: string, alertUid: string, title: string, imageUrl: string, state: string, externalLink: string, channelId: string, phoneNumberIdentification: string, accessKey: string, appSid: string, senderId: string, tenantId: string, AppIOBaseUrl: string, signingSecret: string, outboundIntegrationId: string, useFromAddressOverride: bool, fromAddressOverride: string, emailSlugPrefix: string, externalEnvironmentId: string, externalVaultId: string, externalWorkspaceId: string>, configurations: record<inboundWebhookEnabled: bool, inboundWebhookSigningKey: string>, active: bool, deleted: bool, deletedAt: string, deletedBy: string, primary: bool, conditions: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/integrations/($integrationId)/set-primary")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate chat OAuth URL
#
# POST /v1/integrations/chat/oauth
# DEPRECATED
# operationId: IntegrationsController_getChatOAuthUrl
@deprecated
export def "integrations-chat-oauth post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subscriberId: string # The subscriber ID to link the channel connection to. For Slack: Required for incoming webhook endpoints, optional for workspace connections. For MS Teams: Optional. Admin consent is tenant-wide and can be associated with a subscriber for organizational purposes. (e.g. subscriber-123)
  integrationIdentifier: string # Integration identifier
  --connectionIdentifier: string # Identifier of the channel connection that will be created. It is generated automatically if not provided. (e.g. slack-connection-abc123)
  --context: record
  --scope: list # **Slack only**: OAuth scopes to request during authorization. These define the permissions your Slack integration will have. If not specified, default scopes will be used: chat:write, chat:write.public, channels:read, groups:read, users:read, users:read.email. **MS Teams**: This parameter is ignored. MS Teams uses admin consent with pre-configured permissions in Azure AD. Note: The generated OAuth URL expires after 5 minutes. (e.g. [chat:write, chat:write.public, channels:read, groups:read, users:read, users:read.email, incoming-webhook])
  --userScope: list # **Slack only, link_user mode**: User-level OAuth scopes to request during authorization. Used when mode is "link_user" to identify the Slack user via "Sign in with Slack". If not specified, defaults to: identity.basic. (e.g. [identity.basic])
  --mode: string@mode-completer # OAuth flow mode. Use "connect" (default) to create a workspace channel connection, or "link_user" to identify the subscriber's Slack user ID without creating a connection. (e.g. link_user)
  --connectionMode: string@connectionMode-completer # Connection mode that determines how the channel connection is scoped. Use "subscriber" (default) to associate the connection with a specific subscriber. Use "shared" to associate the connection with a context instead of a subscriber — subscriberId will not be stored on the connection. (e.g. shared)
  --autoLinkUser: string@bool-completer # When true, after the workspace/tenant connection is created the OAuth flow also links the subscriber who clicked "Connect" as a personal endpoint. For Slack, this uses the authed_user.id already returned by oauth.v2.access — no extra redirect. For MS Teams, this triggers a second OAuth redirect for delegated user-identity consent. Defaults to false when omitted; the SlackConnectButton and MsTeamsConnectButton SDK components default this to true. (e.g. true)
]: any -> record<data: record<url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/integrations/chat/oauth")
  let body = {subscriberId: $subscriberId, integrationIdentifier: $integrationIdentifier, connectionIdentifier: $connectionIdentifier, context: $context, scope: $scope, userScope: $userScope, mode: $mode, connectionMode: $connectionMode, autoLinkUser: $autoLinkUser} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate OAuth URL for a workspace/tenant connection
#
# POST /v1/integrations/channel-connections/oauth
# operationId: IntegrationsController_generateConnectOAuthUrl
export def "integrations-channel-connections-oauth generateConnectOAuthUrl" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subscriberId: string # The subscriber ID to associate with the channel connection. For Slack: optional for workspace connections (required only for incoming-webhook scope). For MS Teams: optional. Admin consent is tenant-wide. (e.g. subscriber-123)
  integrationIdentifier: string # Integration identifier
  --connectionIdentifier: string # Identifier of the channel connection that will be created. Generated automatically if not provided. (e.g. slack-connection-abc123)
  --context: record
  --scope: list # **Slack only**: OAuth scopes to request during authorization. If not specified, default scopes will be used: chat:write, chat:write.public, channels:read, groups:read, users:read, users:read.email. **MS Teams**: ignored — uses admin consent with pre-configured Azure AD permissions. (e.g. [chat:write, chat:write.public, channels:read])
  --connectionMode: string@connectionMode-completer # Connection mode that determines how the channel connection is scoped. "subscriber" (default) associates the connection with a specific subscriber. "shared" associates the connection with a context instead of a subscriber. (e.g. shared)
  --autoLinkUser: string@bool-completer # When true (default when connectionMode is "subscriber"), after the workspace/tenant connection is created the OAuth flow also links the subscriber who clicked "Connect" as a personal endpoint. For Slack, uses the authed_user.id returned by oauth.v2.access — no extra redirect. For MS Teams, triggers a second OAuth redirect for delegated user-identity consent. Set to false to only create the workspace connection without linking the individual user. (e.g. true)
]: any -> record<data: record<url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/integrations/channel-connections/oauth")
  let body = {subscriberId: $subscriberId, integrationIdentifier: $integrationIdentifier, connectionIdentifier: $connectionIdentifier, context: $context, scope: $scope, connectionMode: $connectionMode, autoLinkUser: $autoLinkUser} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate OAuth URL to link a subscriber user identity
#
# POST /v1/integrations/channel-endpoints/oauth
# operationId: IntegrationsController_generateLinkUserOAuthUrl
export def "integrations-channel-endpoints-oauth generateLinkUserOAuthUrl" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  subscriberId: string # The subscriber ID to link to their chat identity. Required — this operation always binds a specific subscriber to a user identity in the chat provider. (e.g. subscriber-123)
  integrationIdentifier: string # Integration identifier
  --connectionIdentifier: string # Identifier of the existing channel connection to associate this user endpoint with. Generated automatically if not provided. (e.g. slack-connection-abc123)
  --context: record
  --userScope: list # **Slack only**: User-level OAuth scopes for "Sign in with Slack". Defaults to: identity.basic. **MS Teams**: ignored — uses delegated OpenID scopes (openid, profile, User.Read). (e.g. [identity.basic])
]: any -> record<data: record<url: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/integrations/channel-endpoints/oauth")
  let body = {subscriberId: $subscriberId, integrationIdentifier: $integrationIdentifier, connectionIdentifier: $connectionIdentifier, context: $context, userScope: $userScope} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a context
#
# POST /v2/contexts
# operationId: ContextsController_createContext
export def "contexts createContext" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  type: string # Context type (e.g., tenant, app, workspace). Must be lowercase alphanumeric with optional separators. (e.g. tenant)
  id: string # Unique identifier for this context. Must be lowercase alphanumeric with optional separators. (e.g. org-acme)
  --data: record # Optional custom data to associate with this context. (e.g. {tenantName: Acme Corp, region: us-east-1, settings: {theme: dark}})
]: any -> record<data: record<type: string, id: string, data: record, createdAt: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/contexts")
  let body = {type: $type, id: $id, data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all contexts
#
# GET /v2/contexts
# operationId: ContextsController_listContexts
export def "contexts listContexts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string # Cursor for pagination indicating the starting point after which to fetch results.
  --before: string # Cursor for pagination indicating the ending point before which to fetch results.
  --limit: float # Limit the number of items to return (e.g. 10)
  --orderDirection: string@orderDirection-completer # Direction of sorting
  --orderBy: string # Field to order by
  --includeCursor: string@bool-completer # Include cursor item in response
  --id: string # Filter contexts by id (e.g. tenant-prod-123)
  --search: string # Search contexts by type or id (supports partial matching across both fields) (e.g. tenant)
]: nothing -> record<data: record<data: list<record>, next: string, previous: string, totalCount: float, totalCountCapped: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "orderDirection" $orderDirection "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "includeCursor" $includeCursor "scalar") (serialize-qp "id" $id "scalar") (serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/contexts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a context
#
# PATCH /v2/contexts/{type}/{id}
# operationId: ContextsController_updateContext
export def "contexts updateContext" [
  id: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  data: record # Custom data to associate with this context. Replaces existing data. (e.g. {tenantName: Acme Corp, region: us-east-1, settings: {theme: dark}})
]: any -> record<data: record<type: string, id: string, data: record, createdAt: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/contexts/($type)/($id)")
  let body = {data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a context
#
# GET /v2/contexts/{type}/{id}
# operationId: ContextsController_getContext
export def "contexts get" [
  id: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<type: string, id: string, data: record, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/contexts/($type)/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a context
#
# DELETE /v2/contexts/{type}/{id}
# operationId: ContextsController_deleteContext
export def "contexts delete" [
  id: string
  type: string
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
  let full_url = (build-url $base $"/v2/contexts/($type)/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk create subscribers
#
# POST /v1/subscribers/bulk
# operationId: SubscribersV1Controller_bulkCreateSubscribers
# --subscribers item shape: {firstName?: string, lastName?: string, email?: string, phone?: string, avatar?: string, locale?: string, timezone?: string, data?: record, subscriberId: string}
export def "subscribers-bulk bulkCreateSubscribers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  subscribers: list # An array of subscribers to be created in bulk. — item shape: {firstName?: string, lastName?: string, email?: string, phone?: string, avatar?: string, locale?: string, timezone?: string, data?: record, subscriberId: string}
]: any -> record<data: record<updated: list<record>, created: list<record>, failed: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/subscribers/bulk")
  let body = {subscribers: $subscribers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update provider credentials
#
# PUT /v1/subscribers/{subscriberId}/credentials
# operationId: SubscribersV1Controller_updateSubscriberChannel
export def "subscribers-credentials updateSubscriberChannel" [
  subscriberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  providerId: string@providerId-completer # The provider identifier for the credentials
  --integrationIdentifier: string # The integration identifier
  credentials: any # Credentials payload for the specified provider
]: any -> record<data: record<_id: string, firstName: string, lastName: string, email: string, phone: string, avatar: string, locale: string, channels: list<record>, topics: list<string>, isOnline: bool, lastOnlineAt: string, __v: float, data: record, timezone: string, subscriberId: string, _organizationId: string, _environmentId: string, deleted: bool, createdAt: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/subscribers/($subscriberId)/credentials")
  let body = {providerId: $providerId, integrationIdentifier: $integrationIdentifier, credentials: $credentials} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upsert provider credentials
#
# PATCH /v1/subscribers/{subscriberId}/credentials
# operationId: SubscribersV1Controller_modifySubscriberChannel
export def "subscribers-credentials modifySubscriberChannel" [
  subscriberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  providerId: string@providerId-completer # The provider identifier for the credentials
  --integrationIdentifier: string # The integration identifier
  credentials: any # Credentials payload for the specified provider
]: any -> record<data: record<_id: string, firstName: string, lastName: string, email: string, phone: string, avatar: string, locale: string, channels: list<record>, topics: list<string>, isOnline: bool, lastOnlineAt: string, __v: float, data: record, timezone: string, subscriberId: string, _organizationId: string, _environmentId: string, deleted: bool, createdAt: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/subscribers/($subscriberId)/credentials")
  let body = {providerId: $providerId, integrationIdentifier: $integrationIdentifier, credentials: $credentials} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete provider credentials
#
# DELETE /v1/subscribers/{subscriberId}/credentials/{providerId}
# operationId: SubscribersV1Controller_deleteSubscriberCredentials
export def "subscribers-credentials delete" [
  subscriberId: string
  providerId: string
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
  let full_url = (build-url $base $"/v1/subscribers/($subscriberId)/credentials/($providerId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update subscriber online status
#
# PATCH /v1/subscribers/{subscriberId}/online-status
# operationId: SubscribersV1Controller_updateSubscriberOnlineFlag
export def "subscribers-online-status updateSubscriberOnlineFlag" [
  subscriberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --isOnline: string@bool-completer
]: any -> record<data: record<_id: string, firstName: string, lastName: string, email: string, phone: string, avatar: string, locale: string, channels: list<record>, topics: list<string>, isOnline: bool, lastOnlineAt: string, __v: float, data: record, timezone: string, subscriberId: string, _organizationId: string, _environmentId: string, deleted: bool, createdAt: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/subscribers/($subscriberId)/online-status")
  let body = {isOnline: $isOnline} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve subscriber notifications
#
# GET /v1/subscribers/{subscriberId}/notifications/feed
# DEPRECATED
# operationId: SubscribersV1Controller_getNotificationsFeed
@deprecated
export def "subscribers-notifications-feed get" [
  subscriberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: float # e.g. 0
  --limit: float # default: 10, e.g. 10
  --read: string@bool-completer
  --seen: string@bool-completer
  --payload: string # Base64 encoded string of the partial payload JSON object (e.g. btoa(JSON.stringify({ foo: 123 })) results in base64 encoded string like eyJmb28iOjEyM30=)
]: nothing -> record<data: record<totalCount: float, hasMore: bool, data: list<record>, pageSize: float, page: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "read" $read "scalar") (serialize-qp "seen" $seen "scalar") (serialize-qp "payload" $payload "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/subscribers/($subscriberId)/notifications/feed" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve unseen notifications count
#
# GET /v1/subscribers/{subscriberId}/notifications/unseen
# DEPRECATED
# operationId: SubscribersV1Controller_getUnseenCount
@deprecated
export def "subscribers-notifications-unseen get" [
  subscriberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --seen: string@bool-completer # Indicates whether to count seen notifications. (default: false)
  --limit: float # The maximum number of notifications to return. (default: 100)
]: nothing -> record<data: record<count: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "seen" $seen "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/subscribers/($subscriberId)/notifications/unseen" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update notifications state
#
# POST /v1/subscribers/{subscriberId}/messages/mark-as
# DEPRECATED
# operationId: SubscribersV1Controller_markMessagesAs
@deprecated
export def "subscribers-messages-mark-as markMessagesAs" [
  subscriberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  messageId: any
  markAs: string@markAs-completer
]: any -> record<data: table<_id: string, _templateId: string, _environmentId: string, _messageTemplateId: string, _organizationId: string, _notificationId: string, _subscriberId: string, subscriber: record, template: record, templateIdentifier: string, createdAt: string, deliveredAt: list, lastSeenDate: string, lastReadDate: string, content: any, transactionId: string, subject: string, channel: string, read: bool, seen: bool, snoozedUntil: string, email: string, phone: string, directWebhookUrl: string, providerId: string, deviceTokens: list, title: string, cta: record, _feedId: string, status: string, errorId: string, errorText: string, payload: record, overrides: record, contextKeys: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/subscribers/($subscriberId)/messages/mark-as")
  let body = {messageId: $messageId, markAs: $markAs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update all notifications state
#
# POST /v1/subscribers/{subscriberId}/messages/mark-all
# DEPRECATED
# operationId: SubscribersV1Controller_markAllUnreadAsRead
@deprecated
export def "subscribers-messages-mark-all markAllUnreadAsRead" [
  subscriberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --feedIdentifier: any # Optional feed identifier or array of feed identifiers
  markAs: string@markAs-completer # Mark all subscriber messages as read, unread, seen or unseen
]: any -> float {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/subscribers/($subscriberId)/messages/mark-all")
  let body = {feedIdentifier: $feedIdentifier, markAs: $markAs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update notification action status
#
# POST /v1/subscribers/{subscriberId}/messages/{messageId}/actions/{type}
# DEPRECATED
# operationId: SubscribersV1Controller_markActionAsSeen
@deprecated
export def "subscribers-messages-actions markActionAsSeen" [
  messageId: string
  type: string
  subscriberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  status: string@status-completer # Message action status
  --payload: record # Message action payload
]: any -> record<data: record<_id: string, _templateId: string, _environmentId: string, _messageTemplateId: string, _organizationId: string, _notificationId: string, _subscriberId: string, subscriber: record<_id: string, firstName: string, lastName: string, email: string, phone: string, avatar: string, locale: string, channels: list, topics: list, isOnline: bool, lastOnlineAt: string, __v: float, data: record, timezone: string, subscriberId: string, _organizationId: string, _environmentId: string, deleted: bool, createdAt: string, updatedAt: string>, template: record<_id: string, name: string, description: string, active: bool, draft: bool, preferenceSettings: record, critical: bool, tags: list, steps: list, _organizationId: string, _creatorId: string, _environmentId: string, triggers: list, _notificationGroupId: string, _parentId: string, deleted: bool, deletedAt: string, deletedBy: string, notificationGroup: record, data: record, workflowIntegrationStatus: record>, templateIdentifier: string, createdAt: string, deliveredAt: list<string>, lastSeenDate: string, lastReadDate: string, content: any, transactionId: string, subject: string, channel: string, read: bool, seen: bool, snoozedUntil: string, email: string, phone: string, directWebhookUrl: string, providerId: string, deviceTokens: list<string>, title: string, cta: record<type: string, data: record, action: record>, _feedId: string, status: string, errorId: string, errorText: string, payload: record, overrides: record, contextKeys: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/subscribers/($subscriberId)/messages/($messageId)/actions/($type)")
  let body = {status: $status, payload: $payload} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Search subscribers
#
# GET /v2/subscribers
# operationId: SubscribersController_searchSubscribers
export def "subscribers searchSubscribers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string # Cursor for pagination indicating the starting point after which to fetch results.
  --before: string # Cursor for pagination indicating the ending point before which to fetch results.
  --limit: float # Limit the number of items to return (e.g. 10)
  --orderDirection: string@orderDirection-completer # Direction of sorting
  --orderBy: string # Field to order by
  --includeCursor: string@bool-completer # Include cursor item in response
  --email: string # Email address of the subscriber to filter results.
  --name: string # Name of the subscriber to filter results.
  --phone: string # Phone number of the subscriber to filter results.
  --subscriberId: string # Unique identifier of the subscriber to filter results.
]: nothing -> record<data: record<data: list<record>, next: string, previous: string, totalCount: float, totalCountCapped: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "orderDirection" $orderDirection "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "includeCursor" $includeCursor "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "phone" $phone "scalar") (serialize-qp "subscriberId" $subscriberId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/subscribers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a subscriber
#
# POST /v2/subscribers
# operationId: SubscribersController_createSubscriber
export def "subscribers createSubscriber" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --failIfExists: string@bool-completer # If true, the request will fail if a subscriber with the same subscriberId already exists
  --firstName: string # First name of the subscriber (nullable, e.g. John)
  --lastName: string # Last name of the subscriber (nullable, e.g. Doe)
  --email: string # Email address of the subscriber (nullable, e.g. john.doe@example.com)
  --phone: string # Phone number of the subscriber (nullable, e.g. +1234567890)
  --avatar: string # Avatar URL or identifier (nullable, e.g. https://example.com/avatar.jpg)
  --locale: string # Locale of the subscriber (nullable, e.g. en-US)
  --timezone: string # Timezone of the subscriber (nullable, e.g. America/New_York)
  --data: record # Additional custom data associated with the subscriber (nullable)
  subscriberId: string # Unique identifier of the subscriber
]: any -> record<data: record<_id: string, firstName: string, lastName: string, email: string, phone: string, avatar: string, locale: string, channels: list<record>, topics: list<string>, isOnline: bool, lastOnlineAt: string, __v: float, data: record, timezone: string, subscriberId: string, _organizationId: string, _environmentId: string, deleted: bool, createdAt: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "failIfExists" $failIfExists "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/subscribers" $qp)
  let body = {firstName: $firstName, lastName: $lastName, email: $email, phone: $phone, avatar: $avatar, locale: $locale, timezone: $timezone, data: $data, subscriberId: $subscriberId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a subscriber
#
# GET /v2/subscribers/{subscriberId}
# operationId: SubscribersController_getSubscriber
export def "subscribers get" [
  subscriberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<_id: string, firstName: string, lastName: string, email: string, phone: string, avatar: string, locale: string, channels: list<record>, topics: list<string>, isOnline: bool, lastOnlineAt: string, __v: float, data: record, timezone: string, subscriberId: string, _organizationId: string, _environmentId: string, deleted: bool, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/subscribers/($subscriberId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a subscriber
#
# PATCH /v2/subscribers/{subscriberId}
# operationId: SubscribersController_patchSubscriber
export def "subscribers patch" [
  subscriberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --firstName: string # First name of the subscriber (nullable, e.g. John)
  --lastName: string # Last name of the subscriber (nullable, e.g. Doe)
  --email: string # Email address of the subscriber (nullable, e.g. john.doe@example.com)
  --phone: string # Phone number of the subscriber (nullable, e.g. +1234567890)
  --avatar: string # Avatar URL or identifier (nullable, e.g. https://example.com/avatar.jpg)
  --locale: string # Locale of the subscriber (nullable, e.g. en-US)
  --timezone: string # Timezone of the subscriber (nullable, e.g. America/New_York)
  --data: record # Additional custom data associated with the subscriber (nullable)
]: any -> record<data: record<_id: string, firstName: string, lastName: string, email: string, phone: string, avatar: string, locale: string, channels: list<record>, topics: list<string>, isOnline: bool, lastOnlineAt: string, __v: float, data: record, timezone: string, subscriberId: string, _organizationId: string, _environmentId: string, deleted: bool, createdAt: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/subscribers/($subscriberId)")
  let body = {firstName: $firstName, lastName: $lastName, email: $email, phone: $phone, avatar: $avatar, locale: $locale, timezone: $timezone, data: $data} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a subscriber
#
# DELETE /v2/subscribers/{subscriberId}
# operationId: SubscribersController_removeSubscriber
export def "subscribers removeSubscriber" [
  subscriberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<acknowledged: bool, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/subscribers/($subscriberId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve subscriber preferences
#
# GET /v2/subscribers/{subscriberId}/preferences
# operationId: SubscribersController_getSubscriberPreferences
export def "subscribers-preferences get" [
  subscriberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --criticality: string@criticality-completer # default: nonCritical
  --contextKeys: list # Context keys for filtering preferences (e.g., ["tenant:acme"]) (e.g. [tenant:acme])
]: nothing -> record<data: record<global: record<enabled: bool, channels: record, schedule: record>, workflows: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "criticality" $criticality "scalar") (serialize-qp "contextKeys" $contextKeys "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/subscribers/($subscriberId)/preferences" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update subscriber preferences
#
# PATCH /v2/subscribers/{subscriberId}/preferences
# operationId: SubscribersController_updateSubscriberPreferences
export def "subscribers-preferences updateSubscriberPreferences" [
  subscriberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --channels: any # Channel-specific preference settings
  --workflowId: string # Workflow internal _id, identifier or slug. If provided, update workflow specific preferences, otherwise update global preferences
  --schedule: any # Subscriber schedule
  --context: record
]: any -> record<data: record<global: record<enabled: bool, channels: record, schedule: record>, workflows: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/subscribers/($subscriberId)/preferences")
  let body = {channels: $channels, workflowId: $workflowId, schedule: $schedule, context: $context} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Bulk update subscriber preferences
#
# PATCH /v2/subscribers/{subscriberId}/preferences/bulk
# operationId: SubscribersController_bulkUpdateSubscriberPreferences
# --preferences item shape: {channels: any, workflowId: string}
export def "subscribers-preferences-bulk bulkUpdateSubscriberPreferences" [
  subscriberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  preferences: list # Array of workflow preferences to update (maximum 100 items) — item shape: {channels: any, workflowId: string}
  --context: record
]: any -> record<data: table<level: string, workflow: record, enabled: bool, channels: record, condition: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/subscribers/($subscriberId)/preferences/bulk")
  let body = {preferences: $preferences, context: $context} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve subscriber subscriptions
#
# GET /v2/subscribers/{subscriberId}/subscriptions
# operationId: SubscribersController_listSubscriberTopics
export def "subscribers-subscriptions listSubscriberTopics" [
  subscriberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string # Cursor for pagination indicating the starting point after which to fetch results.
  --before: string # Cursor for pagination indicating the ending point before which to fetch results.
  --limit: float # Limit the number of items to return (max 100) (e.g. 10)
  --orderDirection: string@orderDirection-completer # Direction of sorting
  --orderBy: string # Field to order by
  --includeCursor: string@bool-completer # Include cursor item in response
  --key: string # Filter by topic key
  --contextKeys: list # Filter by exact context keys, order insensitive (format: "type:id") (e.g. [tenant:org-123, region:us-east-1])
]: nothing -> record<data: record<data: list<record>, next: string, previous: string, totalCount: float, totalCountCapped: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "orderDirection" $orderDirection "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "includeCursor" $includeCursor "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "contextKeys" $contextKeys "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/subscribers/($subscriberId)/subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve subscriber notifications
#
# GET /v2/subscribers/{subscriberId}/notifications
# operationId: SubscribersController_getSubscriberNotifications
export def "subscribers-notifications get" [
  subscriberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # default: 10, e.g. 10
  --after: string
  --offset: float # e.g. 0
  --read: string@bool-completer # Filter by read/unread state
  --archived: string@bool-completer # Filter by archived state
  --snoozed: string@bool-completer # Filter by snoozed state
  --seen: string@bool-completer # Filter by seen state
  --data: string # Filter by data attributes (JSON string)
  --severity: list # Filter by severity levels
  --createdGte: float # Filter notifications created on or after this timestamp (Unix timestamp in milliseconds) (e.g. 1704067200000)
  --createdLte: float # Filter notifications created on or before this timestamp (Unix timestamp in milliseconds) (e.g. 1735689599999)
  --contextKeys: list # Context keys for filtering notifications in multi-context scenarios
]: nothing -> record<data: record<data: list<record>, hasMore: bool, filter: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "after" $after "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "read" $read "scalar") (serialize-qp "archived" $archived "scalar") (serialize-qp "snoozed" $snoozed "scalar") (serialize-qp "seen" $seen "scalar") (serialize-qp "data" $data "scalar") (serialize-qp "severity" $severity "multi") (serialize-qp "createdGte" $createdGte "scalar") (serialize-qp "createdLte" $createdLte "scalar") (serialize-qp "contextKeys" $contextKeys "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/subscribers/($subscriberId)/notifications" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve subscriber notifications count
#
# GET /v2/subscribers/{subscriberId}/notifications/count
# operationId: SubscribersController_getSubscriberNotificationsCount
export def "subscribers-notifications-count get" [
  subscriberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --filters: string # Array of filter objects (max 30) to count notifications by different criteria (e.g. [{"read":false,"archived":false},{"tags":["important"]},{"tags":{"and":[{"or":["a","b"]},{"or":["c"]}]}}])
]: nothing -> record<data: table<count: float, filter: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filters" $filters "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/subscribers/($subscriberId)/notifications/count" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mark a notification as read
#
# PATCH /v2/subscribers/{subscriberId}/notifications/{notificationId}/read
# operationId: SubscribersController_markNotificationAsRead
export def "subscribers-notifications-read markNotificationAsRead" [
  subscriberId: string
  notificationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contextKeys: list # Context keys for filtering
]: nothing -> record<id: string, transactionId: string, subject: string, body: string, to: record<id: string, firstName: string, lastName: string, avatar: string, subscriberId: string>, isRead: bool, isSeen: bool, isArchived: bool, isSnoozed: bool, snoozedUntil: string, deliveredAt: list<string>, createdAt: string, readAt: string, firstSeenAt: string, archivedAt: string, avatar: string, primaryAction: record<label: string, isCompleted: bool, redirect: record<url: string, target: string>>, secondaryAction: record<label: string, isCompleted: bool, redirect: record<url: string, target: string>>, channelType: string, tags: list<string>, data: record, redirect: record<url: string, target: string>, workflow: record<id: string, identifier: string, name: string, critical: bool, tags: list<string>, data: record, severity: string>, severity: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contextKeys" $contextKeys "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/subscribers/($subscriberId)/notifications/($notificationId)/read" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mark a notification as unread
#
# PATCH /v2/subscribers/{subscriberId}/notifications/{notificationId}/unread
# operationId: SubscribersController_markNotificationAsUnread
export def "subscribers-notifications-unread markNotificationAsUnread" [
  subscriberId: string
  notificationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contextKeys: list # Context keys for filtering
]: nothing -> record<id: string, transactionId: string, subject: string, body: string, to: record<id: string, firstName: string, lastName: string, avatar: string, subscriberId: string>, isRead: bool, isSeen: bool, isArchived: bool, isSnoozed: bool, snoozedUntil: string, deliveredAt: list<string>, createdAt: string, readAt: string, firstSeenAt: string, archivedAt: string, avatar: string, primaryAction: record<label: string, isCompleted: bool, redirect: record<url: string, target: string>>, secondaryAction: record<label: string, isCompleted: bool, redirect: record<url: string, target: string>>, channelType: string, tags: list<string>, data: record, redirect: record<url: string, target: string>, workflow: record<id: string, identifier: string, name: string, critical: bool, tags: list<string>, data: record, severity: string>, severity: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contextKeys" $contextKeys "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/subscribers/($subscriberId)/notifications/($notificationId)/unread" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Archive a notification
#
# PATCH /v2/subscribers/{subscriberId}/notifications/{notificationId}/archive
# operationId: SubscribersController_archiveNotification
export def "subscribers-notifications-archive archiveNotification" [
  subscriberId: string
  notificationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contextKeys: list # Context keys for filtering
]: nothing -> record<id: string, transactionId: string, subject: string, body: string, to: record<id: string, firstName: string, lastName: string, avatar: string, subscriberId: string>, isRead: bool, isSeen: bool, isArchived: bool, isSnoozed: bool, snoozedUntil: string, deliveredAt: list<string>, createdAt: string, readAt: string, firstSeenAt: string, archivedAt: string, avatar: string, primaryAction: record<label: string, isCompleted: bool, redirect: record<url: string, target: string>>, secondaryAction: record<label: string, isCompleted: bool, redirect: record<url: string, target: string>>, channelType: string, tags: list<string>, data: record, redirect: record<url: string, target: string>, workflow: record<id: string, identifier: string, name: string, critical: bool, tags: list<string>, data: record, severity: string>, severity: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contextKeys" $contextKeys "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/subscribers/($subscriberId)/notifications/($notificationId)/archive" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Unarchive a notification
#
# PATCH /v2/subscribers/{subscriberId}/notifications/{notificationId}/unarchive
# operationId: SubscribersController_unarchiveNotification
export def "subscribers-notifications-unarchive unarchiveNotification" [
  subscriberId: string
  notificationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contextKeys: list # Context keys for filtering
]: nothing -> record<id: string, transactionId: string, subject: string, body: string, to: record<id: string, firstName: string, lastName: string, avatar: string, subscriberId: string>, isRead: bool, isSeen: bool, isArchived: bool, isSnoozed: bool, snoozedUntil: string, deliveredAt: list<string>, createdAt: string, readAt: string, firstSeenAt: string, archivedAt: string, avatar: string, primaryAction: record<label: string, isCompleted: bool, redirect: record<url: string, target: string>>, secondaryAction: record<label: string, isCompleted: bool, redirect: record<url: string, target: string>>, channelType: string, tags: list<string>, data: record, redirect: record<url: string, target: string>, workflow: record<id: string, identifier: string, name: string, critical: bool, tags: list<string>, data: record, severity: string>, severity: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contextKeys" $contextKeys "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/subscribers/($subscriberId)/notifications/($notificationId)/unarchive" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Snooze a notification
#
# PATCH /v2/subscribers/{subscriberId}/notifications/{notificationId}/snooze
# operationId: SubscribersController_snoozeNotification
export def "subscribers-notifications-snooze snoozeNotification" [
  subscriberId: string
  notificationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contextKeys: list # Context keys for filtering
  snoozeUntil: string # The date and time until which the notification should be snoozed (format: date-time, e.g. 2026-03-01T10:00:00Z)
]: any -> record<id: string, transactionId: string, subject: string, body: string, to: record<id: string, firstName: string, lastName: string, avatar: string, subscriberId: string>, isRead: bool, isSeen: bool, isArchived: bool, isSnoozed: bool, snoozedUntil: string, deliveredAt: list<string>, createdAt: string, readAt: string, firstSeenAt: string, archivedAt: string, avatar: string, primaryAction: record<label: string, isCompleted: bool, redirect: record<url: string, target: string>>, secondaryAction: record<label: string, isCompleted: bool, redirect: record<url: string, target: string>>, channelType: string, tags: list<string>, data: record, redirect: record<url: string, target: string>, workflow: record<id: string, identifier: string, name: string, critical: bool, tags: list<string>, data: record, severity: string>, severity: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contextKeys" $contextKeys "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/subscribers/($subscriberId)/notifications/($notificationId)/snooze" $qp)
  let body = {snoozeUntil: $snoozeUntil} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Unsnooze a notification
#
# PATCH /v2/subscribers/{subscriberId}/notifications/{notificationId}/unsnooze
# operationId: SubscribersController_unsnoozeNotification
export def "subscribers-notifications-unsnooze unsnoozeNotification" [
  subscriberId: string
  notificationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contextKeys: list # Context keys for filtering
]: nothing -> record<id: string, transactionId: string, subject: string, body: string, to: record<id: string, firstName: string, lastName: string, avatar: string, subscriberId: string>, isRead: bool, isSeen: bool, isArchived: bool, isSnoozed: bool, snoozedUntil: string, deliveredAt: list<string>, createdAt: string, readAt: string, firstSeenAt: string, archivedAt: string, avatar: string, primaryAction: record<label: string, isCompleted: bool, redirect: record<url: string, target: string>>, secondaryAction: record<label: string, isCompleted: bool, redirect: record<url: string, target: string>>, channelType: string, tags: list<string>, data: record, redirect: record<url: string, target: string>, workflow: record<id: string, identifier: string, name: string, critical: bool, tags: list<string>, data: record, severity: string>, severity: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contextKeys" $contextKeys "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/subscribers/($subscriberId)/notifications/($notificationId)/unsnooze" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a notification
#
# DELETE /v2/subscribers/{subscriberId}/notifications/{notificationId}
# operationId: SubscribersController_deleteNotification
export def "subscribers-notifications delete" [
  subscriberId: string
  notificationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contextKeys: list # Context keys for filtering
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contextKeys" $contextKeys "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/subscribers/($subscriberId)/notifications/($notificationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Complete a notification action
#
# PATCH /v2/subscribers/{subscriberId}/notifications/{notificationId}/actions/{actionType}/complete
# operationId: SubscribersController_completeNotificationAction
export def "subscribers-notifications-actions-complete completeNotificationAction" [
  subscriberId: string
  notificationId: string
  actionType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contextKeys: list # Context keys for filtering
]: nothing -> record<id: string, transactionId: string, subject: string, body: string, to: record<id: string, firstName: string, lastName: string, avatar: string, subscriberId: string>, isRead: bool, isSeen: bool, isArchived: bool, isSnoozed: bool, snoozedUntil: string, deliveredAt: list<string>, createdAt: string, readAt: string, firstSeenAt: string, archivedAt: string, avatar: string, primaryAction: record<label: string, isCompleted: bool, redirect: record<url: string, target: string>>, secondaryAction: record<label: string, isCompleted: bool, redirect: record<url: string, target: string>>, channelType: string, tags: list<string>, data: record, redirect: record<url: string, target: string>, workflow: record<id: string, identifier: string, name: string, critical: bool, tags: list<string>, data: record, severity: string>, severity: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contextKeys" $contextKeys "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/subscribers/($subscriberId)/notifications/($notificationId)/actions/($actionType)/complete" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Revert a notification action
#
# PATCH /v2/subscribers/{subscriberId}/notifications/{notificationId}/actions/{actionType}/revert
# operationId: SubscribersController_revertNotificationAction
export def "subscribers-notifications-actions-revert revertNotificationAction" [
  subscriberId: string
  notificationId: string
  actionType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --contextKeys: list # Context keys for filtering
]: nothing -> record<id: string, transactionId: string, subject: string, body: string, to: record<id: string, firstName: string, lastName: string, avatar: string, subscriberId: string>, isRead: bool, isSeen: bool, isArchived: bool, isSnoozed: bool, snoozedUntil: string, deliveredAt: list<string>, createdAt: string, readAt: string, firstSeenAt: string, archivedAt: string, avatar: string, primaryAction: record<label: string, isCompleted: bool, redirect: record<url: string, target: string>>, secondaryAction: record<label: string, isCompleted: bool, redirect: record<url: string, target: string>>, channelType: string, tags: list<string>, data: record, redirect: record<url: string, target: string>, workflow: record<id: string, identifier: string, name: string, critical: bool, tags: list<string>, data: record, severity: string>, severity: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "contextKeys" $contextKeys "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/subscribers/($subscriberId)/notifications/($notificationId)/actions/($actionType)/revert" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Mark notifications as seen
#
# POST /v2/subscribers/{subscriberId}/notifications/seen
# operationId: SubscribersController_markNotificationsAsSeen
export def "subscribers-notifications-seen markNotificationsAsSeen" [
  subscriberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --notificationIds: list # Specific notification IDs to mark as seen
  --tags: record # Filter notifications by workflow tags (OR for string[], or { and: [{ or: string[] }, ...] } for AND of OR-groups).
  --data: string # Filter notifications by data attributes (JSON string)
  --contextKeys: list # Context keys for filtering notifications
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/subscribers/($subscriberId)/notifications/seen")
  let body = {notificationIds: $notificationIds, tags: $tags, data: $data, contextKeys: $contextKeys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Mark all notifications as read
#
# POST /v2/subscribers/{subscriberId}/notifications/read
# operationId: SubscribersController_markAllNotificationsAsRead
export def "subscribers-notifications-read markAllNotificationsAsRead" [
  subscriberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tags: record # Filter notifications by workflow tags (OR for string[], or { and: [{ or: string[] }, ...] } for AND of OR-groups).
  --data: string # Filter notifications by data attributes (JSON string)
  --contextKeys: list # Context keys for filtering notifications
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/subscribers/($subscriberId)/notifications/read")
  let body = {tags: $tags, data: $data, contextKeys: $contextKeys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Archive all notifications
#
# POST /v2/subscribers/{subscriberId}/notifications/archive
# operationId: SubscribersController_archiveAllNotifications
export def "subscribers-notifications-archive archiveAllNotifications" [
  subscriberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tags: record # Filter notifications by workflow tags (OR for string[], or { and: [{ or: string[] }, ...] } for AND of OR-groups).
  --data: string # Filter notifications by data attributes (JSON string)
  --contextKeys: list # Context keys for filtering notifications
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/subscribers/($subscriberId)/notifications/archive")
  let body = {tags: $tags, data: $data, contextKeys: $contextKeys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Archive all read notifications
#
# POST /v2/subscribers/{subscriberId}/notifications/read-archive
# operationId: SubscribersController_archiveAllReadNotifications
export def "subscribers-notifications-read-archive archiveAllReadNotifications" [
  subscriberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tags: record # Filter notifications by workflow tags (OR for string[], or { and: [{ or: string[] }, ...] } for AND of OR-groups).
  --data: string # Filter notifications by data attributes (JSON string)
  --contextKeys: list # Context keys for filtering notifications
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/subscribers/($subscriberId)/notifications/read-archive")
  let body = {tags: $tags, data: $data, contextKeys: $contextKeys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete all notifications
#
# POST /v2/subscribers/{subscriberId}/notifications/delete
# operationId: SubscribersController_deleteAllNotifications
export def "subscribers-notifications-delete post" [
  subscriberId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --tags: record # Filter notifications by workflow tags (OR for string[], or { and: [{ or: string[] }, ...] } for AND of OR-groups).
  --data: string # Filter notifications by data attributes (JSON string)
  --contextKeys: list # Context keys for filtering notifications
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/subscribers/($subscriberId)/notifications/delete")
  let body = {tags: $tags, data: $data, contextKeys: $contextKeys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a layout
#
# POST /v2/layouts
# operationId: LayoutsController_create
export def "layouts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  layoutId: string # Unique identifier for the layout
  name: string # Name of the layout
  --isTranslationEnabled: string@bool-completer # Enable or disable translations for this layout (default: false)
  --body-source: string@source-completer # Source of layout creation (default: dashboard)
]: any -> record<data: record<_id: string, layoutId: string, slug: string, name: string, isDefault: bool, isTranslationEnabled: bool, updatedAt: string, updatedBy: record<_id: string, firstName: string, lastName: string, externalId: string>, createdAt: string, origin: string, type: string, variables: record, controls: record<dataSchema: record, uiSchema: record, values: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/layouts")
  let body = {layoutId: $layoutId, name: $name, isTranslationEnabled: $isTranslationEnabled, __source: $body_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all layouts
#
# GET /v2/layouts
# operationId: LayoutsController_list
export def "layouts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # Number of items to return per page (e.g. 10)
  --offset: float # Number of items to skip before starting to return results (e.g. 0)
  --orderDirection: string@orderDirection-completer # Direction of sorting
  --orderBy: string@orderBy-completer # Field to sort the results by
  --qp-query: string # Search query to filter layouts
]: nothing -> record<data: record<layouts: list<record>, totalCount: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "orderDirection" $orderDirection "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "query" $qp_query "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/layouts" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a layout
#
# PUT /v2/layouts/{layoutId}
# operationId: LayoutsController_update
export def "layouts update" [
  layoutId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the layout
  --isTranslationEnabled: string@bool-completer # Enable or disable translations for this layout (default: false)
  --controlValues: any # Control values for the layout. Omit to leave unchanged, or set to null to clear stored control values. (nullable)
]: any -> record<data: record<_id: string, layoutId: string, slug: string, name: string, isDefault: bool, isTranslationEnabled: bool, updatedAt: string, updatedBy: record<_id: string, firstName: string, lastName: string, externalId: string>, createdAt: string, origin: string, type: string, variables: record, controls: record<dataSchema: record, uiSchema: record, values: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/layouts/($layoutId)")
  let body = {name: $name, isTranslationEnabled: $isTranslationEnabled, controlValues: $controlValues} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a layout
#
# GET /v2/layouts/{layoutId}
# operationId: LayoutsController_get
export def "layouts get" [
  layoutId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<_id: string, layoutId: string, slug: string, name: string, isDefault: bool, isTranslationEnabled: bool, updatedAt: string, updatedBy: record<_id: string, firstName: string, lastName: string, externalId: string>, createdAt: string, origin: string, type: string, variables: record, controls: record<dataSchema: record, uiSchema: record, values: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/layouts/($layoutId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a layout
#
# DELETE /v2/layouts/{layoutId}
# operationId: LayoutsController__delete
export def "layouts delete" [
  layoutId: string
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
  let full_url = (build-url $base $"/v2/layouts/($layoutId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Duplicate a layout
#
# POST /v2/layouts/{layoutId}/duplicate
# operationId: LayoutsController_duplicate
export def "layouts-duplicate duplicate" [
  layoutId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the layout
  --body-layoutId: string # Identifier for the duplicated layout. When omitted, it is derived from the name.
  --isTranslationEnabled: string@bool-completer # Enable or disable translations for this layout (default: false)
]: any -> record<data: record<_id: string, layoutId: string, slug: string, name: string, isDefault: bool, isTranslationEnabled: bool, updatedAt: string, updatedBy: record<_id: string, firstName: string, lastName: string, externalId: string>, createdAt: string, origin: string, type: string, variables: record, controls: record<dataSchema: record, uiSchema: record, values: record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/layouts/($layoutId)/duplicate")
  let body = {name: $name, layoutId: $body_layoutId, isTranslationEnabled: $isTranslationEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate layout preview
#
# POST /v2/layouts/{layoutId}/preview
# operationId: LayoutsController_generatePreview
export def "layouts-preview generatePreview" [
  layoutId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --controlValues: record # Optional control values for layout preview
  --previewPayload: any # Optional payload for layout preview
]: any -> record<data: record<previewPayloadExample: record<subscriber: record>, schema: record, result: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/layouts/($layoutId)/preview")
  let body = {controlValues: $controlValues, previewPayload: $previewPayload} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get layout usage
#
# GET /v2/layouts/{layoutId}/usage
# operationId: LayoutsController_getUsage
export def "layouts-usage get" [
  layoutId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<workflows: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/layouts/($layoutId)/usage")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all messages
#
# GET /v1/messages
# operationId: MessagesController_getMessages
export def "messages get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --channel: string@channel-completer
  --subscriberId: string
  --transactionId: list
  --contextKeys: list # Filter by exact context keys, order insensitive (format: "type:id") (e.g. [tenant:org-123, region:us-east-1])
  --page: float # default: 0
  --limit: float # default: 10
]: nothing -> record<totalCount: float, hasMore: bool, data: table<_id: string, _templateId: string, _environmentId: string, _messageTemplateId: string, _organizationId: string, _notificationId: string, _subscriberId: string, subscriber: record, template: record, templateIdentifier: string, createdAt: string, deliveredAt: list, lastSeenDate: string, lastReadDate: string, content: any, transactionId: string, subject: string, channel: string, read: bool, seen: bool, snoozedUntil: string, email: string, phone: string, directWebhookUrl: string, providerId: string, deviceTokens: list, title: string, cta: record, _feedId: string, status: string, errorId: string, errorText: string, payload: record, overrides: record, contextKeys: list>, pageSize: float, page: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "channel" $channel "scalar") (serialize-qp "subscriberId" $subscriberId "scalar") (serialize-qp "transactionId" $transactionId "multi") (serialize-qp "contextKeys" $contextKeys "multi") (serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/messages" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a message
#
# DELETE /v1/messages/{messageId}
# operationId: MessagesController_deleteMessage
export def "messages delete" [
  messageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<acknowledged: bool, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/messages/($messageId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete messages by transactionId
#
# DELETE /v1/messages/transaction/{transactionId}
# operationId: MessagesController_deleteMessagesByTransactionId
export def "messages-transaction delete" [
  transactionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --channel: string@channel-completer # The channel of the message to be deleted
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "channel" $channel "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/messages/transaction/($transactionId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check topic subscriber
#
# GET /v1/topics/{topicKey}/subscribers/{externalSubscriberId}
# operationId: TopicsV1Controller_getTopicSubscriber
export def "topics-subscribers get" [
  externalSubscriberId: string
  topicKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<_organizationId: string, _environmentId: string, _subscriberId: string, _topicId: string, topicKey: string, externalSubscriberId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/topics/($topicKey)/subscribers/($externalSubscriberId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all topics
#
# GET /v2/topics
# operationId: TopicsController_listTopics
export def "topics listTopics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string # Cursor for pagination indicating the starting point after which to fetch results.
  --before: string # Cursor for pagination indicating the ending point before which to fetch results.
  --limit: float # Limit the number of items to return (max 100) (e.g. 10)
  --orderDirection: string@orderDirection-completer # Direction of sorting
  --orderBy: string # Field to order by
  --includeCursor: string@bool-completer # Include cursor item in response
  --key: string # Key of the topic to filter results.
  --name: string # Name of the topic to filter results.
]: nothing -> record<data: record<data: list<record>, next: string, previous: string, totalCount: float, totalCountCapped: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "orderDirection" $orderDirection "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "includeCursor" $includeCursor "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/topics" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a topic
#
# POST /v2/topics
# operationId: TopicsController_upsertTopic
export def "topics upsertTopic" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --failIfExists: string@bool-completer # If true, the request will fail if a topic with the same key already exists
  key: string # The unique key identifier for the topic. The key must contain only alphanumeric characters (a-z, A-Z, 0-9), hyphens (-), underscores (_), colons (:), or be a valid email address. (e.g. task:12345)
  --name: string # The display name for the topic (e.g. Task Title)
]: any -> record<data: record<_id: string, key: string, name: string, createdAt: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "failIfExists" $failIfExists "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/topics" $qp)
  let body = {key: $key, name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a topic
#
# GET /v2/topics/{topicKey}
# operationId: TopicsController_getTopic
export def "topics get" [
  topicKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<_id: string, key: string, name: string, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/topics/($topicKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a topic
#
# PATCH /v2/topics/{topicKey}
# operationId: TopicsController_updateTopic
export def "topics updateTopic" [
  topicKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # The display name for the topic (e.g. Updated Topic Name)
]: any -> record<data: record<_id: string, key: string, name: string, createdAt: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/topics/($topicKey)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a topic
#
# DELETE /v2/topics/{topicKey}
# operationId: TopicsController_deleteTopic
export def "topics delete" [
  topicKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<acknowledged: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/topics/($topicKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List topic subscriptions
#
# GET /v2/topics/{topicKey}/subscriptions
# operationId: TopicsController_listTopicSubscriptions
export def "topics-subscriptions listTopicSubscriptions" [
  topicKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string # Cursor for pagination indicating the starting point after which to fetch results.
  --before: string # Cursor for pagination indicating the ending point before which to fetch results.
  --limit: float # Limit the number of items to return (max 100) (e.g. 10)
  --orderDirection: string@orderDirection-completer # Direction of sorting
  --orderBy: string # Field to order by
  --includeCursor: string@bool-completer # Include cursor item in response
  --subscriberId: string # Filter by subscriber ID
  --contextKeys: list # Filter by exact context keys, order insensitive (format: "type:id") (e.g. [tenant:org-123, region:us-east-1])
]: nothing -> record<data: record<data: list<record>, next: string, previous: string, totalCount: float, totalCountCapped: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "orderDirection" $orderDirection "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "includeCursor" $includeCursor "scalar") (serialize-qp "subscriberId" $subscriberId "scalar") (serialize-qp "contextKeys" $contextKeys "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/topics/($topicKey)/subscriptions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create topic subscriptions
#
# POST /v2/topics/{topicKey}/subscriptions
# operationId: TopicsController_createTopicSubscriptions
@deprecated --flag subscriberIds
export def "topics-subscriptions createTopicSubscriptions" [
  topicKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subscriberIds: list # List of subscriber IDs to subscribe to the topic (max: 100). @deprecated Use the "subscriptions" property instead. (DEPRECATED, e.g. [subscriberId1, subscriberId2])
  --subscriptions: list # List of subscriptions to subscribe to the topic (max: 100). Can be either a string array of subscriber IDs or an array of objects with identifier and subscriberId (e.g. [{identifier: subscriber-123-subscription-a, subscriberId: subscriber-123}, {identifier: subscriber-456-subscription-b, subscriberId: subscriber-456}])
  --name: string # The name of the topic (e.g. My Topic)
  --context: record
  --preferences: list # The preferences of the topic. Can be a simple workflow ID string, workflow preference object, or group filter object (e.g. [{workflowId: workflow-123, condition: {===: [{var: tier}, premium]}}])
]: any -> record<data: record<data: list<record>, meta: record<totalCount: float, successful: float, failed: float>, errors: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/topics/($topicKey)/subscriptions")
  let body = {subscriberIds: $subscriberIds, subscriptions: $subscriptions, name: $name, context: $context, preferences: $preferences} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete topic subscriptions
#
# DELETE /v2/topics/{topicKey}/subscriptions
# operationId: TopicsController_deleteTopicSubscriptions
@deprecated --flag subscriberIds
export def "topics-subscriptions delete" [
  topicKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --subscriberIds: list # List of subscriber identifiers to unsubscribe from the topic (max: 100). @deprecated Use the "subscriptions" property instead. (DEPRECATED, e.g. [subscriberId1, subscriberId2])
  --subscriptions: list # List of subscriptions to unsubscribe from the topic (max: 100). Can be either a string array of subscriber IDs or an array of objects with identifier and/or subscriberId. If only subscriberId is provided, all subscriptions for that subscriber within the topic will be deleted. (e.g. [{identifier: subscriber-123-subscription-a, subscriberId: subscriber-123}, {subscriberId: subscriber-456}, {identifier: subscriber-789-subscription-b}])
]: any -> record<data: table<_id: string, identifier: string, topic: record, subscriber: record, contextKeys: list, createdAt: string, updatedAt: string>, meta: record<totalCount: float, successful: float, failed: float>, errors: table<subscriberId: string, code: string, message: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/topics/($topicKey)/subscriptions")
  let body = {subscriberIds: $subscriberIds, subscriptions: $subscriptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a topic subscription
#
# GET /v2/topics/{topicKey}/subscriptions/{identifier}
# operationId: TopicsController_getTopicSubscription
export def "topics-subscriptions get" [
  topicKey: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: string, identifier: string, name: string, preferences: list<record>, contextKeys: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/topics/($topicKey)/subscriptions/($identifier)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a topic subscription
#
# PATCH /v2/topics/{topicKey}/subscriptions/{identifier}
# operationId: TopicsController_updateTopicSubscription
export def "topics-subscriptions updateTopicSubscription" [
  topicKey: string
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --name: string # The name of the subscription (e.g. My Subscription)
  --preferences: list # The preferences of the topic. Can be a simple workflow ID string, workflow preference object, or group filter object (e.g. [{workflowId: workflow-123, condition: {===: [{var: tier}, premium]}}])
]: any -> record<data: record<_id: string, identifier: string, name: string, topic: record<_id: string, key: string, name: string>, subscriber: record<_id: string, subscriberId: string, avatar: string, firstName: string, lastName: string, email: string>, preferences: list<record>, contextKeys: list<string>, createdAt: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/topics/($topicKey)/subscriptions/($identifier)")
  let body = {name: $name, preferences: $preferences} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all variables
#
# GET /v1/environment-variables
# operationId: EnvironmentVariablesController_listEnvironmentVariables
export def "environment-variables listEnvironmentVariables" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Filter variables by key (case-insensitive partial match)
]: nothing -> record<data: table<_id: string, _organizationId: string, key: string, type: string, isSecret: bool, values: list, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/environment-variables" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a variable
#
# POST /v1/environment-variables
# operationId: EnvironmentVariablesController_createEnvironmentVariable
# --values item shape: {_environmentId: string, value: string}
export def "environment-variables createEnvironmentVariable" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  key: string # Unique key for the variable. Must start with a letter and contain only letters, digits, and underscores.
  --type: string@type-completer-1 # The type of the variable
  --isSecret: string@bool-completer # Whether this variable is a secret (encrypted at rest, masked in responses)
  --values: list # item shape: {_environmentId: string, value: string}
]: any -> record<data: record<_id: string, _organizationId: string, key: string, type: string, isSecret: bool, values: list<record>, createdAt: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/environment-variables")
  let body = {key: $key, type: $type, isSecret: $isSecret, values: $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a variable usage
#
# GET /v1/environment-variables/{variableKey}/usage
# operationId: EnvironmentVariablesController_getEnvironmentVariableUsage
export def "environment-variables-usage get" [
  variableKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<workflows: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/environment-variables/($variableKey)/usage")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get environment variable
#
# GET /v1/environment-variables/{variableKey}
# operationId: EnvironmentVariablesController_getEnvironmentVariable
export def "environment-variables get" [
  variableKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<_id: string, _organizationId: string, key: string, type: string, isSecret: bool, values: list<record>, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/environment-variables/($variableKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a variable
#
# PATCH /v1/environment-variables/{variableKey}
# operationId: EnvironmentVariablesController_updateEnvironmentVariable
# --values item shape: {_environmentId: string, value: string}
export def "environment-variables updateEnvironmentVariable" [
  variableKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --key: string # Unique key for the variable. Must start with a letter and contain only letters, digits, and underscores.
  --type: string@type-completer-1 # The type of the variable
  --isSecret: string@bool-completer
  --values: list # item shape: {_environmentId: string, value: string}
]: any -> record<data: record<_id: string, _organizationId: string, key: string, type: string, isSecret: bool, values: list<record>, createdAt: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/environment-variables/($variableKey)")
  let body = {key: $key, type: $type, isSecret: $isSecret, values: $values} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete environment variable
#
# DELETE /v1/environment-variables/{variableKey}
# operationId: EnvironmentVariablesController_deleteEnvironmentVariable
export def "environment-variables delete" [
  variableKey: string
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
  let full_url = (build-url $base $"/v1/environment-variables/($variableKey)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a workflow
#
# POST /v2/workflows
# operationId: WorkflowController_create
export def "workflows create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the workflow
  --description: string # Description of the workflow
  --tags: list # Tags associated with the workflow
  --active: string@bool-completer # Whether the workflow is active (default: false)
  --validatePayload: string@bool-completer # Enable or disable payload schema validation
  --payloadSchema: record # The payload JSON Schema for the workflow (nullable)
  --isTranslationEnabled: string@bool-completer # Enable or disable translations for this workflow (default: false)
  workflowId: string # Unique identifier for the workflow
  steps: list # Steps of the workflow
  --body-source: string@source-completer-1 # Source of workflow creation (default: editor)
  --preferences: any # Workflow preferences
  --severity: string@severity-completer # Severity of the workflow
]: any -> record<data: record<name: string, description: string, tags: list<string>, active: bool, validatePayload: bool, payloadSchema: record, isTranslationEnabled: bool, _id: string, workflowId: string, slug: string, updatedAt: string, createdAt: string, updatedBy: record<_id: string, firstName: string, lastName: string, externalId: string>, lastPublishedAt: string, lastPublishedBy: record<_id: string, firstName: string, lastName: string, externalId: string>, steps: list<any>, origin: string, preferences: record<user: record, default: record>, status: string, issues: record, lastTriggeredAt: string, payloadExample: record, severity: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/workflows")
  let body = {name: $name, description: $description, tags: $tags, active: $active, validatePayload: $validatePayload, payloadSchema: $payloadSchema, isTranslationEnabled: $isTranslationEnabled, workflowId: $workflowId, steps: $steps, __source: $body_source, preferences: $preferences, severity: $severity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all workflows
#
# GET /v2/workflows
# operationId: WorkflowController_searchWorkflows
export def "workflows searchWorkflows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: float # Number of items to return per page (e.g. 10)
  --offset: float # Number of items to skip before starting to return results (e.g. 0)
  --orderDirection: string@orderDirection-completer # Direction of sorting
  --orderBy: string@orderBy-completer-1 # Field to sort the results by
  --qp-query: string # Search query to filter workflows
  --tags: list # Filter workflows by tags
  --status: list # Filter workflows by status
]: nothing -> record<data: record<workflows: list<record>, totalCount: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "orderDirection" $orderDirection "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "query" $qp_query "scalar") (serialize-qp "tags" $tags "multi") (serialize-qp "status" $status "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/workflows" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Sync a workflow
#
# PUT /v2/workflows/{workflowId}/sync
# operationId: WorkflowController_sync
export def "workflows-sync sync" [
  workflowId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  targetEnvironmentId: string # Target environment identifier to sync the workflow to
]: any -> record<data: record<name: string, description: string, tags: list<string>, active: bool, validatePayload: bool, payloadSchema: record, isTranslationEnabled: bool, _id: string, workflowId: string, slug: string, updatedAt: string, createdAt: string, updatedBy: record<_id: string, firstName: string, lastName: string, externalId: string>, lastPublishedAt: string, lastPublishedBy: record<_id: string, firstName: string, lastName: string, externalId: string>, steps: list<any>, origin: string, preferences: record<user: record, default: record>, status: string, issues: record, lastTriggeredAt: string, payloadExample: record, severity: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/workflows/($workflowId)/sync")
  let body = {targetEnvironmentId: $targetEnvironmentId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a workflow
#
# PUT /v2/workflows/{workflowId}
# operationId: WorkflowController_update
export def "workflows update" [
  workflowId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  name: string # Name of the workflow
  --description: string # Description of the workflow
  --tags: list # Tags associated with the workflow
  --active: string@bool-completer # Whether the workflow is active (default: false)
  --validatePayload: string@bool-completer # Enable or disable payload schema validation
  --payloadSchema: record # The payload JSON Schema for the workflow (nullable)
  --isTranslationEnabled: string@bool-completer # Enable or disable translations for this workflow (default: false)
  --body-workflowId: string # Workflow ID (allowed only for code-first workflows)
  steps: list # Steps of the workflow
  preferences: any # Workflow preferences
  origin: string@origin-completer # Origin of the layout
  --severity: string@severity-completer # Severity of the workflow
]: any -> record<data: record<name: string, description: string, tags: list<string>, active: bool, validatePayload: bool, payloadSchema: record, isTranslationEnabled: bool, _id: string, workflowId: string, slug: string, updatedAt: string, createdAt: string, updatedBy: record<_id: string, firstName: string, lastName: string, externalId: string>, lastPublishedAt: string, lastPublishedBy: record<_id: string, firstName: string, lastName: string, externalId: string>, steps: list<any>, origin: string, preferences: record<user: record, default: record>, status: string, issues: record, lastTriggeredAt: string, payloadExample: record, severity: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/workflows/($workflowId)")
  let body = {name: $name, description: $description, tags: $tags, active: $active, validatePayload: $validatePayload, payloadSchema: $payloadSchema, isTranslationEnabled: $isTranslationEnabled, workflowId: $body_workflowId, steps: $steps, preferences: $preferences, origin: $origin, severity: $severity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a workflow
#
# GET /v2/workflows/{workflowId}
# operationId: WorkflowController_getWorkflow
export def "workflows get" [
  workflowId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --environmentId: string
]: nothing -> record<data: record<name: string, description: string, tags: list<string>, active: bool, validatePayload: bool, payloadSchema: record, isTranslationEnabled: bool, _id: string, workflowId: string, slug: string, updatedAt: string, createdAt: string, updatedBy: record<_id: string, firstName: string, lastName: string, externalId: string>, lastPublishedAt: string, lastPublishedBy: record<_id: string, firstName: string, lastName: string, externalId: string>, steps: list<any>, origin: string, preferences: record<user: record, default: record>, status: string, issues: record, lastTriggeredAt: string, payloadExample: record, severity: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "environmentId" $environmentId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/workflows/($workflowId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a workflow
#
# DELETE /v2/workflows/{workflowId}
# operationId: WorkflowController_removeWorkflow
export def "workflows removeWorkflow" [
  workflowId: string
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
  let full_url = (build-url $base $"/v2/workflows/($workflowId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a workflow
#
# PATCH /v2/workflows/{workflowId}
# operationId: WorkflowController_patchWorkflow
export def "workflows patch" [
  workflowId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --active: string@bool-completer # Activate or deactivate the workflow
  --name: string # New name for the workflow
  --description: string # Updated description of the workflow
  --tags: list # Tags associated with the workflow
  --payloadSchema: record # The payload JSON Schema for the workflow (nullable)
  --validatePayload: string@bool-completer # Enable or disable payload schema validation
  --isTranslationEnabled: string@bool-completer # Enable or disable translations for this workflow
]: any -> record<data: record<name: string, description: string, tags: list<string>, active: bool, validatePayload: bool, payloadSchema: record, isTranslationEnabled: bool, _id: string, workflowId: string, slug: string, updatedAt: string, createdAt: string, updatedBy: record<_id: string, firstName: string, lastName: string, externalId: string>, lastPublishedAt: string, lastPublishedBy: record<_id: string, firstName: string, lastName: string, externalId: string>, steps: list<any>, origin: string, preferences: record<user: record, default: record>, status: string, issues: record, lastTriggeredAt: string, payloadExample: record, severity: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/workflows/($workflowId)")
  let body = {active: $active, name: $name, description: $description, tags: $tags, payloadSchema: $payloadSchema, validatePayload: $validatePayload, isTranslationEnabled: $isTranslationEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate a step preview
#
# POST /v2/workflows/{workflowId}/step/{stepId}/preview
# operationId: WorkflowController_generatePreview
export def "workflows-step-preview generatePreview" [
  workflowId: string
  stepId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --controlValues: record # Optional control values
  --previewPayload: any # Optional payload for preview generation
]: any -> record<data: record<previewPayloadExample: record<subscriber: record, payload: record, steps: record, context: record, env: record>, schema: record, novuSignature: string, result: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/workflows/($workflowId)/step/($stepId)/preview")
  let body = {controlValues: $controlValues, previewPayload: $previewPayload} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve workflow step
#
# GET /v2/workflows/{workflowId}/steps/{stepId}
# operationId: WorkflowController_getWorkflowStepData
export def "workflows-steps get" [
  workflowId: string
  stepId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<controls: record<dataSchema: record, uiSchema: record>, controlValues: record, variables: record, stepId: string, _id: string, name: string, slug: string, type: string, origin: string, workflowId: string, workflowDatabaseId: string, issues: record<controls: record, integration: record>, stepResolverHash: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/workflows/($workflowId)/steps/($stepId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List environment tags
#
# GET /v2/environments/{environmentId}/tags
# operationId: EnvironmentsController_getEnvironmentTags
export def "environments-tags get" [
  environmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/environments/($environmentId)/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Publish resources to target environment
#
# POST /v2/environments/{targetEnvironmentId}/publish
# operationId: EnvironmentsController_publishEnvironment
# --resources item shape: {resourceType: "REGULAR"|"ECHO"|"BRIDGE", resourceId: string}
export def "environments-publish publishEnvironment" [
  targetEnvironmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sourceEnvironmentId: string # Source environment ID to sync from. Defaults to the Development environment if not provided. (e.g. 507f1f77bcf86cd799439011)
  --dryRun: string@bool-completer # Perform a dry run without making actual changes (default: false)
  --resources: list # Array of specific resources to publish. If not provided, all resources will be published. — item shape: {resourceType: "REGULAR"|"ECHO"|"BRIDGE", resourceId: string}
]: any -> record<data: record<results: list<record>, summary: record<resources: float, successful: float, failed: float, skipped: float>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/environments/($targetEnvironmentId)/publish")
  let body = {sourceEnvironmentId: $sourceEnvironmentId, dryRun: $dryRun, resources: $resources} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Compare resources between environments
#
# POST /v2/environments/{targetEnvironmentId}/diff
# operationId: EnvironmentsController_diffEnvironment
export def "environments-diff diffEnvironment" [
  targetEnvironmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --sourceEnvironmentId: string # Source environment ID to compare from. Defaults to the Development environment if not provided. (e.g. 507f1f77bcf86cd799439011)
]: any -> record<data: record<sourceEnvironmentId: string, targetEnvironmentId: string, resources: list<record>, summary: record<totalEntities: float, totalChanges: float, hasChanges: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/environments/($targetEnvironmentId)/diff")
  let body = {sourceEnvironmentId: $sourceEnvironmentId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all channel connections
#
# GET /v1/channel-connections
# operationId: ChannelConnectionsController_listChannelConnections
export def "channel-connections listChannelConnections" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string # Cursor for pagination indicating the starting point after which to fetch results.
  --before: string # Cursor for pagination indicating the ending point before which to fetch results.
  --limit: float # Limit the number of items to return (max 100) (e.g. 10)
  --orderDirection: string@orderDirection-completer # Direction of sorting
  --orderBy: string # Field to order by
  --includeCursor: string@bool-completer # Include cursor item in response
  --subscriberId: string # The subscriber ID to filter results by (e.g. subscriber-123)
  --channel: string@channel-completer # Filter by channel type (email, sms, push, chat, etc.). (e.g. chat)
  --providerId: string@providerId-completer-1 # Filter by provider identifier (e.g., sendgrid, twilio, slack, etc.). (e.g. slack)
  --integrationIdentifier: string # Filter by integration identifier. (e.g. slack-prod)
  --contextKeys: list # Filter by exact context keys, order insensitive (format: "type:id") (e.g. [tenant:org-123, region:us-east-1])
]: nothing -> record<data: record<data: list<record>, next: string, previous: string, totalCount: float, totalCountCapped: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "orderDirection" $orderDirection "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "includeCursor" $includeCursor "scalar") (serialize-qp "subscriberId" $subscriberId "scalar") (serialize-qp "channel" $channel "scalar") (serialize-qp "providerId" $providerId "scalar") (serialize-qp "integrationIdentifier" $integrationIdentifier "scalar") (serialize-qp "contextKeys" $contextKeys "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/channel-connections" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a channel connection
#
# POST /v1/channel-connections
# operationId: ChannelConnectionsController_createChannelConnection
# --workspace shape: {id: string, name?: string}
# --auth shape: {accessToken: string}
export def "channel-connections createChannelConnection" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifier: string # The unique identifier for the channel connection. If not provided, one will be generated automatically. (e.g. slack-prod-user123-abc4)
  --subscriberId: string # The subscriber ID to link the channel connection to (e.g. subscriber-123)
  --context: record
  --connectionMode: string@connectionMode-completer # Connection mode that determines how the channel connection is scoped. Use "subscriber" (default) to associate the connection with a specific subscriber. Use "shared" to associate the connection with a context instead of a subscriber — subscriberId will not be stored on the connection. (e.g. shared)
  integrationIdentifier: string # The identifier of the integration to use for this channel connection. (e.g. slack-prod)
  workspace: record # shape: {id: string, name?: string}
  --body-auth: record # shape: {accessToken: string}
]: any -> record<data: record<identifier: string, channel: string, providerId: string, integrationIdentifier: string, subscriberId: string, contextKeys: list<string>, workspace: record<id: string, name: string>, auth: record<accessToken: string>, createdAt: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/channel-connections")
  let body = {identifier: $identifier, subscriberId: $subscriberId, context: $context, connectionMode: $connectionMode, integrationIdentifier: $integrationIdentifier, workspace: $workspace, auth: $body_auth} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a channel connection
#
# GET /v1/channel-connections/{identifier}
# operationId: ChannelConnectionsController_getChannelConnectionByIdentifier
export def "channel-connections get" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<identifier: string, channel: string, providerId: string, integrationIdentifier: string, subscriberId: string, contextKeys: list<string>, workspace: record<id: string, name: string>, auth: record<accessToken: string>, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/channel-connections/($identifier)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a channel connection
#
# PATCH /v1/channel-connections/{identifier}
# operationId: ChannelConnectionsController_updateChannelConnection
# --workspace shape: {id: string, name?: string}
# --auth shape: {accessToken: string}
export def "channel-connections updateChannelConnection" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  workspace: record # shape: {id: string, name?: string}
  --body-auth: record # shape: {accessToken: string}
]: any -> record<data: record<identifier: string, channel: string, providerId: string, integrationIdentifier: string, subscriberId: string, contextKeys: list<string>, workspace: record<id: string, name: string>, auth: record<accessToken: string>, createdAt: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/channel-connections/($identifier)")
  let body = {workspace: $workspace, auth: $body_auth} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a channel connection
#
# DELETE /v1/channel-connections/{identifier}
# operationId: ChannelConnectionsController_deleteChannelConnection
export def "channel-connections delete" [
  identifier: string
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
  let full_url = (build-url $base $"/v1/channel-connections/($identifier)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all channel endpoints
#
# GET /v1/channel-endpoints
# operationId: ChannelEndpointsController_listChannelEndpoints
export def "channel-endpoints listChannelEndpoints" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --after: string # Cursor for pagination indicating the starting point after which to fetch results.
  --before: string # Cursor for pagination indicating the ending point before which to fetch results.
  --limit: float # Limit the number of items to return (max 100) (e.g. 10)
  --orderDirection: string@orderDirection-completer # Direction of sorting
  --orderBy: string # Field to order by
  --includeCursor: string@bool-completer # Include cursor item in response
  --subscriberId: string # The subscriber ID to filter results by (e.g. subscriber-123)
  --contextKeys: list # Filter by exact context keys, order insensitive (format: "type:id") (e.g. [tenant:org-123, region:us-east-1])
  --channel: string@channel-completer # Channel type to filter results.
  --providerId: string@providerId-completer-1 # Filter by provider identifier (e.g., sendgrid, twilio, slack, etc.). (e.g. slack)
  --integrationIdentifier: string # Integration identifier to filter results. (e.g. slack-prod)
  --connectionIdentifier: string # Connection identifier to filter results. (e.g. slack-connection-abc123)
]: nothing -> record<data: record<data: list<record>, next: string, previous: string, totalCount: float, totalCountCapped: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "after" $after "scalar") (serialize-qp "before" $before "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "orderDirection" $orderDirection "scalar") (serialize-qp "orderBy" $orderBy "scalar") (serialize-qp "includeCursor" $includeCursor "scalar") (serialize-qp "subscriberId" $subscriberId "scalar") (serialize-qp "contextKeys" $contextKeys "multi") (serialize-qp "channel" $channel "scalar") (serialize-qp "providerId" $providerId "scalar") (serialize-qp "integrationIdentifier" $integrationIdentifier "scalar") (serialize-qp "connectionIdentifier" $connectionIdentifier "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/channel-endpoints" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a channel endpoint
#
# POST /v1/channel-endpoints
# Discriminator (request): type = slack_channel, slack_user, webhook, phone, ms_teams_channel, ms_teams_user, telegram_chat
# operationId: ChannelEndpointsController_createChannelEndpoint
export def "channel-endpoints createChannelEndpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --identifier: string # The unique identifier for the channel endpoint. If not provided, one will be generated automatically. (e.g. slack-channel-user123-abc4)
  --subscriberId: string # The subscriber ID to which the channel endpoint is linked (e.g. subscriber-123)
  --context: record
  --integrationIdentifier: string # The identifier of the integration to use for this channel endpoint. (e.g. slack-prod)
  --connectionIdentifier: string # The identifier of the channel connection to use for this channel endpoint. (e.g. slack-connection-abc123)
  type: string@type-completer-2 # Type of channel endpoint (e.g. slack_channel)
  --endpoint: any # Slack channel endpoint data
]: any -> record<data: record<identifier: string, channel: string, providerId: string, integrationIdentifier: string, connectionIdentifier: string, subscriberId: string, contextKeys: list<string>, type: string, endpoint: any, createdAt: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/channel-endpoints")
  let body = {identifier: $identifier, subscriberId: $subscriberId, context: $context, integrationIdentifier: $integrationIdentifier, connectionIdentifier: $connectionIdentifier, type: $type, endpoint: $endpoint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a channel endpoint
#
# GET /v1/channel-endpoints/{identifier}
# operationId: ChannelEndpointsController_getChannelEndpoint
export def "channel-endpoints get" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<identifier: string, channel: string, providerId: string, integrationIdentifier: string, connectionIdentifier: string, subscriberId: string, contextKeys: list<string>, type: string, endpoint: any, createdAt: string, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/channel-endpoints/($identifier)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a channel endpoint
#
# PATCH /v1/channel-endpoints/{identifier}
# operationId: ChannelEndpointsController_updateChannelEndpoint
export def "channel-endpoints updateChannelEndpoint" [
  identifier: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  endpoint: any # Updated endpoint data. The structure must match the existing channel endpoint type.
]: any -> record<data: record<identifier: string, channel: string, providerId: string, integrationIdentifier: string, connectionIdentifier: string, subscriberId: string, contextKeys: list<string>, type: string, endpoint: any, createdAt: string, updatedAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/channel-endpoints/($identifier)")
  let body = {endpoint: $endpoint} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a channel endpoint
#
# DELETE /v1/channel-endpoints/{identifier}
# operationId: ChannelEndpointsController_deleteChannelEndpoint
export def "channel-endpoints delete" [
  identifier: string
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
  let full_url = (build-url $base $"/v1/channel-endpoints/($identifier)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload translation files
#
# POST /v2/translations/upload
# operationId: TranslationController_uploadTranslationFiles
export def "translations-upload uploadTranslationFiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  resourceId: string # The resource ID to associate localizations with. Accepts identifier or slug format (e.g. welcome-email)
  resourceType: string@resourceType-completer # The resource type to associate localizations with
  files: list # One or more JSON translation files. Filenames must match locale format (e.g., en_US.json, fr_FR.json). Field name can be "files" or "files[]".
]: any -> record<totalFiles: float, successfulUploads: float, failedUploads: float, errors: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/translations/upload")
  let body = {resourceId: $resourceId, resourceType: $resourceType, files: $files} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Create a translation
#
# POST /v2/translations
# operationId: TranslationController_createTranslationEndpoint
export def "translations createTranslationEndpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  resourceId: string # The resource ID to associate translation with. Accepts identifier or slug format (e.g. welcome-email)
  resourceType: string@resourceType-completer # The resource type to associate translation with
  locale: string # Locale code (e.g., en_US, es_ES) (e.g. en_US)
  content: record # Translation content as JSON object (e.g. {welcome.title: Welcome, welcome.message: Hello there!})
]: any -> record<resourceId: string, resourceType: string, locale: string, content: record, createdAt: string, updatedAt: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/translations")
  let body = {resourceId: $resourceId, resourceType: $resourceType, locale: $locale, content: $content} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve master translations JSON
#
# GET /v2/translations/master-json
# operationId: TranslationController_getMasterJsonEndpoint
export def "translations-master-json get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --locale: string # Locale to export. If not provided, exports organization default locale (e.g. en_US)
]: nothing -> record<workflows: record, layouts: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/translations/master-json" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Import master translations JSON
#
# POST /v2/translations/master-json
# operationId: TranslationController_importMasterJsonEndpoint
export def "translations-master-json importMasterJsonEndpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  locale: string # The locale for which translations are being imported (e.g. en_US)
  masterJson: record # Master JSON object containing all translations organized by workflow identifier (e.g. {workflows: {welcome-email: {welcome.title: Welcome to our platform, welcome.message: Hello there!}, password-reset: {reset.title: Reset your password, reset.message: Click the link to reset}}})
]: any -> record<success: bool, message: string, successful: list<string>, failed: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/translations/master-json")
  let body = {locale: $locale, masterJson: $masterJson} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Upload master translations JSON file
#
# POST /v2/translations/master-json/upload
# operationId: TranslationController_uploadMasterJsonEndpoint
export def "translations-master-json-upload uploadMasterJsonEndpoint" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  file: string # Master JSON file with locale as filename (e.g., en_US.json) (format: binary)
]: any -> record<success: bool, message: string, successful: list<string>, failed: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/translations/master-json/upload")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "multipart/form-data" $body
}

# Retrieve a translation group
#
# GET /v2/translations/group/{resourceType}/{resourceId}
# operationId: TranslationController_getTranslationGroupEndpoint
export def "translations-group get" [
  resourceType: string
  resourceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<resourceId: string, resourceType: string, resourceName: string, locales: list<string>, outdatedLocales: list<string>, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/translations/group/($resourceType)/($resourceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a translation
#
# GET /v2/translations/{resourceType}/{resourceId}/{locale}
# operationId: TranslationController_getSingleTranslation
export def "translations get" [
  resourceType: string
  resourceId: string
  locale: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<resourceId: string, resourceType: string, locale: string, content: record, createdAt: string, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/translations/($resourceType)/($resourceId)/($locale)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a translation
#
# DELETE /v2/translations/{resourceType}/{resourceId}/{locale}
# operationId: TranslationController_deleteTranslationEndpoint
export def "translations delete-by-resourceType-resourceId-locale" [
  resourceType: string
  resourceId: string
  locale: string
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
  let full_url = (build-url $base $"/v2/translations/($resourceType)/($resourceId)/($locale)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a translation group
#
# DELETE /v2/translations/{resourceType}/{resourceId}
# operationId: TranslationController_deleteTranslationGroupEndpoint
export def "translations delete-by-resourceType-resourceId" [
  resourceType: string
  resourceId: string
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
  let full_url = (build-url $base $"/v2/translations/($resourceType)/($resourceId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Track provider activity and engagement events
#
# POST /v2/inbound-webhooks/delivery-providers/{environmentId}/{integrationId}
# operationId: InboundWebhooksController_handleWebhook
export def "inbound-webhooks-delivery-providers handleWebhook" [
  environmentId: string
  integrationId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --body: record
]: any -> table<id: string, event: record<status: string, date: string, externalId: string, attempts: float, response: string, row: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/inbound-webhooks/delivery-providers/($environmentId)/($integrationId)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
